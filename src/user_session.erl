%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(user_session).
-behaviour(gen_server).

-define(GRACE_PERIOD_MS, 30000).

%% API
-export([start_link/4, attach/2, detach/1, deliver/2, revoke/1, get_info/1, get_user_id/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(session, {
    session_id,
    user_id,
    conn_pid,          % undefined when disconnected
    conn_mon_ref,      % monitor ref for conn_pid, so we notice it dying
    device_id,
    created_at,
    last_active_at,
    status = active,   % active | revoked
    expiry_ref         % timer ref for the disconnect grace period
}).

%%====================================================================
%% API
%%====================================================================

start_link(UserId, SessionId, ConnPid, DeviceId) ->
    gen_server:start_link(?MODULE, {UserId, SessionId, ConnPid, DeviceId}, []).

%% Called by a (possibly new) connection process to bind itself to
%% this session -- both on initial login and on reconnect.
attach(SessionPid, ConnPid) ->
    gen_server:call(SessionPid, {attach, ConnPid}).

%% Called when the connection drops. Starts the grace-period timer
%% instead of killing the session outright.
detach(SessionPid) ->
    gen_server:cast(SessionPid, detach).

%% Fan-out delivery goes through here rather than messaging conn_pid
%% directly, so the session decides what "connected" means.
deliver(SessionPid, Message) ->
    gen_server:cast(SessionPid, {deliver, Message}).

revoke(SessionPid) ->
    gen_server:call(SessionPid, revoke).

get_info(SessionPid) ->
    gen_server:call(SessionPid, get_info).

get_user_id(SessionPid) ->
    gen_server:call(SessionPid, get_user_id).

%%====================================================================
%% gen_server callbacks
%%====================================================================

init({UserId, SessionId, ConnPid, DeviceId}) ->
    Ref = erlang:monitor(process, ConnPid),
    Now = erlang:system_time(second),
    {ok, #session{
        session_id = SessionId,
        user_id = UserId,
        conn_pid = ConnPid,
        conn_mon_ref = Ref,
        device_id = DeviceId,
        created_at = Now,
        last_active_at = Now
    }}.

handle_call({attach, ConnPid}, _From, State) ->
    %% Cancel any pending expiry from a previous disconnect.
    cancel_expiry(State#session.expiry_ref),
    %% Drop the old monitor if one existed, then monitor the new conn.
    Ref = erlang:monitor(process, ConnPid),
    {reply, ok, State#session{
        conn_pid = ConnPid,
        conn_mon_ref = Ref,
        expiry_ref = undefined,
        last_active_at = erlang:system_time(second)
    }};

handle_call(revoke, _From, State) ->
    {stop, normal, ok, State#session{status = revoked}};

handle_call(get_info, _From, State) ->
    {reply, {ok, State}, State};

handle_call(get_user_id, _From, State) ->
    {reply, {ok, State#session.user_id}, State};

handle_call(_Request, _From, State) ->
    {reply, {error, unknown_call}, State}.

handle_cast(detach, State) ->
    {noreply, start_expiry(State#session{conn_pid = undefined})};

handle_cast({deliver, _Message}, #session{conn_pid = undefined} = State) ->
    %% Not connected right now -- simplest option is to drop it.
    %% (Swap in a buffer/queue here later if you need delivery
    %% guarantees across reconnects.)
    {noreply, State};

handle_cast({deliver, Message}, #session{conn_pid = ConnPid} = State) ->
    ConnPid ! {session_message, Message},
    {noreply, State#session{last_active_at = erlang:system_time(second)}};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% conn_pid died without a clean detach -- treat it the same as detach.
handle_info({'DOWN', Ref, process, _Pid, _Reason}, #session{conn_mon_ref = Ref} = State) ->
    {noreply, start_expiry(State#session{conn_pid = undefined})};

%% Grace period expired with no reconnect -- session is done.
handle_info({expire, Ref}, #session{expiry_ref = Ref} = State) ->
    {stop, normal, State};

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%====================================================================
%% internal
%%====================================================================

start_expiry(State) ->
    Ref = make_ref(),
    erlang:send_after(?GRACE_PERIOD_MS, self(), {expire, Ref}),
    State#session{expiry_ref = Ref}.

cancel_expiry(undefined) -> ok;
cancel_expiry(_Ref) -> ok. % timer message is matched against current expiry_ref and ignored if stale


