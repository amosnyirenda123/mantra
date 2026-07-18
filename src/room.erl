%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc 
%%%
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>
-module(room).
-behaviour(gen_server).

%% API
-export([stop/1, start_link/1]).
-export([
    get_messages/1, 
    get_members/1, 
    get_moderators/1,
    add_moderator/2, 
    add_member/2, 
    get_owner/1, 
    rename/2, 
    add_message/2, 
    remove_member/2, 
    add_to_join_requests/2, 
    add_invitation/2, 
    accept_invitation/2, 
    reject_invitation/2, 
    promote_join_request/2, 
    promote_all_join_requests/1, 
    remove_moderator/2
]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    room_name,
    owner, %id of user
    members = [],  %list of user id's
    messages = [],
    moderators = [], %list of user id's
    permissions = [],
    join_requests = [],
    invitations = [], % {UserId, InvitationTime, Expiry, IsAccepted}
    created_at,
    last_active_at
}).



start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).

stop(RoomPid) ->
    gen_server:call(RoomPid, stop).

init({RoomName, Owner}) ->
    Now = erlang:system_time(second),
    {ok, #state{
        room_name = RoomName,
        owner = Owner,
        created_at = Now,
        last_active_at = Now
    }}.


get_owner(RoomPid) ->
    gen_server:call(RoomPid, {get_owner}).

rename(RoomPid, NewName) ->
    gen_server:call(RoomPid, {rename, NewName}).

add_message(RoomPid, Message) ->
    gen_server:call(RoomPid, {add_message, Message}).

remove_member(RoomPid, UserId) ->
    gen_server:call(RoomPid, {remove_member, UserId}).

get_messages(RoomPid) ->
    gen_server:call(RoomPid, {get_messages}).

get_members(RoomPid) ->
    gen_server:call(RoomPid, {get_members}).

get_moderators(RoomPid) ->
    gen_server:call(RoomPid, {get_moderators}).

add_moderator(RoomPid, UserId) ->
    gen_server:call(RoomPid, {add_moderator, UserId}).

remove_moderator(RoomPid, UserId) ->
    gen_server:call(RoomPid, {remove_moderator, UserId}).

add_member(RoomPid, UserId) ->
    gen_server:call(RoomPid, {add_member, UserId}).

add_to_join_requests(RoomPid, UserId) ->
    gen_server:call(RoomPid, {add_to_join_requests, UserId}).

add_invitation(RoomPid, {UserId, Start, Expiry}) ->
    gen_server:call(RoomPid, {add_invitation, UserId, Start, Expiry}).

accept_invitation(RoomPid, UserId) ->
    gen_server:call(RoomPid, {accept_invitation, UserId}).

reject_invitation(RoomPid, UserId) ->
    gen_server:call(RoomPid, {reject_invitation, UserId}).

promote_join_request(RoomPid, UserId) ->
    gen_server:call(RoomPid, {promote_join_request, UserId}).

promote_all_join_requests(RoomPid) ->
    gen_server:call(RoomPid, {promote_all_join_requests}).


handle_call(stop, _From, State) ->
    {stop, normal, stopped, State};

handle_call({get_messages}, _From, State) ->
    {reply, State#state.messages, State};

handle_call({get_owner}, _From, State) ->
    {reply, State#state.owner, State};

handle_call({rename, NewName}, _From, State) ->
    {reply, ok, State#state{room_name = NewName}};

handle_call({add_message, Message}, _From, State) ->
    {reply, ok, State#state{messages = State#state.messages ++ [Message]}};

handle_call({add_invitation, UserId, Start, Expiry}, _From, State) ->
    Invitation = {UserId, Start, Expiry, false},
    {reply, ok, State#state{invitations = State#state.invitations ++ [Invitation]}};

handle_call({promote_join_request, UserId}, _From, State) ->
    case lists:member(UserId, State#state.join_requests) of
        true ->
            NewState = State#state{
                join_requests = lists:delete(UserId, State#state.join_requests),
                members = [UserId | State#state.members]
            },
            {reply, ok, NewState};
        false ->
            {reply, {error, not_requested}, State}
    end;

handle_call({promote_all_join_requests}, _From, State) ->
    NewState = State#state{
        members = State#state.join_requests ++ State#state.members,
        join_requests = []
    },
    {reply, ok, NewState};

handle_call({accept_invitation, UserId}, _From, State) ->
    Now = erlang:system_time(second),
    case lists:keyfind(UserId, 1, State#state.invitations) of
        {UserId, _Start, Expiry, false} when Expiry >= Now ->
            NewInvitations = lists:keydelete(UserId, 1, State#state.invitations),
            NewState = State#state{
                invitations = NewInvitations,
                members = [UserId | State#state.members]
            },
            {reply, ok, NewState};
        {UserId, _Start, _Expiry, false} ->
            {reply, {error, expired}, State};
        {UserId, _Start, _Expiry, true} ->
            {reply, {error, already_accepted}, State};
        false ->
            {reply, {error, not_invited}, State}
    end;

handle_call({reject_invitation, UserId}, _From, State) ->
    case lists:keyfind(UserId, 1, State#state.invitations) of
        {UserId, _Start, _Expiry, false} ->
            NewInvitations = lists:keydelete(UserId, 1, State#state.invitations),
            {reply, ok, State#state{invitations = NewInvitations}};
        {UserId, _Start, _Expiry, true} ->
            {reply, {error, already_accepted}, State};
        false ->
            {reply, {error, not_invited}, State}
    end;



handle_call({remove_moderator, UserId}, _From, State) ->
    NewState = State#state{moderators = lists:delete(UserId, State#state.moderators)},
    {reply, ok, NewState};

handle_call({remove_member, UserId}, _From, State) ->
    NewState = State#state{members = lists:delete(UserId, State#state.members)},
    {reply, ok, NewState};

handle_call({get_members}, _From, State) ->
    {reply, State#state.members, State};

handle_call({get_moderators}, _From, State) ->
    {reply, State#state.moderators, State};

handle_call({add_moderator, UserId}, _From, State) ->
    NewState = State#state{moderators = [UserId | State#state.moderators]},
    {reply, ok, NewState};

handle_call({add_member, UserId}, _From, State) ->
    case lists:member(UserId, State#state.members) of
        true ->
            {reply, {error, already_member}, State};
        false ->
            NewState = State#state{members = [UserId | State#state.members]},
            {reply, ok, NewState}
    end;

handle_call({add_to_join_requests, UserId}, _From, State) ->
    NewState = State#state{join_requests = [UserId | State#state.join_requests]},
    {reply, ok, NewState};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.