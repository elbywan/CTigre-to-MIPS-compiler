(** Canon : functions for linearizing and canonizing I.R. code *)

open Label

val linearize : Ir.exp -> Lin.funbody
  (** From an arbitrary I.R. expression, produce a linearized function body. *)

type basicBlock = { label : lbl; inner : Lin.stms; last : Lin.stm }
  (** A basic block representation:
     [{ label=l; inner=b; last=s}] is equivalent to [([LABEL lab] @ b @ [s])]
  *)

val basicBlocks : Lin.stms -> basicBlock list * lbl
  (** From a list of linearized statements, produce a list of
     basic blocks satisfying the following properties:
     - 1. 2. 3. 4. as above;
     - 5. Every block begins with a [LABEL];
     - 6. A [LABEL] appears only at the beginning of a block;
     - 7. Any [JUMP] or [CJUMP] is the last stm in a block;
     - 8. Every block ends with a [JUMP] or [CJUMP];

     Also produce the "label" to which control will be passed
     upon exit.
  *)

val traceSchedule : basicBlock list * lbl -> Lin.stms
  (** From a list of basic blocks satisfying properties 1-6,
     along with an "exit" label, produce a list of stms such that:
     - 1. 2. 3. 4. as above;
     - 9. Every [CJUMP(_,t,f)] is immediately followed by [LABEL f].

     The blocks are reordered to satisfy property 9; also
     in this reordering as many [JUMP(NAME(lab))] statements
      as possible are eliminated by falling through into [LABEL(lab)].
  *)

