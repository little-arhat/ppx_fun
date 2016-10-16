open Ocamlbuild_plugin

let () = dispatch (
  function
  | After_rules ->
     flag ["ocaml"; "compile"; "use_ppx_fun"] &
       S[A"-ppx"; A("./bin/main.native -as-ppx")];
     (* Pass -predicates to ocamldep *)
     pflag ["ocaml"; "ocamldep"] "predicate" (fun s -> S [A "-predicates"; A s])

  | _ -> ())
