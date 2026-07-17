%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>

-module(connection).

-export([start_link/1]).

-record(state, {
    socket,
    session_id = undefined
}).

%%====================================================================
%% API
%%====================================================================

start_link(Socket) ->
    Pid = spawn_link(fun() ->
        receive
            activate ->
                State = #state{socket = Socket},
                connection_handler(State)
        end
    end),
    {ok, Pid}.

%%====================================================================
%% Internal
%%====================================================================

connection_handler(State = #state{socket = Socket}) ->
    inet:setopts(Socket, [{active, once}]),
    loop(State).

loop(State = #state{socket = Socket}) ->
    receive
        {tcp, Socket, Data} ->
            NewState = handle_command(Data, State),
            inet:setopts(Socket, [{active, once}]),
            loop(NewState);

        {tcp_closed, Socket} ->
            io:format("Client disconnected.~n"),
            ok;

        {tcp_error, Socket, Reason} ->
            io:format("Socket error: ~p~n", [Reason]),
            ok
    end.

handle_command(Data, State = #state{socket = Socket}) ->
    case command_parser:parse(binary_to_list(Data)) of

        {command, Cmd, [Username], _Flags}
                when Cmd =:= login;
                     Cmd =:= register;
                     Cmd =:= logout ->
            case handle_session_command(Cmd, Username, State) of
                {ok, SessionId} ->
                    gen_tcp:send(Socket, <<"OK.">>),
                    State#state{session_id = SessionId};

                ok ->
                    gen_tcp:send(Socket, <<"OK.">>),
                    State;

                {error, Reason} ->
                    gen_tcp:send(Socket, format_error(Reason)),
                    State
            end;

        {command, Cmd, Args, _Flags}
                when Cmd =:= create_room;
                     Cmd =:= join_room;
                     Cmd =:= leave_room;
                     Cmd =:= rename_room;
                     Cmd =:= send_message;
                     Cmd =:= invite;
                     Cmd =:= kick ->
            case handle_room_command(Cmd, Args, State) of
                ok ->
                    gen_tcp:send(Socket, <<"OK.">>),
                    State;

                {error, Reason} ->
                    gen_tcp:send(Socket, format_error(Reason)),
                    State
            end;

        {command, Cmd, Args, _Flags} ->
            case handle_utility_command(Cmd, Args, State) of
                ok ->
                    gen_tcp:send(Socket, <<"OK.">>),
                    State;

                {error, Reason} ->
                    gen_tcp:send(Socket, format_error(Reason)),
                    State
            end;

        {error, unknown_command} ->
            gen_tcp:send(Socket, <<"Bad Command.">>),
            State
    end.

%%====================================================================
%% Utility Commands
%%====================================================================

handle_utility_command(_Cmd, _Args, _State) ->
    ok.

%%====================================================================
%% Session Commands
%%====================================================================

handle_session_command(login, Username, _State) ->
    session_manager:login(Username);

handle_session_command(register, Username, _State) ->
    session_manager:register(Username);

handle_session_command(logout, Username, _State) ->
    session_manager:logout(Username).

%%====================================================================
%% Room Commands
%%====================================================================

handle_room_command(_Cmd, _Args, #state{session_id = undefined}) ->
    {error, authentication_required};

handle_room_command(create_room,
                    [RoomName],
                    #state{session_id = SessionId}) ->
    room_manager:create_room(RoomName, SessionId);

handle_room_command(join_room,
                    [RoomName],
                    #state{session_id = SessionId}) ->
    room_manager:join_room(RoomName, SessionId);

handle_room_command(leave_room,
                    [RoomName],
                    #state{session_id = SessionId}) ->
    room_manager:leave_room(RoomName, SessionId);

handle_room_command(rename_room,
                    [RoomName, NewName],
                    #state{session_id = SessionId}) ->
    room_manager:rename_room(RoomName, NewName, SessionId);

handle_room_command(send_message,
                    [RoomName, Message],
                    #state{session_id = SessionId}) ->
    room_manager:send(RoomName, Message, SessionId);

handle_room_command(invite,
                    [RoomName, TargetUser],
                    #state{session_id = SessionId}) ->
    room_manager:invite(RoomName, TargetUser, SessionId);

handle_room_command(kick,
                    [RoomName, TargetUser],
                    #state{session_id = SessionId}) ->
    room_manager:kick(RoomName, TargetUser, SessionId);

handle_room_command(_Cmd, _Args, _State) ->
    {error, bad_arguments}.

%%====================================================================
%% Helpers
%%====================================================================

format_error(authentication_required) ->
    <<"Error: login required.">>;

format_error(bad_arguments) ->
    <<"Error: bad arguments.">>;

format_error(_) ->
    <<"Error: command failed.">>.