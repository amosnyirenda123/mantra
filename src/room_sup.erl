%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(room_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).
-export([start_room/2]).

%% Supervisor callbacks
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_room(RoomName, Owner) ->
    supervisor:start_child(?MODULE, [RoomName, Owner]).

init([]) ->
    SupFlags = #{
        strategy => simple_one_for_one,
        intensity => 10,
        period => 60
    },

    ChildSpecs = [
        #{
            id => room,
            start => {room, start_link, []},
            restart => transient,
            shutdown => 5000,
            type => worker,
            modules => [room]
        }
    ],

    {ok, {SupFlags, ChildSpecs}}.