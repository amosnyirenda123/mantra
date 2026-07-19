%%% @author Nyirenda Amos <nyirendaamos1@gmail.com>
%%% @copyright (C) 2026, Nyirenda Amos
%%% @doc
%%% Human-readable error messages.
%%% @end
%%% Created : 19 Jul 2026 by Nyirenda Amos <nyirendaamos1@gmail.com>

-module(mantra_errors).

-export([format_error/1]).

%% Authentication

format_error(authentication_required) ->
    <<"Error: authentication required.">>;

format_error(invalid_session) ->
    <<"Error: your session is invalid or has expired.">>;

format_error(missing_password) ->
    <<"Error: password is required.">>;

format_error(username_taken) ->
    <<"Error: username is already taken.">>;

format_error(invalid_credentials) ->
    <<"Error: invalid username or password.">>;

format_error(bad_arguments) ->
    <<"Error: invalid command arguments.">>;

%% Rooms

format_error(room_not_found) ->
    <<"Error: room not found.">>;

format_error(room_exists) ->
    <<"Error: a room with that name already exists.">>;

format_error(not_authorized) ->
    <<"Error: you are not authorized to perform this operation.">>;

format_error(not_owner) ->
    <<"Error: only the room owner can perform this operation.">>;

%% Members

format_error(already_member) ->
    <<"Error: user is already a member of the room.">>;

format_error(not_member) ->
    <<"Error: user is not a member of the room.">>;

%% Moderators

format_error(already_moderator) ->
    <<"Error: user is already a moderator.">>;

format_error(not_moderator) ->
    <<"Error: user is not a moderator.">>;

%% Join Requests

format_error(already_requested) ->
    <<"Error: user has already requested to join this room.">>;

format_error(join_request_not_found) ->
    <<"Error: join request not found.">>;

%% Invitations

format_error(already_invited) ->
    <<"Error: user already has a pending invitation.">>;

format_error(invitation_not_found) ->
    <<"Error: invitation not found.">>;

format_error(invitation_expired) ->
    <<"Error: invitation has expired.">>;

format_error(invitation_already_accepted) ->
    <<"Error: invitation has already been accepted.">>;

%% Generic

format_error(not_found) ->
    <<"Error: requested resource not found.">>;

format_error(_) ->
    <<"Error: operation failed.">>.