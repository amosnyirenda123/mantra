%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(listener).
-export([start/1, acceptor/1, connection_handler/0]).

start(Port) ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [binary, {active, false}]),
    spawn(?MODULE, acceptor, [ListenSocket]).

acceptor(ListenSocket) ->
    {ok, Socket} = gen_tcp:accept(ListenSocket),

    %% Continue processing client requests in another process
    Pid = spawn(?MODULE, connection_handler, []),

    ok = gen_tcp:controlling_process(Socket, Pid),

    Pid ! {socket, Socket},

    %% Then continue accepting requests.
    acceptor(ListenSocket).

connection_handler() ->
    receive
        {socket, Socket} ->
            inet:setopts(Socket, [{active, once}]),
            loop(Socket)
    end.

loop(Socket) ->
    receive
        {tcp, Socket, Data} ->
            %% Process Data
            io:format("Received: ~p~n", [binary_to_list(Data)]),
            case command_parser:parse(binary_to_list(Data)) of
                {command, _Guide, _Args, _FlagsMap} ->
                    ok = gen_tcp:send(Socket, <<"Good Command.">>);
                {error, unknown_command} ->
                    ok = gen_tcp:send(Socket, <<"Bad Command.">>)
            end,
            inet:setopts(Socket, [{active, once}]),
            loop(Socket);

        {tcp_closed, Socket} ->
            io:format("Client disconnected.~n"),
            ok;

        {tcp_error, Socket, Reason} ->
            io:format("Socket error: ~p~n", [Reason]),
            ok
    end.
