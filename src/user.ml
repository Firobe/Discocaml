open Lwt
open Types_t

type t = user

let get bot ~user_id =
  Http.call (Bot.token bot) `GET
    (Http.Endpoints.User.user user_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.user_of_string

let get_self bot =
  Http.call (Bot.token bot) `GET
    (Http.Endpoints.User.user "@me")
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.user_of_string

let modify bot ~username (* TODO avatar *) =
  let body = Yojson.Safe.to_string (`Assoc [("username", `String username)]) in
  Http.call (Bot.token bot) ~body `PATCH
    (Http.Endpoints.User.user "@me")
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.user_of_string

let get_guilds bot =
  Http.call (Bot.token bot) `GET
    (Http.Endpoints.User.guilds "@me")
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.guild_array_of_string

let leave_guild bot ~guild_id =
  Http.call (Bot.token bot) `DELETE
    (Http.Endpoints.User.guild "@me" guild_id)
  >>= Http.check_code 204 >|= ignore

let get_dms bot =
  Http.call (Bot.token bot) `GET
    (Http.Endpoints.User.channels "@me")
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.channel_array_of_string

let create_dm bot ~recipient_id =
  let body = Yojson.Safe.to_string (`Assoc ["recipient_id", `String recipient_id]) in
  Http.call (Bot.token bot) ~body `POST
    (Http.Endpoints.User.channels "@me")
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.channel_of_string
