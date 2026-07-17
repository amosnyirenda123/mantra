%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(session_registry).
-behaviour(gen_server).

-define(SERVER, ?MODULE).
-define(TABLE_ID, session_registry_by_user_id).
-define(REV_TABLE_ID, session_registry_by_session).

%% API
-export([stop/0, start_link/0, register/2, unregister/1, lookup/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {table_id, rev_table_id}).



%%====================================================================
%% API
%%====================================================================

stop() ->
    gen_server:call(?SERVER, stop).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


register(UserId, SessionId) ->
    gen_server:call(?SERVER, {register, UserId, SessionId}).

unregister(SessionId) ->
    gen_server:call(?SERVER, {unregister, SessionId}).

lookup(UserId, SessionId) ->
    gen_server:call(?SERVER, {lookup, UserId, SessionId}).



%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    
    ets:new(?TABLE_ID, [bag, named_table, private]),
    ets:new(?REV_TABLE_ID, [set, named_table, private]),
    {ok, #state{table_id = ?TABLE_ID, rev_table_id = ?REV_TABLE_ID}}.

handle_call(stop, _From, State) ->
    {stop, normal, stopped, State};

handle_call({register, UserId, SessionId}, _From, State) ->
    true = ets:insert(State#state.table_id, {UserId, SessionId}),
    true = ets:insert(State#state.rev_table_id, {SessionId, UserId}),
    {reply, ok, State};

handle_call({unregister, SessionId}, _From, State) ->
    case ets:lookup(State#state.rev_table_id, SessionId) of
        [{SessionId, UserId}] ->
            true = ets:delete_object(State#state.table_id, {UserId, SessionId}),
            true = ets:delete(State#state.rev_table_id, SessionId),
            {reply, ok, State};
        [] ->
            {reply, {error, not_found}, State}
    end;

handle_call({lookup, UserId, SessionId}, _From, State) ->
    Entries = ets:lookup(State#state.table_id, UserId),
    Reply = case lists:member({UserId, SessionId}, Entries) of
        true  -> {ok, SessionId};
        false -> {error, not_found}
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