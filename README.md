ppx_fun — shorthand syntax for anonymous functions
-------------------------------------------------------------------------------

ppx_fun is PPX rewriter that provides simplified syntax for anonymous functions via extensions:
`[%f ...]` and `[%f_ ...]`.

## Examples

```ocaml

(* anonymous placeholder: *)
List.iter lst ~f:[%f Printf.printf "element: %d" __]
(* function translated to: (fun v -> Printf.printf "element: %d" v) *)

(* positional placeholders: *)
List.map lst ~f:[%f _1 * _2]
(* translated to: (fun v1 v2 -> v1 * v2) *)

(* unused positional placeholders: *)
some_func |> [%f _1 ^ _3]
(* translated to: (fun v1 _v2 v3 -> v1 ^ v3) *)

(* 0-ary function: *)
async_func >>= [%f other_async_func var ]
(* translsated to: (fun () -> other_async_func var) *)

(* drop argument: *)
return_smth >>= [%f_ ignore_and_continue ()]
(* translated to*)
```

Note: function parameters are named with line info to avoid name-clashing.

## Installation

ppx_fun can be installed with `opam`:

    opam install ppx_fun

## Usage

Add `ppx_fun` as dependency to your `opam` file, and this to your `_tags`:

```
<src/*.ml>: package(ppx_fun)
```

## Differences with ppx_lambda

[ppx_lambda](https://github.com/rizo/ppx_lambda) is another ppx rewriter with aim to provide lightweight
syntax for anonymous functions. With contrast to `ppx_lambda`, this packages is:

* Maintained %)
* Available via [opam](http://opam.ocaml.org/packages/ppx_fun/)
* Uses extension syntax, so no strange conflicts/errors


## Build instruction

    make

to build rewriter and run tests.
