%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(room_registry).
-export([start_link/0]).

start_link() ->
    Pid = spawn_link(fun() -> receive stop -> ok end end),
    {ok, Pid}.

