(** Words, rewrite systems, and rewriting *)
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

exception Invalid_word
exception Invalid_rule
exception Invalid_interp
exception Invalid_command

(** [word_append current_word w2] appends [w2] to [current_word] according this rules :
      If [current_word] is a Symb,
        then creates a [Seq] with [current_word] followed by [w2].
      Else if [current_word] contains at least one 'opened' branch,
        then appends recursively [w2] to its last 'opened' branch
      Else,
        appends [w2] to the [current_word Seq list].

    A branch is 'opened' if '[' has been read and not ']'.
*)
val word_append : 's word -> 's word -> 's word

(** [create_char_word_from_str str]
    @return the [char word] corresponding to [str].
    @raise Invalid_word on errors. *)
val create_char_word_from_str : string -> char word

(** Creates a [char rewrite_rules] according to a given string list.
    @raise Invalid_word if a word is not valid
    @raise Invalid_rule if a rule is not valid.

    If a symbol have more than one rule, the last one is used.
*)
val create_char_rules_from_str_list : string list -> char -> char word

(** [create_command_from_str str]
    @return the corresponding Turtle.command from [str].
    @raise Invalid_command if [str.[0]] doesn't correspond to an command initial.
    @Invalid_argument('index out of bounds') if [str] len < 2.
    @Failure('int_of_string') if the value isn't a number.
*)
val create_command_from_str : string -> Turtle.command

(** [create_char_interp_from_str_list str_list]
    @return a char interpretation of the string list.
    @raise Invalid_word if a word is not valid
    @raise Invalid_interp if a rule is not valid.

    If a symbol have more than one interpretation, the last one is used.
*)
val create_char_interp_from_str_list : string list -> char -> Turtle.command list

(** Creates a [char system] according to a given string. *)
val create_system_from_file : string -> char system

(** Prints a [char word] with Seq represented by '|'. *)
val print_char_word : char word -> unit
