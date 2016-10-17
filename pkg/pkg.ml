#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let () =
  let build = Pkg.build () in
  Pkg.describe "ppx_fun" ~build
  @@ fun _c ->
     Ok [Pkg.lib "pkg/META";
         Pkg.libexec "src/ppx_fun";
         Pkg.test "test/test";
     ]
