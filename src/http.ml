open Lwt
open Cohttp
open Cohttp_lwt_unix

exception HTTP_Bad_Return of string

let o rl s = if rl then "" else s

module Endpoints = struct
  module Gateway = struct let gateway_bot _ = "gateway/bot" end
  module Channel = struct
    let channel id _ = "channels/" ^ id
    let messages id rl = (channel id rl) ^ "/messages"
    let message cid mid rl = (messages cid rl) ^ "/" ^ o rl mid
    let reactions cid mid rl = (message cid mid rl) ^ "/reaction"
    let reaction cid mid emoji rl = (reactions cid mid rl) ^ "/" ^ o rl emoji
    let user_reaction cid mid emoji uid rl = (reaction cid mid emoji rl) ^ "/" ^ o rl uid
    let message_bulk_delete id rl = (messages id rl) ^ "/bulk-delete"
    let permissions cid oid rl = (channel cid rl) ^ "/permissions/" ^ o rl oid
    let invites id rl = (channel id rl) ^ "/invites"
    let typing id rl = (channel id rl) ^ "/typing"
    let pins id rl = (channel id rl) ^ "/pins"
    let pin cid mid rl = (pins cid rl) ^ "/" ^ o rl mid
    let recipients cid uid rl = (channel cid rl) ^ "/recipients/" ^ o rl uid
  end
  module Guild = struct
    let all _ = "guilds"
    let guild id rl = (all rl) ^ "/" ^ id
    let channels id rl = (guild id rl) ^ "/channels"
    let members id rl = (guild id rl) ^ "/members"
    let member gid mid rl = (members gid rl) ^ "/" ^ o rl mid
    let nick gid mid rl = (member gid mid rl) ^ "/nick"
    let user_role gid mid rid rl = (member gid mid rl) ^ "/roles/" ^ o rl rid
    let bans id rl = (guild id rl) ^ "/bans"
    let ban gid uid rl = (bans gid rl) ^ "/" ^ o rl uid
    let roles id rl = (guild id rl) ^ "/roles"
    let role gid rid rl = (roles gid rl) ^ "/" ^ o rl rid
    let prune id rl = (guild id rl) ^ "/prune"
    let regions id rl = (guild id rl) ^ "/regions"
    let invites id rl = (guild id rl) ^ "/invites"
    let integrations id rl = (guild id rl) ^ "/integrations"
    let integration gid iid rl = (integrations gid rl) ^ "/" ^ o rl iid
    let embed id rl = (guild id rl) ^ "/embed"
    let vanity_url id rl = (guild id rl) ^ "/vanity-url"
    let widget id rl = (guild id rl) ^ "/widget.png"
  end
  module User = struct
    let user id rl = "users/" ^ o rl id
    let guilds id rl = (user id rl) ^ "/guilds"
    let guild uid gid rl = (guilds uid rl) ^ "/" ^ o rl gid
    let channels id rl = (user id rl) ^ "/channels"
    let connections id rl = (user id rl) ^ "/connections"
  end
  module Invite = struct let invite id = "invites/" ^ id end
  (* TODO Emoji / Voice / Webhook *)
end

let base_uri = Uri.of_string "https://discordapp.com/api/"

let get_url endpoint = Uri.resolve "" base_uri (Uri.of_string endpoint)

module Rate_Limiter = struct
  type rate_limit = {
    rl_limit : int;
    rl_remaining : int;
    rl_reset : int;
  }

  let routes = Hashtbl.create 200
  let locks = Hashtbl.create 200
  let itime () = int_of_float (Unix.time ())

  let reset ({rl_limit; _} as rl) =
    {rl with rl_reset = itime () + 100; rl_remaining = rl_limit}

  let wait route =
    let lock = match Hashtbl.find_opt locks route with
      | None ->
        let m = Lwt_mutex.create () in
        Hashtbl.add locks route m; m
      | Some l -> l
    in
    let%lwt () = Lwt_mutex.lock lock in
    match Hashtbl.find_opt routes route with
    | None -> Lwt.return_unit
    | Some ({rl_remaining; _} as rl) when rl_remaining > 0 ->
      Hashtbl.replace routes route {rl with rl_remaining = rl_remaining - 1};
      Lwt.return_unit
    | Some ({rl_reset; _} as rl) ->
      let%lwt () =
        if rl_reset > itime () then (
          let diff = rl_reset - (itime ()) in
          Lwt_unix.sleep (float_of_int diff)
        ) else Lwt.return_unit
      in
      Hashtbl.replace routes route (reset rl);
      Lwt.return_unit

  let update route ((resp, _) as a) =
    let headers = Response.headers resp in
    let get s = Header.get headers s |> Option.get |> int_of_string in
    let rl_limit = get "X-RateLimit-Limit" in
    let rl_remaining = get "X-RateLimit-Remaining" in
    let rl_reset = get "X-RateLimit-Reset" in
    Hashtbl.replace routes route {rl_limit; rl_remaining; rl_reset};
    let lock = Hashtbl.find locks route in
    Lwt_mutex.unlock lock; a
end

let call token ?(body="") ?(headers=Header.init ()) meth endpoint =
  let route = endpoint true in
  let%lwt () = Rate_Limiter.wait route in
  let url = get_url (endpoint false) in
  let headers = Header.add headers "Authorization" ("Bot " ^ token) in
  let headers = Header.add headers "Content-Type" ("application/json") in
  let body = Cohttp_lwt.Body.of_string body in
  Client.call ~body ~headers meth url >|=
  Rate_Limiter.update route

let check_code code (resp, body) =
  let act = Code.code_of_status (Response.status resp) in
  if act = code then Lwt.return body
  else 
    let%lwt err = Cohttp_lwt.Body.to_string body in
    Lwt.fail (HTTP_Bad_Return err)

let to_string = Cohttp_lwt.Body.to_string
let to_json body = to_string body >|= Yojson.Safe.from_string
