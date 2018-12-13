module type Wmap = sig
    type t
    val assoc : (int * t) list
end
module Wrapper (M : Wmap) = struct
    type t = M.t
    let wrap a = List.assoc a M.assoc
    let unwrap v = fst (List.find (fun (_, vt) -> vt = v) M.assoc)
end

module Message_activity_type = struct
    type t = Join | Spectate | Listen | Join_Request
    let assoc = [(1, Join); (2, Spectate); (3, Listen); (5, Join_Request)]
end
module Message_activity_type_wrapper = Wrapper (Message_activity_type)

module Message_type = struct
    type t = Default | Recipient_Add | Recipient_Remove | Call
             | Channel_Name_Change | Channel_Icon_Change 
             | Channel_Pinned_Message | Guild_Member_Join
    let assoc = [(0, Default); (1, Recipient_Add); (2, Recipient_Remove);
                 (3, Call); (4, Channel_Name_Change); (5, Channel_Icon_Change);
                 (6, Channel_Pinned_Message); (7, Guild_Member_Join)]
end
module Message_type_wrapper = Wrapper (Message_type)

module Channel_type = struct
    type t = Guild_Text | DM | Guild_Voice | Group_DM | Guild_Category
    let assoc = [(0, Guild_Text); (1, DM); (2, Guild_Voice);
                 (3, Group_DM); (4, Guild_Category)]
end
module Channel_type_wrapper = Wrapper (Channel_type)

module Payload_opcode = struct
    type t = string
    let assoc = [(0, "Event"); (10, "Hello");
                 (9, "Invalid_session"); (2, "Identify");
                 (11, "Heartbeat_ACK"); (1, "Heartbeat")]
end
module Payload_opcode_wrapper = Wrapper (Payload_opcode)

open Yojson.Safe.Util
module Payload_adapter = struct
    let normalize = function
        | `Assoc l as dp ->
            let opcode = dp |> member "op" |> to_int in
            let name = Payload_opcode_wrapper.wrap opcode in
            let data = dp |> member "d" in
            let without = `Assoc (List.filter (fun (n, _) ->
                n <> "op" && n <> "d") l) in
            let full = begin match data with
                | `Assoc _ -> combine data without
                | _ -> without
            end in
            `List [`String name; full]
        | _ -> assert false
                
    let restore = function
        | `List [`String kind; rest] ->
            let opcode = Payload_opcode_wrapper.unwrap kind in
            `Assoc [
                ("op", `Int opcode);
                ("d", rest)
            ]
        | _ -> assert false
end

module Event_adapter = struct 
    module W = Atdgen_runtime.Json_adapter.Type_field.Make
        (struct let type_field_name = "t" end)
    let normalize : Yojson.Safe.json -> Yojson.Safe.json = function
        | `Assoc l as e ->
            let without = `Assoc (List.filter (fun (n, _) -> n <> "s") l) in
            let s = e |> member "s" in
            `Assoc [ ("s", s); ("e", W.normalize without)]
        | _ -> assert false
    let restore = W.restore
end
