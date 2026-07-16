%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(command_parser).
-include("command.hrl").
-export([parse/1]).

parse(Command) ->
    Tokens = string:tokens(Command, " "),
    dispatch(Tokens).


dispatch(["CREATE", "ROOM" | Rest]) ->
    build_command(create_room, Rest);

dispatch(["JOIN", "ROOM" | Rest]) ->
    build_command(join_room, Rest);

dispatch(["LEAVE", "ROOM" | Rest]) ->
    build_command(leave_room, Rest);

dispatch(["LOOKUP", "ROOM" | Rest]) ->
    build_command(lookup_room, Rest);

dispatch(["RENAME", "ROOM" | Rest]) ->
    build_command(rename_room, Rest);

dispatch(["LOGIN" | Rest]) ->
    build_command(login, Rest);

dispatch(["REGISTER" | Rest]) ->
    build_command(register, Rest);

dispatch(["DELETE" | Rest]) ->
    build_command(delete, Rest);

dispatch(["SEND" | Rest]) ->
    build_command(send, Rest);

dispatch(["INVITE" | Rest]) ->
    build_command(invite, Rest);

dispatch(["KICK" | Rest]) ->
    build_command(kick, Rest);

dispatch(_) ->
    {error, unknown_command}.



build_command(Guide, Tokens) ->
    case split_arguments_and_flags(Tokens) of
        {error, Reason} ->
            {error, Reason};

        {Arguments, Flags} ->
            #command{
                guide = Guide,
                arguments = Arguments,
                flags = Flags
            }
    end.


split_arguments_and_flags(Tokens) ->
    split_arguments_and_flags(Tokens, [], #{}).

split_arguments_and_flags([], ArgumentsAcc, FlagsAcc) ->
    {lists:reverse(ArgumentsAcc), FlagsAcc};


split_arguments_and_flags([Token], ArgumentsAcc, FlagsAcc) ->
    case Token of
        [$- | Flag] ->
            {error, {missing_flag_value, list_to_atom(Flag)}};

        _ ->
            split_arguments_and_flags(
                [],
                [Token | ArgumentsAcc],
                FlagsAcc
            )
    end;

split_arguments_and_flags([Token, Value | Rest], ArgumentsAcc, FlagsAcc) ->
    case Token of
        [$- | Flag] ->
            split_arguments_and_flags(
                Rest,
                ArgumentsAcc,
                maps:put(list_to_atom(Flag), Value, FlagsAcc)
            );
        _ ->
            split_arguments_and_flags(
                [Value | Rest],
                [Token | ArgumentsAcc],
                FlagsAcc
            )
    end.





