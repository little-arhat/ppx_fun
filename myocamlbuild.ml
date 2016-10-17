open Ocamlbuild_plugin

let () = dispatch (
  function
  | After_rules ->
     flag ["ocaml"; "compile"; "use_ppx_fun"] &
       S[A"-ppx"; A("./src/ppx_fun.native")];
     (* Pass -predicates to ocamldep *)
     pflag ["ocaml"; "ocamldep"] "predicate" (fun s -> S [A "-predicates"; A s])

  | _ -> ())
