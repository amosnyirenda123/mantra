%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(user_session_sup).

-behaviour(supervisor).

%% API
-export([start_link/0, start_user_session/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_user_session() ->
    supervisor:start_child(?MODULE, []).

init(_Args) ->
    SupervisorSpecification = #{
        strategy => simple_one_for_one, 
        intensity => 10,
        period => 60},

    ChildSpecifications = [
        #{
            id => user_session,
            start => {user_session, start_link, []},
            restart => temporary,
            shutdown => 5000,
            type => worker,
            modules => [user_session]
        }
    ],

    {ok, {SupervisorSpecification, ChildSpecifications}}.
