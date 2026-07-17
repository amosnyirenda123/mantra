%%%-------------------------------------------------------------------
%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%% Manages session lifecycle and session operations.
%%% @end
%%%-------------------------------------------------------------------

-module(session_manager).

-behaviour(gen_server).

-define(SERVER, ?MODULE).

%% API
-export([
    start_link/0,
    stop/0,
    login/1,
    register/1,
    logout/1
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-record(state, {
    sessions = #{},      %% Username => [SessionPid]
    num_sessions = 0
}).

%%====================================================================
%% API
%%====================================================================

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

stop() ->
    gen_server:call(?SERVER, stop).

login(Username) ->
    gen_server:call(?SERVER, {login, Username}).

register(Username) ->
    gen_server:call(?SERVER, {register, Username}).

logout(Username) ->
    gen_server:call(?SERVER, {logout, Username}).

%%====================================================================
%% gen_server callbacks
%%====================================================================

init([]) ->
    {ok, #state{num_sessions = 0}}.

handle_call(stop, _From, State) ->
    {stop, normal, stopped, State};

handle_call({login, _Username}, _From, State) ->
    {reply, ok, State};

handle_call({register, _Username}, _From, State) ->
    {reply, ok, State};

handle_call({logout, _Username}, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.