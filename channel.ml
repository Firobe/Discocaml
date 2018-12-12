open Lwt
open Types_t

type t = channel

let get bot ~channel_id =
  Http.call (Bot.token bot) `GET
    (Http.Endpoints.Channel.channel channel_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.channel_of_string

let modify bot ~(channel : t) = 
  Http.call (Bot.token bot) `PATCH
    (Http.Endpoints.Channel.channel channel.channel_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.channel_of_string

let delete bot ~channel_id =
  Http.call (Bot.token bot) `DELETE
    (Http.Endpoints.Channel.channel channel_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.channel_of_string

let create_invite bot ~channel_id ?max_age ?max_uses ?temporary ?unique () =
  let body = Types_j.string_of_create_invite {max_age; max_uses; temporary; unique} in
  Http.call (Bot.token bot) ~body `POST
    (Http.Endpoints.Channel.invites channel_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.invite_of_string

let edit_permission bot ~channel_id ~overwrite_id ~allow ~deny ~kind =
  let body = Yojson.Safe.to_string
      (`Assoc [("allow", `Bool allow); ("deny", `Bool deny);
               ("type", `String kind)]) in
  Http.call (Bot.token bot) ~body `PUT
    (Http.Endpoints.Channel.permissions channel_id overwrite_id)
  >>= Http.check_code 204 >|= ignore

let delete_permission bot ~channel_id ~overwrite_id =
  Http.call (Bot.token bot) `DELETE
    (Http.Endpoints.Channel.permissions channel_id overwrite_id)
  >>= Http.check_code 204 >|= ignore

let trigger_typing bot ~channel_id =
  Http.call (Bot.token bot) `POST
    (Http.Endpoints.Channel.typing channel_id)
  >>= Http.check_code 204 >|= ignore

let get_pinned_messages bot ~channel_id =
  Http.call (Bot.token bot) `GET
    (Http.Endpoints.Channel.pins channel_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.message_array_of_string

let add_pinned_message bot ~channel_id ~message_id =
  Http.call (Bot.token bot) `PUT
    (Http.Endpoints.Channel.pin channel_id message_id)
  >>= Http.check_code 204 >|= ignore

let delete_pinned_message bot ~channel_id ~message_id =
  Http.call (Bot.token bot) `DELETE
    (Http.Endpoints.Channel.pin channel_id message_id)
  >>= Http.check_code 204 >|= ignore
