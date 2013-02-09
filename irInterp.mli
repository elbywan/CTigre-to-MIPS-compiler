(** IrInterp : Interpretor for Intermediate Representation *)

(** Executes a list of I.R. code fragments. The boolean argument
    allows or disallows the display of debugging messages during
    interpretation. *)

val interp : Ir.ir -> bool -> unit

(** NB: for a sucessful execution, the following constraints must be
    satisfied:

    - Each frame should have a correct numargs and numvars fields.
    - For all JUMP and CJUMP, the destination label should be
      declared in the same ESEQ
    - I.R. code should not include any prologue and epilogue, in particular
      no modifications of $sp, $fp and $ra should be done in it.
*)
