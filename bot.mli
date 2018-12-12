(** Toplevel functions for the API. Most functions in the library return
    a Lwt promise, so they must be chained accordingly.

    For example, [Bot.create token >>= Bot.launch handler |> Lwt_main.run]
    effectively creates and launch a new bot with the given token and handler.
*)

type t

(** The type of event that the bot may receive and handle *)
type event = Types_t.event_kind

(** [Bot.create token] creates a new idle bot with the given Discord bot token *)
val create : string -> t Lwt.t

(** [Bot.launch handler bot] takes a handler function and bot created with {!create}
    and returns a promise that is resolved only when the bot stops (when the
    connection is closed, for example).

    A handler function takes an {!event} and process it, returning a unit
    promise.

    If the handler raises an exception, it is caught by the API and printed on
    the standard error output by default.

    Note that while the processing of an event by the handler is pending (for
    example if the handler is waiting for I/O), the bot may receive any number
    of other events and concurrently call the handler for each of them.
*)
val launch : (t -> event -> unit Lwt.t) -> t -> unit Lwt.t

(** [Bot.stop bot] waits for current pending events to be processed then stops the
    bot, thus resolving the promise returned by {!launch}.

    It may be called inside the handler.
*)
val stop : t -> unit Lwt.t

(** [Bot.user bot] returns the User object associated to a {b running} bot. *)
val user : t -> Types_t.user

(** [Bot.token bot] returns the token associated to a bot. *)
val token : t -> string
