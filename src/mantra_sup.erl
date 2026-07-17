%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(mantra_sup).
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
        supervisor_spec(gateway_sup, gateway_sup),
        supervisor_spec(room_sup, room_sup),
        supervisor_spec(user_session_sup, user_session_sup),
        supervisor_spec(registry_sup, registry_sup),
        supervisor_spec(connection_sup, connection_sup),
        worker_spec(room_manager, room_manager),
        worker_spec(session_manager, session_manager)
    ],

    {ok, {SupervisorSpecification, ChildSpecifications}}.



supervisor_spec(Id, Module) ->
    #{
        id => Id,
        start => {Module, start_link, []},
        restart => permanent,
        shutdown => infinity,
        type => supervisor,
        modules => [Module]
    }.

worker_spec(Id, Module) ->
    #{
        id => Id,
        start => {Module, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [Module]
    }.

