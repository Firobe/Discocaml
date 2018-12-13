open Lwt
open Cohttp
open Cohttp_lwt_unix

exception HTTP_Bad_Return of string

module Endpoints = struct
  module Gateway = struct let gateway_bot = "gateway/bot" end
  module Channel = struct
    let channel id = "channels/" ^ id
    let messages id = (channel id) ^ "/messages"
    let message cid mid = (messages cid) ^ "/" ^ mid
    let reactions cid mid = (message cid mid) ^ "/reaction"
    let reaction cid mid emoji = (reactions cid mid) ^ "/" ^ emoji
    let user_reaction cid mid emoji uid = (reaction cid mid emoji) ^ "/" ^ uid
    let message_bulk_delete id = (messages id) ^ "/bulk-delete"
    let permissions cid oid = (channel cid) ^ "/permissions/" ^ oid
    let invites id = (channel id) ^ "/invites"
    let typing id = (channel id) ^ "/typing"
    let pins id = (channel id) ^ "/pins"
    let pin cid mid = (pins cid) ^ "/" ^ mid
    let recipients cid uid = (channel cid) ^ "/recipients/" ^ uid
  end
  module Guild = struct
    let all = "guilds"
    let guild id = all ^ "/" ^ id
    let channels id = (guild id) ^ "/channels"
    let members id = (guild id) ^ "/members"
    let member gid mid = (members gid) ^ "/" ^ mid
    let nick gid mid = (member gid mid) ^ "/nick"
    let user_role gid mid rid = (member gid mid) ^ "/roles/" ^ rid
    let bans id = (guild id) ^ "/bans"
    let ban gid uid = (bans gid) ^ "/" ^ uid
    let roles id = (guild id) ^ "/roles"
    let role gid rid = (roles gid) ^ "/" ^ rid
    let prune id = (guild id) ^ "/prune"
    let regions id = (guild id) ^ "/regions"
    let invites id = (guild id) ^ "/invites"
    let integrations id = (guild id) ^ "/integrations"
    let integration gid iid = (integrations gid) ^ "/" ^ iid
    let embed id = (guild id) ^ "/embed"
    let vanity_url id = (guild id) ^ "/vanity-url"
    let widget id = (guild id) ^ "/widget.png"
  end
  module User = struct
    let user id = "users/" ^ id
    let guilds id = (user id) ^ "/guilds"
    let guild uid gid = (guilds uid) ^ "/" ^ gid
    let channels id = (user id) ^ "/channels"
    let connections id = (user id) ^ "/connections"
  end
  module Invite = struct let invite id = "invites/" ^ id end
  (* TODO Emoji / Voice / Webhook *)
end

let base_uri = Uri.of_string "https://discordapp.com/api/"

let get_url endpoint = Uri.resolve "" base_uri (Uri.of_string endpoint)

let call token ?(body="") ?(headers=Header.init ()) meth endpoint =
  let url = get_url endpoint in
  let headers = Header.add headers "Authorization" ("Bot " ^ token) in
  let headers = Header.add headers "Content-Type" ("application/json") in
  let body = Cohttp_lwt.Body.of_string body in
  Client.call ~body ~headers meth url

let check_code code (resp, body) =
  let act = Code.code_of_status (Response.status resp) in
  if act = code then Lwt.return body
  else 
    let%lwt err = Cohttp_lwt.Body.to_string body in
    Lwt.fail (HTTP_Bad_Return err)

let to_string = Cohttp_lwt.Body.to_string
let to_json body = to_string body >|= Yojson.Safe.from_string

let auth_header token =
  Header.of_list [("Authorization", "Bot " ^ token)]

