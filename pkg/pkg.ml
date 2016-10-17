#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  let build = Pkg.build () in
  Pkg.describe "ppx_fun" ~build
  @@ fun c ->
     Ok [Pkg.lib "pkg/META";
         Pkg.lib ~exts:Exts.library "src/ppx_fun";
         Pkg.libexec "bin/ppx_fun_bin" ~dst:"ppx_fun";
         Pkg.test "test/test";
     ]
