module Opt = Option
open Lwt
open Types_j
open Yojson.Safe.Util
open Websocket
open Websocket_lwt

type t = {
  user : user option;
  session_id : string;
  token : string;
  todo : unit Lwt.t list;
  recv : unit -> Websocket.Frame.t Lwt.t;
  send : Websocket.Frame.t -> unit Lwt.t;
  mutable heartbeat_ok : bool;
  mutable seq : int;
  wake : int Lwt.t * int Lwt.u;
  stop : unit Lwt.t * unit Lwt.u;
}

type event = event_kind

exception Bad_Frame
exception Bad_opcode
exception Resumable_stop
exception Fatal_stop

let get_uri token =
  let%lwt answer =
    Http.call token `GET Http.Endpoints.Gateway.gateway_bot
    >>= Http.check_code 200
    >>= Http.to_json in
  let wss = answer |> member "url" |> to_string |> Uri.of_string in
  Lwt.return (Uri.with_scheme wss (Some "https"))

let get_interface uri =
  let open Conduit_lwt_unix in
  let%lwt endpoint = Resolver_lwt.resolve_uri ~uri
      Resolver_lwt_unix.system in
  let %lwt client = endp_to_client ~ctx:default_ctx endpoint in
  with_connection client uri

let make_frame payload =
  let content = string_of_payload payload in
  Frame.create ~opcode:Frame.Opcode.Text ~content ()

let make_identify bot = {
  token = bot.token;
  properties = {
    os = "linux";
    browser = "discocaml";
    device = "discocaml"
  }
}

let heartbeat_forever bot =
  let%lwt iinter = fst bot.wake in
  let finter = (float_of_int iinter) /. 1000. in
  let rec aux () =
    let payload = Heartbeat bot.seq in
    let frame = make_frame payload in
    let%lwt () = bot.send frame in
    let%lwt () = Lwt_unix.sleep finter in
    aux ()
  in aux ()

let user_exception ex =
  Lwt_io.fprintf Lwt_io.stderr "Exception in user handler : %s\n%!"
    (Printexc.to_string ex)

let react_event bot handler = function
  | READY ready -> 
    Lwt.return {bot with user=Some ready.user; session_id=ready.session_id}
  | e ->
    let task = (try%lwt handler bot e with ex -> user_exception ex) in
    Lwt.async (fun () -> task);
    Lwt.return {bot with todo = task :: bot.todo}

let react_payload bot handler = function
  | Hello {heartbeat_interval} ->
    let ident_frame = Identify (make_identify bot) |> make_frame in
    let%lwt () = bot.send ident_frame in
    Lwt.wakeup (snd bot.wake) heartbeat_interval;
    Lwt.return bot 
  | Event {e; s} -> bot.seq <- s; react_event bot handler e
  | Invalid_session {resumable} ->
    Lwt.fail (if resumable then Resumable_stop else Fatal_stop)
  | Heartbeat_ACK _ -> bot.heartbeat_ok <- true; Lwt.return bot
  | Identify _ | Heartbeat _ -> Lwt.fail Bad_opcode

let react bot handler frame =
  let open Frame in match frame.opcode with
  | Opcode.Close ->
    let%lwt () = bot.send (Frame.close 1000) in
    Lwt.fail Fatal_stop
  | Opcode.Text ->
    frame.content |> payload_of_string |> react_payload bot handler
  | _ -> Lwt.fail Bad_Frame

let prune_todo = List.filter Lwt.is_sleeping

let rec react_forever bot handler =
  let%lwt frame = bot.recv () in
  let%lwt nbot = react bot handler frame in
  react_forever {nbot with todo = prune_todo nbot.todo} handler

let create token =
  let%lwt uri = get_uri token in
  let%lwt recv, send = get_interface uri in
  Lwt.return {
    token; recv; send; user = None; todo = [];
    session_id = ""; heartbeat_ok = false;
    wake = Lwt.wait (); seq = 0; stop = Lwt.wait ()
  }

let close_connection bot =
  bot.send (Websocket.Frame.close 1000)

let launch handler bot =
  (react_forever bot handler <?> heartbeat_forever bot <?> fst bot.stop)
    [%lwt.finally close_connection bot]

let stop bot =
  let%lwt () = Lwt.join bot.todo in
  Lwt.wakeup (snd bot.stop) ();
  Lwt.return_unit

let user b = Opt.get b.user
let token b = b.token

(* https://discordapp.com/oauth2/authorize?&client_id=520343422591172613&scope=bot&permissions=0 *)
