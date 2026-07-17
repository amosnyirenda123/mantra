%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(listener).
-export([start_link/1, acceptor/1]).

start_link(Port) ->
    Parent = self(),
    Pid = spawn_link(fun() -> init(Parent, Port) end),
    receive
        {Pid, ready} -> {ok, Pid}
    end.

init(Parent, Port) ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [binary, {active, false}]),
    Parent ! {self(), ready},
    acceptor(ListenSocket).

acceptor(ListenSocket) ->
    {ok, Socket} = gen_tcp:accept(ListenSocket),
    {ok, Pid} = connection_sup:start_connection(Socket),
    ok = gen_tcp:controlling_process(Socket, Pid),
    Pid ! activate,
    acceptor(ListenSocket).

