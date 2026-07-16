%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(client).
-export([start/0]).


start() ->
    Host = "localhost",
    Port = 9000,

    % Connect to the server
    case gen_tcp:connect(Host, Port, [binary, {packet, 0}]) of
        {ok, Sock} ->
            io:format("Connected to server.~n", []),
            loop(Sock);
        {error, Reason} ->
            io:format("Connection failed: ~p~n", [Reason])
    end.


loop(Socket) ->
    Input = io:get_line(">> "),
    CleanInput = string:trim(Input),
 
    case CleanInput of
        "quit" ->
            gen_tcp:close(Socket),
            io:format("Connection closed.~n", []);
        _ ->

            BinInput = list_to_binary(CleanInput),
            ok = gen_tcp:send(Socket, BinInput),
 
            receive
                {tcp, Socket, Bin} ->
                    ReplyStr = binary_to_list(Bin),
                    io:format("Received: ~s~n", [ReplyStr]);
                {tcp_closed, Socket} ->
                    io:format("Server closed the connection.~n", []);
                {tcp_error, Socket, Reason} ->
                    io:format("Socket error: ~p~n", [Reason])
            end,
            loop(Socket)
    end.  
   
    
