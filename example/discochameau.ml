open Discocaml
open Discocaml.Types_t
open Lwt
open ExtString

exception User_interrupt

let history = ref []

let send_simple bot channel_id content =
  let message = Message.create ~content () in
  let%lwt result = Message.send bot ~channel_id message in
  Lwt.return (history := result.id :: !history)

let handler bot = function
  | MESSAGE_CREATE mess ->
    let botu = Bot.user bot in
    let channel_id = mess.channel_id in
    let words = String.nsplit mess.content " " in
    if mess.author.id <> botu.id then (match words with
        | "!ping" :: _ -> send_simple bot channel_id "pong"
        | "!exit" :: _ ->
          let%lwt () = send_simple bot channel_id "Bye :(" in
          Bot.stop bot
        | "!wait" :: time :: _ ->
          let ftime = float_of_string time in
          let%lwt () = Lwt_unix.sleep ftime in
          send_simple bot channel_id "Wait is over !"
        | "!bad" :: _ -> raise User_interrupt
        | "!del" :: _ ->
          let message_id = List.hd !history in
          Message.delete bot ~channel_id ~message_id
        | "!bulk" :: _ ->
          Message.bulk_delete bot ~channel_id !history
        | "!edit" :: content :: _ ->
          let message_id = List.hd !history in
          Message.edit bot ~channel_id ~message_id ~content ()
          >|= ignore
        | "!cn" :: n :: _ ->
          let%lwt ch = Channel.get bot ~channel_id in
          Printf.printf "Got\n%!";
          let channel_name = Some n in
          let channel = {ch with channel_name} in
          Channel.modify bot ~channel >|= ignore
        | _ ->
          if Message.mentions mess botu then
            send_simple bot channel_id "C'est moi le Disco Chameau ;)"
          else Lwt.return_unit
      )
    else Lwt.return_unit
  | _ -> Lwt.return_unit

let main =
  let token = open_in "token" |> input_line in
  Bot.create token >>= Bot.launch handler |> Lwt_main.run
