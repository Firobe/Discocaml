open Types_t

type t = user

val get : Bot.t -> user_id : string -> t Lwt.t

val get_self : Bot.t -> t Lwt.t

val modify : Bot.t -> username : string -> t Lwt.t

val get_guilds : Bot.t -> Guild.t list Lwt.t

val leave_guild : Bot.t -> guild_id : string -> unit Lwt.t

val get_dms : Bot.t -> Channel.t list Lwt.t

val create_dm : Bot.t -> recipient_id : string -> Channel.t Lwt.t
