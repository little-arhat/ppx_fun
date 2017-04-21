open StdLabels
open Ppx_core.Light
open Asttypes
open Ast_builder.Default

[@@@metaloc loc]

type placeholder =
  Anonymous
| Numbered of int

type context = {
    used: int list;
    highest: placeholder option
  }

let parse_placeholder s =
  if s = "__"
  then Some Anonymous
  else (try
          Some (Scanf.sscanf s "_%d" (fun i -> Numbered i))
        with Scanf.Scan_failure _ -> None)

let set_add l el =
  if List.mem el ~set:l
  then l
  else (el::l)

let fold_downto ~init ~f start finish =
  let rec aux counter current =
    if counter < finish
    then current
    else aux (counter - 1) (f current counter)
  in
  if start < finish
  then raise (Invalid_argument "start cannot be less then finish!")
  else aux start init

let replace_and_count_placeholders prefix =
  object (_self)
    inherit [context] Ast_traverse.fold_map as super

    method! expression e acc =
      let (e', acc') = super#expression e acc in
      match e'.pexp_desc with
      | Pexp_ident {txt=Longident.Lident s; loc} ->
         let maybe_placeholder = parse_placeholder s in
         (match maybe_placeholder, acc' with
          | Some Anonymous, {highest=Some Anonymous; _} ->
             (evar ~loc prefix, acc')
          | Some Anonymous, {highest=None; _}->
             (evar ~loc prefix, {acc' with highest=Some Anonymous})
          | Some Anonymous, {highest=Some (Numbered _); _} ->
             Location.raise_errorf ~loc "ppx_fun: can't use anonymous and numbered placeholders in the same expression!"
          | Some (Numbered _), {highest=Some Anonymous; _} ->
             Location.raise_errorf ~loc "ppx_fun: can't use anonymous and numbered placeholders in the same expression!"
          | Some (Numbered current),
            {highest=Some (Numbered highest); used}->
             let name = prefix ^ (string_of_int current) in
             let e = evar ~loc name in
             let new_highest = if current > highest
                               then Numbered current
                               else Numbered highest in
             (e, {used = set_add used current;
                  highest = Some new_highest})
          | Some (Numbered current),
            {used; _} ->
             let name = prefix ^ (string_of_int current) in
             let e = evar ~loc name in
             (e, {used = set_add used current;
                  highest = Some (Numbered current)})
          | None, _ ->
             (e', acc'))
      | _ -> (e', acc')

  end

let replace_and_count_placeholders_in_expr prefix expr =
  let mapper = replace_and_count_placeholders prefix in
  let init = {used=[]; highest=None} in
  mapper#expression expr init

let ppx_fun_expander_args ~loc (expr:Parsetree.expression) =
  let line = loc.Location.loc_start.Lexing.pos_lnum in
  let prefix = Printf.sprintf "l_%d_v" line in
  let (inner, context) = replace_and_count_placeholders_in_expr
                           prefix expr in
  (* let inner = pexp_apply ~loc func new_args in *)
  match context.highest with
  | None ->
     (* without placeholders*)
     [%expr fun () -> [%e inner]]
  | Some Anonymous ->
     (* anonymous placeholders only -- 1-ary fun *)
     let pat = pvar ~loc prefix in
     [%expr fun [%p pat] -> [%e inner]]
  | Some (Numbered highest) ->
     fold_downto
       highest 1 ~init:inner
       ~f:(fun exp num ->
         let name = prefix ^ string_of_int num in
         let name' = if List.mem num ~set:context.used
                     then name
                     else "_" ^ name in
         let pat = pvar ~loc name' in
         [%expr fun [%p pat] -> [%e exp]])

let ppx_fun_expander_drop ~loc (expr:Parsetree.expression) =
  [%expr fun _ -> [%e expr]]

let parse_payload ~loc payload parse_expr = match payload with
  | PStr [{ pstr_desc =
              Pstr_eval ({ pexp_loc = loc; _} as expr, _); _ }] ->
     parse_expr ~loc expr
  | _ -> Location.raise_errorf ~loc "ppx_fun: expecting expression inside"

let ppx_fun_expander =
  object (_self)
    inherit Ast_traverse.map as super

    method! expression e =
      let e' = super#expression e in
      match e'.pexp_desc with
      | Pexp_extension ({ txt = "f"; loc }, pstr) ->
         parse_payload ~loc pstr ppx_fun_expander_args
      | Pexp_extension ({ txt = "f_"; loc }, pstr) ->
         parse_payload ~loc pstr ppx_fun_expander_drop
      | _ -> e'
  end


(* XXX: Ast_traverse.ast_mapper_of_map was for some reason removed from
   ppx_core, so here is hackish attempt to replace it, see
   https://github.com/janestreet/ppx_core/issues/10 *)
let ast_mapper_of_map (map : #map) : Ast_mapper.mapper =
  let open Ast_mapper in
  { default_mapper with
    expr = fun _ -> Ppx_ast.Selected_ast.to_ocaml_mapper
                      Ppx_ast.Selected_ast.Type.Expression map#expression}

let () =
  let mapper = ast_mapper_of_map ppx_fun_expander in
  Ast_mapper.register "fun" (fun _argv -> mapper)
