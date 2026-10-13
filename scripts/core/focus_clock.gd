extends RefCounted

var previous_eligible := false
var previous_sequence := -1

func reset() -> void:
 previous_eligible = false

func advance(elapsed: float, wall_elapsed: float, eligible: bool, sequence: int) -> float:
 var accrued := 0.0
 if previous_eligible and eligible and sequence > previous_sequence and elapsed > 0 and elapsed <= 5.0 and wall_elapsed >= 0 and wall_elapsed <= 5.0:
  accrued = minf(elapsed,wall_elapsed)
 previous_eligible = eligible and sequence != previous_sequence
 previous_sequence = sequence
 return accrued
