%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(connection).
-export([start_link/1]).

start_link(Socket) ->
    Pid = spawn_link(fun() ->
        receive
            activate ->
                connection_handler(Socket)
        end
    end),
    {ok, Pid}.



connection_handler(Socket) ->
    inet:setopts(Socket, [{active, once}]),
    loop(Socket).


loop(Socket) ->
    receive
        {tcp, Socket, Data} ->
            io:format("Server Received: ~p~n", [Data]),
            handle_command(Socket, Data),
            inet:setopts(Socket, [{active, once}]), 
            loop(Socket);

        {tcp_closed, Socket} ->
            io:format("Client disconnected.~n"),
            ok;

        {tcp_error, Socket, Reason} ->
            io:format("Socket error: ~p~n", [Reason]),
            ok
    end.



handle_command(Socket, Data) ->
    case command_parser:parse(binary_to_list(Data)) of
        {command, _Guide, _Args, _FlagsMap} ->
            gen_tcp:send(Socket, <<"Good Command.">>);
        {error, unknown_command} ->
            gen_tcp:send(Socket, <<"Bad Command.">>)
    end.
