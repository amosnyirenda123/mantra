%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 17 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(cli_spec).
-include("flag_spec.hrl").
-export([commands/0]).


commands() ->
    #{
        login => #{
            "--password" =>
                #flag_spec{
                    required = false,
                    takes_value = true,
                    aliases = ["-p"]
                }
        },
        create_room => #{},
        join_room => #{},
        leave_room => #{},
        lookup_room => #{},
        rename_room => #{},
        send_message => #{},
        invite => #{},
        kick => #{}
    }.

