%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%% Human-readable error messages.
%%% @end
%%% Created : 19 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>

-module(mantra_format).
-export([incoming/1, outgoing/1]).

incoming(Message) ->
    io_lib:format("~p~n", [Message]).

outgoing(_Message) ->
    ok.