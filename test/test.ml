
let () =
  (* anonymous placeholder *)
  let f1 = fun a -> a * 2 in
  let fg1 = [%f __ * 2] in
  assert  (f1 3 = fg1 3)

let () =
  (* N anonymous placeholders *)
  let f1 = fun a -> a * a in
  let fg1 = [%f __ * __] in
  assert (f1 3 = fg1 3)

let () =
  (* numbered placeholders *)
  let f1 = fun a b -> a * b in
  let fg1 = [%f _1 * _2] in
  assert (f1 2 4 = fg1 2 4)

let () =
  (* numbered placeholders, skip *)
  let f1 = fun a _b c -> a * c in
  let fg1 = [%f _1 * _3] in
  assert (f1 2 9 4 = fg1 2 0 4)

let () =
  (* drop args *)
  let f1 = fun _ -> 42 in
  let fg1 = [%f_ 42] in
  assert (f1 1 = fg1 2)

let () =
  print_endline "Tests passed"
