open Types_t

type t = channel

(** {b REST API} *)

(** [Channel.get bot ~channel_id] retrieves the {!channel} with the given id and
    returns it.
*)
val get : Bot.t -> channel_id : string -> t Lwt.t

(** [Channel.get bot ~channel] updates [channel_id] to match the given
    {!channel} and returns the newly updated channel.
*)
val modify : Bot.t -> channel : t -> t Lwt.t

(** [Channel.delete bot ~channel_id] deletes [channel_id] (or
    closes it if it is a DM channel.
*)
val delete : Bot.t -> channel_id : string -> t Lwt.t

(** [Channel.create_invite bot ~channel_id ...] creates an invite for
    [channel_id] with the given parameters. [max_age] is the duration of the
    invite in seconds. [max_uses] must be set to zero to have unlimited uses.
*)
val create_invite : Bot.t -> channel_id : string ->
  ?max_age : int -> ?max_uses : int -> ?temporary : bool ->
  ?unique : bool -> unit -> invite Lwt.t

(** [Channel.edit_permission bot ~channel_id ~overwrite_id ~allow ~deny ~kind]
    edits the permissions for a user ([kind] = "member") or a role
    ([kind] = "role") in [channel_id], listing what he is allowed to do and
    denied.
*)
val edit_permission : Bot.t -> channel_id : string ->
  overwrite_id : string -> allow : int -> deny : int ->
  kind : string -> unit Lwt.t

(** [Channel.delete_permission bot ~channel_id ~overwrite_id] deletes the given
    overwrite in [channel_id].
*)
val delete_permission : Bot.t -> channel_id : string ->
  overwrite_id : string -> unit Lwt.t

(** [Channel.trigger_typing bot ~channel_id] triggers the typing indicator in
    [channel_id].
*)
val trigger_typing : Bot.t -> channel_id : string -> unit Lwt.t

(** [Channel.get_pinned_message bot ~channel_id] retrieves and returns
    the pinned messages of [channel_id].
*)
val get_pinned_messages : Bot.t -> channel_id : string ->
  message list Lwt.t

(** [Channel.add_pinned_message bot ~channel_id ~message_id] adds
    [message_id] to the pinned messages of [channel_id].
*)
val add_pinned_message : Bot.t -> channel_id : string ->
  message_id : string -> unit Lwt.t

(** [Channel.delete_pinned_message bot ~channel_id ~message_id] deletes
    [message_id] from the pinned messages of [channel_id].
*)
val delete_pinned_message : Bot.t -> channel_id : string ->
  message_id : string -> unit Lwt.t

(** [Channel.add_dm_recipient bot ~channel_id ~user_id ~access_token ~nick] adds
    [user_id] to [channel_id] provided the latter is a group DM channel with the
    given [nick]name using the provided access token.
*)
val add_dm_recipient : Bot.t -> channel_id : string ->
  user_id : string -> access_token : string -> nick : string -> unit Lwt.t

(** [Channel.remove_dm_recipient bot ~channel_id ~user_id] removes
    [user_id] from [channel_id] provided the latter is a group DM channel.
*)
val remove_dm_recipient : Bot.t -> channel_id : string ->
  user_id : string -> unit Lwt.t
