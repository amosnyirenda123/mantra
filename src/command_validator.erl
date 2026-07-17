%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 17 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(command_validator).
-export([validate/2]).

-include("flag_spec.hrl").

validate(CmdName, ParsedFlags) ->
    Commands = cli_spec:commands(),
    case maps:find(CmdName, Commands) of
        error ->
            {error, {no_flag_specs, CmdName}};
        {ok, FlagSpecs} ->
            case check_unknown(ParsedFlags, FlagSpecs) of
                {error, _} = Err -> Err;
                ok -> check_required(FlagSpecs, ParsedFlags)
            end
    end.

check_unknown(ParsedFlags, FlagSpecs) ->
    Unknown = [F || F <- maps:keys(ParsedFlags), not maps:is_key(F, FlagSpecs)],
    case Unknown of
        [] -> ok;
        _  -> {error, {unknown_flags, Unknown}}
    end.

check_required(FlagSpecs, ParsedFlags) ->
    Missing = maps:fold(
        fun(Name, #flag_spec{required = true}, Acc) ->
                case maps:is_key(Name, ParsedFlags) of
                    true  -> Acc;
                    false -> [Name | Acc]
                end;
           (_Name, _Spec, Acc) ->
                Acc
        end,
        [],
        FlagSpecs
    ),
    case Missing of
        [] -> ok;
        _  -> {error, {missing_required_flags, Missing}}
    end.



