%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%% Manages chat room lifecycle and room operations.
%%% @end
%%% Created : 14 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>

-module(room_manager).
-define(INVITE_EXPIRY_IN_DAYS, 10). 

%% API
-export([
    create_room/2,
    join_room/2,
    leave_room/2,
    rename_room/3,
    send/3,
    invite/3,
    kick/3,
    accept_invitation/2,
    reject_invitation/2,
    approve_join_request/3,
    approve_all_join_requests/2,
    add_moderator/3,
    add_member/3,
    remove_member/3,
    remove_moderator/3
]).

room_pid(RoomName) ->
    room_registry:lookup(RoomName).
    

create_room(RoomName, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, _RoomPid} ->
                    {error, room_exists};
                {error, not_found} ->
                    case room_sup:start_room(RoomName, UserId) of
                        {ok, RoomPid} ->
                            room_registry:register(RoomPid, RoomName),
                            {ok, RoomPid};
                        {error, Reason} ->
                            {error, Reason}
                    end
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

join_room(RoomName, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} -> room:add_to_join_requests(RoomPid, UserId);
                {error, not_found} -> {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.


approve_join_request(RoomName, TargetUser, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case is_owner_or_mod(RoomPid, UserId) of
                        true -> room:promote_join_request(RoomPid, TargetUser);
                        false -> {error, not_authorized}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

approve_all_join_requests(RoomName, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case is_owner_or_mod(RoomPid, UserId) of
                        true -> room:promote_all_join_requests(RoomPid);
                        false -> {error, not_authorized}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

leave_room(RoomName, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case room:get_owner(RoomPid) of
                        UserId ->
                            room_registry:unregister(RoomName),
                            room:stop(RoomPid);
                        _ ->
                            room:remove_member(RoomPid, UserId)
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

rename_room(RoomName, NewName, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case room:get_owner(RoomPid) of
                        UserId -> room:rename(RoomPid, NewName);
                        _ -> {error, not_owner}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

send(RoomName, Message, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} -> room:add_message(RoomPid, {UserId, Message});
                {error, not_found} -> {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

invite(RoomName, TargetUser, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case is_owner_or_mod(RoomPid, UserId) of
                        true ->
                            Now = erlang:system_time(second),
                            Expiry = Now + (?INVITE_EXPIRY_IN_DAYS * 86400),
                            room:add_invitation(RoomPid, {TargetUser, Now, Expiry});
                        false -> {error, not_authorized}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.


accept_invitation(RoomName, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} -> room:accept_invitation(RoomPid, UserId);
                {error, not_found} -> {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

reject_invitation(RoomName, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} -> room:reject_invitation(RoomPid, UserId);
                {error, not_found} -> {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

kick(RoomName, TargetUser, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case is_owner_or_mod(RoomPid, UserId) of
                        true -> room:remove_member(RoomPid, TargetUser);
                        false -> {error, not_authorized}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.



add_moderator(RoomName, TargetUser, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case room:get_owner(RoomPid) of
                        UserId -> room:add_moderator(RoomPid, TargetUser);
                        _ -> {error, not_owner}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.


add_member(RoomName, TargetUser, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case is_owner_or_mod(RoomPid, UserId) of
                        true -> room:add_member(RoomPid, TargetUser);
                        false -> {error, not_authorized}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

remove_member(RoomName, TargetUser, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case is_owner_or_mod(RoomPid, UserId) of
                        true -> room:remove_member(RoomPid, TargetUser);
                        false -> {error, not_authorized}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.

remove_moderator(RoomName, TargetUser, SessionId) ->
    case session_manager:get_user_id(SessionId) of
        {ok, UserId} ->
            case room_pid(RoomName) of
                {ok, RoomPid} ->
                    case room:get_owner(RoomPid) of
                        UserId -> room:remove_moderator(RoomPid, TargetUser);
                        _ -> {error, not_owner}
                    end;
                {error, not_found} ->
                    {error, room_not_found}
            end;
        {error, not_found} ->
            {error, invalid_session}
    end.


is_owner_or_mod(RoomPid, UserId) ->
    case room:get_owner(RoomPid) of
        UserId -> true;
        _ -> lists:member(UserId, room:get_moderators(RoomPid))
    end.