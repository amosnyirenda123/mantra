%%%-------------------------------------------------------------------
%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%% Minimal account store: username -> {user_id, password_hash}.
%%%
%%% This is a gen_server (not a plain module like session_manager)
%%% because account creation needs a serialization point: two
%%% connections registering the same username at the same instant
%%% must not both succeed. Routing create_account/2 through one
%%% process's mailbox gives us that check-then-insert atomicity for
%%% free. Reads (authenticate/2) could bypass the process and read
%%% the ETS table directly like session_registry does, but auth is
%%% not a hot path the way session lookup is, so it's left going
%%% through the gen_server here for simplicity.
%%%
%%% Two tables: ?TABLE_ID (username -> {user_id, hash}) is primary;
%%% ?ID_TABLE_ID (user_id -> username) is a secondary index for
%%% get_user_by_id/1. Both are written together in create_account/2,
%%% so they can't drift out of sync.
%%% @end
%%%-------------------------------------------------------------------

-module(auth_service).
-behaviour(gen_server).

-define(SERVER, ?MODULE).
-define(TABLE_ID, auth_service_users).
-define(ID_TABLE_ID, auth_service_users_by_id).

%% API
-export([start_link/0, stop/0, create_account/2, authenticate/2, get_user_by_id/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {next_user_id = 1}).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

stop() ->
    gen_server:call(?SERVER, stop).

%% Username, Password -> {ok, UserId} | {error, username_taken}
create_account(Username, Password) ->
    gen_server:call(?SERVER, {create_account, Username, Password}).

%% Username, Password -> {ok, UserId} | {error, invalid_credentials}
authenticate(Username, Password) ->
    gen_server:call(?SERVER, {authenticate, Username, Password}).

%% UserId -> {ok, Username} | {error, not_found}
get_user_by_id(UserId) ->
    gen_server:call(?SERVER, {get_user_by_id, UserId}).

%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    ets:new(?TABLE_ID, [set, named_table, protected]),
    ets:new(?ID_TABLE_ID, [set, named_table, protected]),
    {ok, #state{next_user_id = 1}}.

handle_call(stop, _From, State) ->
    {stop, normal, stopped, State};

handle_call({create_account, Username, Password}, _From, State) ->
    case ets:lookup(?TABLE_ID, Username) of
        [] ->
            UserId = State#state.next_user_id,
            Hash = hash_password(Password),
            true = ets:insert(?TABLE_ID, {Username, UserId, Hash}),
            true = ets:insert(?ID_TABLE_ID, {UserId, Username}),
            {reply, {ok, UserId}, State#state{next_user_id = UserId + 1}};
        [_Existing] ->
            {reply, {error, username_taken}, State}
    end;

handle_call({get_user_by_id, UserId}, _From, State) ->
    Reply = case ets:lookup(?ID_TABLE_ID, UserId) of
        [{UserId, Username}] -> {ok, Username};
        [] -> {error, not_found}
    end,
    {reply, Reply, State};

handle_call({authenticate, Username, Password}, _From, State) ->
    Reply = case ets:lookup(?TABLE_ID, Username) of
        [{Username, UserId, Hash}] ->
            case check_password(Password, Hash) of
                true -> {ok, UserId};
                false -> {error, invalid_credentials}
            end;
        [] ->
            {error, invalid_credentials}
    end,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%====================================================================
%% Internal
%%====================================================================

%% Placeholder hashing. crypto:hash(sha256, ...) has no salt and is
%% fast by design, which is exactly wrong for passwords -- fine for
%% getting the plumbing working, not fine to ship. See note below.
hash_password(Password) ->
    crypto:hash(sha256, Password).

check_password(Password, Hash) ->
    hash_password(Password) =:= Hash.