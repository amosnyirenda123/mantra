%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%% Manages chat room lifecycle and room operations.
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>

-module(room_manager).

-behaviour(gen_server).

%% API
-export([
    start_link/0,
    stop/0,
    create_room/2,
    join_room/2,
    leave_room/2,
    rename_room/3,
    send/3,
    invite/3,
    kick/3
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-define(SERVER, ?MODULE).

-record(state, {
    num_rooms = 0
}).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

stop() ->
    gen_server:call(?SERVER, stop).

create_room(RoomName, SessionId) ->
    gen_server:call(?SERVER, {create_room, RoomName, SessionId}).

join_room(RoomName, SessionId) ->
    gen_server:call(?SERVER, {join_room, RoomName, SessionId}).

leave_room(RoomName, SessionId) ->
    gen_server:call(?SERVER, {leave_room, RoomName, SessionId}).

rename_room(RoomName, NewName, SessionId) ->
    gen_server:call(?SERVER, {rename_room, RoomName, NewName, SessionId}).

send(RoomName, Message, SessionId) ->
    gen_server:call(?SERVER, {send_message, RoomName, Message, SessionId}).

invite(RoomName, TargetUser, SessionId) ->
    gen_server:call(?SERVER, {invite, RoomName, TargetUser, SessionId}).

kick(RoomName, TargetUser, SessionId) ->
    gen_server:call(?SERVER, {kick, RoomName, TargetUser, SessionId}).


%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    {ok, #state{}}.

handle_call(stop, _From, State) ->
    {stop, normal, ok, State};

handle_call({create_room, _RoomName, _SessionId}, _From, State) ->
    {reply, ok, State};

handle_call({join_room, _RoomName, _SessionId}, _From, State) ->
    {reply, ok, State};

handle_call({leave_room, _RoomName, _SessionId}, _From, State) ->
    {reply, ok, State};

handle_call({rename_room, _RoomName, _NewName, _SessionId}, _From, State) ->
    {reply, ok, State};

handle_call({send_message, _RoomName, _Message, _SessionId}, _From, State) ->
    {reply, ok, State};

handle_call({invite, _RoomName, _TargetUser, _SessionId}, _From, State) ->
    {reply, ok, State};

handle_call({kick, _RoomName, _TargetUser, _SessionId}, _From, State) ->
    {reply, ok, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_call}, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.