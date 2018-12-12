open Lwt
open Types_t

type t = message
type query_type = Around | Before | After

let query bot ~channel_id ~query ~message_id ~limit = 
  let str = match query with
      Around -> "around" | Before -> "before" | After -> "after" in
  let json = `Assoc [(str, `String message_id); ("limit", `Int limit)] in
  let body = Yojson.Safe.to_string json in
  Http.call (Bot.token bot) ~body `GET
    (Http.Endpoints.Channel.message channel_id channel_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.message_array_of_string

let get bot ~channel_id ~message_id =
  Http.call (Bot.token bot) `GET
    (Http.Endpoints.Channel.message channel_id message_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.message_of_string

let send bot ~channel_id cm =
  let body = Types_j.string_of_create_message cm in
  Http.call (Bot.token bot) ~body `POST (Http.Endpoints.Channel.messages channel_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.message_of_string

let edit bot ~channel_id ~message_id ?content ?embed () =
  let body = Types_j.string_of_edit_message {content; embed} in
  Http.call (Bot.token bot) ~body `PATCH
    (Http.Endpoints.Channel.message channel_id message_id)
  >>= Http.check_code 200 >>= Http.to_string >|= Types_j.message_of_string

let delete bot ~channel_id ~message_id =
  Http.call (Bot.token bot) `DELETE (Http.Endpoints.Channel.message channel_id message_id)
  >>= Http.check_code 204 >|= ignore

let bulk_delete bot ~channel_id messages =
  let arr = List.map (fun s -> `String s) messages in
  let body = Yojson.Safe.to_string (`Assoc [("messages", `List arr)]) in
  Http.call (Bot.token bot) ~body `POST
    (Http.Endpoints.Channel.message_bulk_delete channel_id)
  >>= Http.check_code 204 >|= ignore

let create = Types_v.create_create_message

let mentions (mess : t) (user : Types_t.user) =
  List.exists (fun (mu : Types_t.user) -> mu.id = user.id) mess.mentions
