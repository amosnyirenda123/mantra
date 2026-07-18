%%%-------------------------------------------------------------------
%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%% Orchestrates session lifecycle: authenticates, spawns a
%%% user_session process, and registers it in session_registry.
%%%
%%% This module is intentionally NOT a gen_server. It holds no state
%%% of its own -- the source of truth for "what sessions exist" lives
%%% in session_registry (lookup) and in each user_session process
%%% (the session's own data). Making this a gen_server would mean
%%% keeping a second, redundant map of sessions here that could drift
%%% out of sync with the registry, and would turn every login/logout
%%% across every connection into calls serialized through one mailbox
%%% for no benefit.
%%% @end
%%%-------------------------------------------------------------------

-module(session_manager).

%% API
-export([
    login/3,
    register/3,
    logout/1,
    get_session_pid/1
]).

%%====================================================================
%% API
%%====================================================================

%% Username, Password, ConnPid -> {ok, SessionId} | {error, Reason}
login(Username, Password, ConnPid) ->
    case auth_service:authenticate(Username, Password) of
        {ok, UserId} ->
            start_session(UserId, ConnPid);
        {error, Reason} ->
            {error, Reason}
    end.

%% Username, Password, ConnPid -> {ok, SessionId} | {error, Reason}
register(Username, Password, ConnPid) ->
    case auth_service:create_account(Username, Password) of
        {ok, UserId} ->
            start_session(UserId, ConnPid);
        {error, Reason} ->
            {error, Reason}
    end.

%% SessionId -> ok | {error, not_found}
logout(SessionId) ->
    case get_session_pid(SessionId) of
        {ok, SessionPid} ->
            user_session:revoke(SessionPid);
        {error, not_found} ->
            {error, authentication_required}
    end.

%% SessionId -> {ok, SessionPid} | {error, not_found}
get_session_pid(SessionId) ->
    session_registry:lookup_pid(SessionId).

%%====================================================================
%% Internal
%%====================================================================

start_session(UserId, ConnPid) ->
    SessionId = generate_session_id(),
    case user_session_sup:start_session(UserId, SessionId, ConnPid, undefined) of
        {ok, SessionPid} ->
            ok = session_registry:register(UserId, SessionId, SessionPid),
            {ok, SessionId};
        {error, Reason} ->
            {error, Reason}
    end.

generate_session_id() ->
    base64:encode(crypto:strong_rand_bytes(16)).