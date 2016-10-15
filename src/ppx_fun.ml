open StdLabels
open Ppx_core.Std
open Parsetree
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

let replace_and_count_placeholders_in_args prefix args =
  let mapper = replace_and_count_placeholders prefix in
  let init = ({used=[]; highest=None}, []) in
  let (context, new_args) =
    List.fold_left
      args ~init
      ~f:(fun (context, collected_args) (al, expr) ->
        let (new_expr, new_context) = mapper#expression expr context in
        let new_args = (al, new_expr)::collected_args in
        (new_context, new_args))
  in
  (context, List.rev new_args)

let ppx_fun_expander
      ~loc ~path:_
      (func:Parsetree.expression)
      (args:(Asttypes.arg_label * Parsetree.expression) list) =
  let prefix = "v" in
  let (context, new_args) = replace_and_count_placeholders_in_args
                              prefix args in
  let inner = pexp_apply ~loc func new_args in
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


let ppx_fun =
  Extension.V2.declare "f"
                       Extension.Context.expression
                       Ast_pattern.(pstr (pstr_eval
                                            (pexp_apply __ __) nil ^:: nil))
                       ppx_fun_expander

let extensions = [ppx_fun]
