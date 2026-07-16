%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(registry_sup).
-behaviour(supervisor).

%% API
-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init(_Args) ->
    SupervisorSpecification = #{
        strategy => one_for_one, 
        intensity => 10,
        period => 60},

    ChildSpecifications = [
        worker_spec(session_registry, []),
        worker_spec(room_registry, [])
    ],

    {ok, {SupervisorSpecification, ChildSpecifications}}.



worker_spec(Module, Args) ->
    #{
        id => Module,
        start => {Module, start_link, Args},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [Module]
    }.

