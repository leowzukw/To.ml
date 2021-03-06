open OUnit
open Toml
open Toml.Parser

module Toml_key = Toml.Table.Key

let error1 ="string = \"Anything other than tabs, spaces and newline after a keygroup or key value pair has ended should produce an error unless it is a comment\"   like this"

let error2 ="array = [
         \"This might most likely happen in multiline arrays\",
         Like here,
         \"or here,
         and here\"
         ]     End of array comment, forgot the #"

let error3 ="number = 3.14  pi <--again forgot the #"

let toml = Parser.from_filename "./hard_example.toml"

let mk_table x =
  Toml.Value.Of.table (List.fold_left (fun tbl (k,v) -> Table.add (Toml_key.of_string k) v tbl) Table.empty x)

let assert_equal =
  OUnit.assert_equal ~cmp:(fun x y -> Compare.table x y == 0)

let expected =
  List.fold_left (fun tbl (k,v) -> Table.add k v tbl) Table.empty
    [
      Toml_key.of_string "the", mk_table
        [ "test_string", Toml.Value.Of.string "You'll hate me after this - #" ;

          "hard", mk_table
            [ "test_array", Toml.Value.Of.array (Toml.Value.Of.Array.string ["] "; " # " ]) ;
              "test_array2", Toml.Value.Of.array (Toml.Value.Of.Array.string
                                       ["Test #11 ]proved that" ;
                                        "Experiment #9 was a success"]) ;
              "another_test_string",
              Toml.Value.Of.string " Same thing, but with a string #" ;
              "harder_test_string",
              Toml.Value.Of.string " And when \"'s are in the string, along with # \"" ;
              "bit", mk_table
                ["what?", Toml.Value.Of.string "You don't think some user won't do that?";
                 "multi_line_array", Toml.Value.Of.array
                 (Toml.Value.Of.Array.string ["]"])]
            ]
        ]
    ]

let suite = "Official hard_example.toml file" >:::
  [

    "Success" >:: (fun () -> assert_equal expected toml) ;

    "Error" >:: (fun () ->
      assert_raises
        (Toml.Parser.Error (
          "Error in <string> at line 1 at column 159 (position 159)",
          { source = "<string>"; line = 1; column = 159; position = 159; }))
        (fun () -> ignore(Parser.from_string error1));
      assert_raises
        (Toml.Parser.Error (
          "Error in <string> at line 3 at column 13 (position 85)",
          { source = "<string>"; line = 3; column = 13; position = 85; }))
        (fun () -> ignore(Parser.from_string error2));
      assert_raises
        (Toml.Parser.Error (
          "Error in <string> at line 1 at column 26 (position 26)",
          { source = "<string>"; line = 1; column = 26; position = 26; }))
        (fun () -> ignore(Parser.from_string error3)))
  ]

