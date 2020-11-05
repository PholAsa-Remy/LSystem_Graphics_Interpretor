type 's word =
  | Symb of 's
  | Seq of 's word list
  | Branch of 's word

type 's rewrite_rules = 's -> 's word

type 's system =
  { axiom : 's word
  ; rules : 's rewrite_rules
  ; interp : 's -> Turtle.command list
  }

(** Parser (not pur functionnal) *)

let read_line ci : string option =
  try
    let x = input_line ci in
    Some x
  with
  | End_of_file -> None
;;

type parse_state =
  | Axiom
  | Rules
  | Interp
  | Done

let rec print_char_word = function
  | Symb s -> print_char s
  | Seq l ->
    print_string "|";
    List.iter (fun w -> print_char_word w) l;
    print_string "|"
  | Branch b ->
    print_string "[";
    print_char_word b;
    print_string "]"
;;

let update_parse_state = function
  | Axiom -> Rules
  | Rules -> Interp
  | Interp | Done -> Done
;;

exception NotValidWord

let empty_word = Seq []
let current_word_depth = ref 0

let word_append (w1 : 's word) (w2 : 's word) =
  let rec word_append_accordin_depth w1 w2 depth =
    match w1 with
    (* The current word contains only one [Symb] *)
    | Symb s -> Seq [ Symb s; w2 ]
    (* The current word contains a sequence of sub [word] *)
    | Seq l ->
      if !current_word_depth <> depth
      then (
        (* The current sequence contains a [Branch] but it *)
        let nb_branches = ref 0 in
        List.iter
          (fun w ->
            match w with
            | Branch _ -> nb_branches := !nb_branches + 1
            | _ -> ())
          l;
        let curr_branch = ref 0 in
        Seq
          (List.map
             (function
               | Symb s -> Symb s
               | Seq l -> Seq l
               | Branch b ->
                 curr_branch := !curr_branch + 1;
                 if !curr_branch = !nb_branches
                 then Branch (word_append_accordin_depth b w2 (depth + 1))
                 else Branch b)
             l))
      else Seq (List.append l [ w2 ])
    | Branch b -> Branch b
  in
  if empty_word <> w2 then word_append_accordin_depth w1 w2 0 else w1
;;

let create_char_word_from_str str =
  (* If [str] contains only one char *)
  if 1 = String.length str
  then Symb str.[0]
  else (
    current_word_depth := 0;
    let word = ref empty_word in
    String.iter
      (fun c ->
        word
          := word_append
               !word
               (match c with
               (* Enterring in a new branch. *)
               | '[' -> Branch empty_word
               (* Exiting of the current branch. *)
               | ']' -> if 0 = !current_word_depth then raise NotValidWord else empty_word
               (* Simple char symbol. *)
               | c -> Symb c);
        match c with
        | '[' -> current_word_depth := !current_word_depth + 1
        | ']' -> current_word_depth := !current_word_depth - 1
        | _ -> ())
      str;
    !word)
;;

let create_char_rules_from_str _ = function
  | 'B' -> Seq [ Symb 'B'; Symb 'B' ]
  | s -> Symb s
;;

(* let get_rules_from_line line = *)
(*   let splited_line = String.split_on_char ' ' line in *)
(*   if 2 <> List.length splited_line *)
(*   then raise NotValidRules *)
(*   else *)
(*     (function -> *)
(*   | List.hd splited_line -> create_char_word_from_str (List.nth 1 splited_line)) *)
(* ;; *)

let create_system_from_file (file_name : string) =
  let axiom_word = ref (Seq []) in
  (* let rules = ref (fun _ -> Seq []) in *)
  let current_parse_state = ref Axiom in
  let ci = open_in file_name in
  let line = ref (read_line ci) in
  while None <> !line && Done <> !current_parse_state do
    match !line with
    | None -> ()
    | Some l ->
      let curr_line = String.trim l in
      (* If it's an empty line, changes the current parse state. *)
      if 0 = String.length curr_line
      then
        current_parse_state := update_parse_state !current_parse_state
        (* If it's a commented line *)
      else if '#' <> curr_line.[0]
      then (
        match !current_parse_state with
        | Axiom ->
          print_string "\nAxiom = ";
          axiom_word := create_char_word_from_str curr_line
        | Rules -> print_string "\nRules = "
        (* if 3 <= String.length curr_line *)
        (* then rules := get_rules_from_line curr_line *)
        (* else raise NotValidRules *)
        | Interp ->
          print_string "\nInterp = ";
          print_string curr_line
        | Done -> print_string "\nDone.");
      line := read_line ci
  done;
  print_string "Finish.\n";
  close_in ci;
  { axiom = !axiom_word; rules = (fun s -> Symb s); interp = (fun _ -> [ Line 5 ]) }
;;
