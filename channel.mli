open Types_t

type t = channel

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

val create_invite : Bot.t -> channel_id : string ->
  ?max_age : int -> ?max_uses : int -> ?temporary : bool ->
  ?unique : bool -> unit -> invite Lwt.t

val edit_permission : Bot.t -> channel_id : string ->
  overwrite_id : string -> allow : bool -> deny : bool ->
  kind : string -> unit Lwt.t

val delete_permission : Bot.t -> channel_id : string ->
  overwrite_id : string -> unit Lwt.t

val trigger_typing : Bot.t -> channel_id : string -> unit Lwt.t

val get_pinned_messages : Bot.t -> channel_id : string ->
  Message.t list Lwt.t

val add_pinned_message : Bot.t -> channel_id : string ->
  message_id : string -> unit Lwt.t

val delete_pinned_message : Bot.t -> channel_id : string ->
  message_id : string -> unit Lwt.t
