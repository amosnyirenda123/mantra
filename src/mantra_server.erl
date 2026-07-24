%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(mantra_server).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    mantra_server_sup:start_link().

stop(_State) ->
    ok.
