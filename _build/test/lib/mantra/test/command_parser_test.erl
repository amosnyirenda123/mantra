%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(command_parser_test).


-include_lib("eunit/include/eunit.hrl").
-include("command.hrl").

create_room_test() ->
    Result = command_parser:parse("CREATE ROOM lobby"),
    ?assertEqual(create_room, Result#command.guide),
    ?assertEqual(["lobby"], Result#command.arguments).

join_room_with_flag_test() ->
    Result = command_parser:parse("JOIN ROOM lobby -password secret"),
    ?assertEqual(join_room, Result#command.guide),
    ?assertEqual(["lobby"], Result#command.arguments),
    ?assertEqual(#{password => "secret"}, Result#command.flags).

login_test() ->
    Result = command_parser:parse("LOGIN alice -token abc123"),
    ?assertEqual(login, Result#command.guide),
    ?assertEqual(["alice"], Result#command.arguments),
    ?assertEqual(#{token => "abc123"}, Result#command.flags).

unknown_command_test() ->
    Result = command_parser:parse("FOO BAR"),
    ?assertEqual({error, unknown_command}, Result).

no_arguments_test() ->
    Result = command_parser:parse("REGISTER"),
    ?assertEqual(register, Result#command.guide),
    ?assertEqual([], Result#command.arguments),
    ?assertEqual(#{}, Result#command.flags).

multiple_flags_test() ->
    Result = command_parser:parse("SEND hello -to bob -room lobby"),
    ?assertEqual(send, Result#command.guide),
    ?assertEqual(["hello"], Result#command.arguments),
    ?assertEqual(#{to => "bob", room => "lobby"}, Result#command.flags).
