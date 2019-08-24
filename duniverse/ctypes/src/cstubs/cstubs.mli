(*
 * Copyright (c) 2014 Jeremy Yallop.
 *
 * This file is distributed under the terms of the MIT License.
 * See the file LICENSE for details.
 *)

(** Operations for generating C bindings stubs. *)

module Types :
sig
  module type TYPE = Ctypes.TYPE

  module type BINDINGS = functor (F : TYPE) -> sig end

  val write_c : Format.formatter -> (module BINDINGS) -> unit
end


module type FOREIGN = Ctypes.FOREIGN

module type BINDINGS = functor (F : FOREIGN with type 'a result = unit) -> sig end

type errno_policy
(** Values of the [errno_policy] type specify the errno support provided by
    the generated code.  See {!ignore_errno} for the available option.
*)

val ignore_errno : errno_policy
(** Generate code with no special support for errno.  This is the default. *)

val return_errno : errno_policy
(** Generate code that returns errno in addition to the return value of each function.

    Passing [return_errno] as the [errno] argument to {!Cstubs.write_c} and
    {!Cstubs.write_ml} changes the return type of bound functions from a
    single value to a pair of values.  For example, the binding
    specification 

       [let realpath = foreign "reaplath" (string @-> string @-> returning string)]

    generates a value of the following type by default:

       [val realpath : string -> string -> stirng]

    but when using [return_errno] the generated type is as follows:

       [val realpath : string -> string -> stirng * int]

    and when using both [return_errno] and [lwt_jobs] the generated type is as
    follows:

       [val realpath : string -> string -> (stirng * int) Lwt.t]
*)

type concurrency_policy
(** Values of the [concurrency_policy] type specify the concurrency support
    provided by the generated code.  See {!sequential} and {!lwt_jobs} for the
    available options.
*)

val sequential : concurrency_policy
(** Generate code with no special support for concurrency.  This is the
    default.
*)

val unlocked : concurrency_policy
(** Generate code that releases the runtime lock during C calls.
*)

val lwt_preemptive : concurrency_policy
(** Generate code which runs C function calls with the Lwt_preemptive module:

    http://ocsigen.org/lwt/2.5.1/api/Lwt_preemptive

    Passing [lwt_preemptive] as the [concurrency] argument to {!Cstubs.write_c} and
    {!Cstubs.write_ml} changes the return type of bound functions to include
    the {!Lwt.t} constructor.  For example, the binding specification

       [let unlink = foreign "unlink" (string @-> returning int)]

    generates a value of the following type by default:

       [val unlink : string -> int]

    but when using [lwt_preemptive] the generated type is as follows:

       [val unlink : string -> int Lwt.t]

    Additionally, the OCaml runtime lock is released during calls to functions
    bound with [lwt_preemptive].
*)

val lwt_jobs : concurrency_policy
(** Generate code which implements C function calls as Lwt jobs:

    http://ocsigen.org/lwt/2.5.1/api/Lwt_unix#TYPEjob

    Passing [lwt_jobs] as the [concurrency] argument to {!Cstubs.write_c} and
    {!Cstubs.write_ml} changes the return type of bound functions to include
    the {!Lwt.t} constructor.  For example, the binding specification

       [let unlink = foreign "unlink" (string @-> returning int)]

    generates a value of the following type by default:

       [val unlink : string -> int]

    but when using [lwt_jobs] the generated type is as follows:

       [val unlink : string -> int Lwt.t]
*)

val write_c : ?concurrency:concurrency_policy -> ?errno:errno_policy ->
  Format.formatter -> prefix:string -> (module BINDINGS) -> unit
(** [write_c fmt ~prefix bindings] generates C stubs for the functions bound
    with [foreign] in [bindings].  The stubs are intended to be used in
    conjunction with the ML code generated by {!write_ml}.

    The optional argument [concurrency] specifies the concurrency support
    provided by the generated code.  The default is [sequential].

    The generated code uses definitions exposed in the header file
    [ctypes_cstubs_internals.h].
*)

val write_ml : ?concurrency:concurrency_policy -> ?errno:errno_policy ->
  Format.formatter -> prefix:string -> (module BINDINGS) -> unit
(** [write_ml fmt ~prefix bindings] generates ML bindings for the functions
    bound with [foreign] in [bindings].  The generated code conforms to the
    {!FOREIGN} interface.

    The optional argument [concurrency] specifies the concurrency support
    provided by the generated code.  The default is [sequential].

    The generated code uses definitions exposed in the module
    [Cstubs_internals]. *)