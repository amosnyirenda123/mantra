%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(room_registry).
-behaviour(gen_server).

-define(SERVER, ?MODULE).
-define(TABLE_ID, ?MODULE).
-define(MON_TABLE_ID, room_registry_by_ref).

%% API
-export([stop/0, start_link/0, register/2, unregister/1, lookup/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {table_id, mon_table_id}).



%%====================================================================
%% API
%%====================================================================

stop() ->
    gen_server:call(?SERVER, stop).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

register(RoomName, Pid) ->
    gen_server:call(?SERVER, {register, RoomName, Pid}).

unregister(RoomName) ->
    gen_server:call(?SERVER, {unregister, RoomName}).

lookup(RoomName) ->
    gen_server:call(?SERVER, {lookup, RoomName}).



%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    ets:new(?TABLE_ID, [set, named_table, private]),
    ets:new(?MON_TABLE_ID, [set, named_table, private]),
    {ok, #state{table_id = ?TABLE_ID, mon_table_id = ?MON_TABLE_ID}}.

handle_call(stop, _From, State) ->
    {stop, normal, stopped, State};

handle_call({register, RoomName, Pid}, _From, State) ->
    case ets:lookup(State#state.table_id, RoomName) of
        [{RoomName, _ExistingPid, _ExistingRef}] ->
            {reply, {error, already_registered}, State};
        [] ->
            Ref = erlang:monitor(process, Pid),
            true = ets:insert(State#state.table_id, {RoomName, Pid, Ref}),
            true = ets:insert(State#state.mon_table_id, {Ref, RoomName}),
            {reply, ok, State}
    end;

handle_call({unregister, RoomName}, _From, State) ->
    case ets:lookup(State#state.table_id, RoomName) of
        [{RoomName, _Pid, Ref}] ->
            erlang:demonitor(Ref, [flush]),
            true = ets:delete(State#state.mon_table_id, Ref),
            true = ets:delete(State#state.table_id, RoomName),
            {reply, ok, State};
        [] ->
            {reply, {error, not_found}, State}
    end;

handle_call({lookup, RoomName}, _From, State) ->
    Reply = case ets:lookup(State#state.table_id, RoomName) of
        [{RoomName, Pid, _Ref}] -> {ok, Pid};
        [] -> {error, not_found}
    end,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({'DOWN', Ref, process, _Pid, _Reason}, State) ->
    case ets:lookup(State#state.mon_table_id, Ref) of
        [{Ref, RoomName}] ->
            true = ets:delete(State#state.mon_table_id, Ref),
            true = ets:delete(State#state.table_id, RoomName);
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