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
-define(MON_TABLE_ID, session_registry_by_monitor).

-export([stop/0, start_link/0, register/3, unregister/1, lookup/2, get_sessions/1, lookup_pid/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {}).

%%====================================================================
%% API
%%====================================================================

stop() ->
    gen_server:call(?SERVER, stop).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).


register(UserId, SessionId, SessionPid) ->
    gen_server:call(?SERVER, {register, UserId, SessionId, SessionPid}).

unregister(SessionId) ->
    gen_server:call(?SERVER, {unregister, SessionId}).

lookup(UserId, SessionId) ->
    gen_server:call(?SERVER, {lookup, UserId, SessionId}).

lookup_pid(SessionId) ->
    gen_server:call(?SERVER, {lookup_pid, SessionId}).

%% Read path bypasses the gen_server entirely -- table is protected,
%% so any process can read it directly without serializing through
%% the registry process. This is the hot path for message fan-out.
get_sessions(UserId) ->
    [{SessionId, SessionPid} || {_UserId, SessionId, SessionPid } <- ets:lookup(?TABLE_ID, UserId)].

%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    ets:new(?TABLE_ID, [bag, named_table, protected]),
    ets:new(?REV_TABLE_ID, [set, named_table, protected]),
    ets:new(?MON_TABLE_ID, [set, named_table, private]),
    {ok, #state{}}.

handle_call(stop, _From, State) ->
    {stop, normal, stopped, State};

handle_call({register, UserId, SessionId, SessionPid }, _From, State) ->
    Ref = erlang:monitor(process, SessionPid),
    true = ets:insert(?TABLE_ID, {UserId, SessionId, SessionPid }),
    true = ets:insert(?REV_TABLE_ID, {SessionId, UserId, SessionPid}),
    true = ets:insert(?MON_TABLE_ID, {Ref, SessionId}),
    {reply, ok, State};

handle_call({unregister, SessionId}, _From, State) ->
    case ets:lookup(?REV_TABLE_ID, SessionId) of
        [{SessionId, UserId, SessionPid }] ->
            true = ets:delete_object(?TABLE_ID, {UserId, SessionId, SessionPid }),
            true = ets:delete(?REV_TABLE_ID, SessionId),
            demonitor_session(SessionId),
            {reply, ok, State};
        [] ->
            {reply, {error, not_found}, State}
    end;

handle_call({lookup_pid, SessionId}, _From, State) ->
    case ets:lookup(?REV_TABLE_ID, SessionId) of
        [{SessionId, _UserId, SessionPid }] ->
            {reply, {ok, SessionPid }, State};
        [] ->
            {reply, {error, not_found}, State}
    end;

handle_call({lookup, UserId, SessionId}, _From, State) ->
    Entries = ets:lookup(?TABLE_ID, UserId),
    Reply = case lists:keymember(SessionId, 2, Entries) of
        true  -> {ok, SessionId};
        false -> {error, not_found}
    end,
    {reply, Reply, State}.



handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info({'DOWN', Ref, process, _Pid, _Reason}, State) ->
    case ets:lookup(?MON_TABLE_ID, Ref) of
        [{Ref, SessionId}] ->
            case ets:lookup(?REV_TABLE_ID, SessionId) of
                [{SessionId, UserId, SessionPid}] ->
                    true = ets:delete_object(?TABLE_ID, {UserId, SessionId, SessionPid
         }),
                    true = ets:delete(?REV_TABLE_ID, SessionId);
                [] ->
                    ok
            end,
            true = ets:delete(?MON_TABLE_ID, Ref);
        [] ->
            ok
    end,
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%====================================================================
%% internal
%%====================================================================

demonitor_session(SessionId) ->
    case ets:match_object(?MON_TABLE_ID, {'_', SessionId}) of
        [{Ref, SessionId}] ->
            erlang:demonitor(Ref, [flush]),
            ets:delete(?MON_TABLE_ID, Ref);
        [] ->
            ok
    end.