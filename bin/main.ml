[@@@ocaml.warning "-33"]
open Ppx_fun

let () =
  Ppx_driver.register_transformation
    "ppx-fun"
  (* XXX: can't use ~rules, because there is no fresh ppx_driver for 4.03 *)
    ~extensions:Ppx_fun.extensions;
  Ppx_driver.standalone ()
