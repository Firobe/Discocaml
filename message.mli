open Types_t

type t = message

(** Type of querty to be passed to {!query} *)
type query_type = Around | Before | After

(** [Message.query bot ~channel_id ~query ~message_id ~limit] retrieves the list
    of (maximum) [limit] messages around, before or after (depending on [query])
    the given message.
*)
val query : Bot.t -> channel_id : string -> query : query_type ->
  message_id : string -> limit : int -> t list Lwt.t

(** [Message.get bot ~channel_id ~message_id] retrieves the [message_id] in
    [channel_id] and returns it.
*)
val get : Bot.t -> channel_id : string -> message_id : string -> t Lwt.t

(** [Message.send bot ~channel_id cm] send the given {!create_message} (which
    can be constructed with {!create}) to [channel_id] and returns a
    complete {!message}.
*)
val send : Bot.t -> channel_id : string -> create_message -> t Lwt.t

(** [Message.edit bot ~channel_id ~message_id ~content ~embed] edits
    [message_id] in [channel_id] with the new (optionals) [content] and [embed].
*)
val edit : Bot.t -> channel_id : string -> message_id : string ->
  ?content : string -> ?embed : embed -> unit -> t Lwt.t

(** [Message.delete bot ~channel_id ~message_id] deletes [message_id] in
    [channel_id] *)
val delete : Bot.t -> channel_id : string -> message_id : string -> unit Lwt.t

(** [Message.bulk_delete bot ~channel_id to_delete] deletes every message with
    its id in [to_delete] in [channel_id].

    Note that it can only delete up to 100 messages that may not be older than 2
    weeks.
*)
val bulk_delete : Bot.t -> channel_id : string -> string list -> unit Lwt.t

(* Util *)

(** Creates a {!create_message} object that can then be sent using {!send}. *)
val create : content:string -> ?nonce:string -> ?tts:bool -> ?file:string ->
  ?embed:Types_v.embed -> ?payload_json:string -> unit -> Types_v.create_message

(** [Message.mentions message user] returns [true] if the [message] mentions
    [user]
*)
val mentions : t -> Types_t.user -> bool

