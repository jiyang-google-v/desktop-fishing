extends RefCounted

var previous_eligible := false
var previous_sequence := -1
var previous_generation := ""

func reset() -> void:
 previous_eligible = false
 previous_sequence = -1
 previous_generation = ""

func advance(elapsed: float, wall_elapsed: float, eligible: bool, sequence: int, generation: String = "") -> float:
 var accrued := 0.0
 var continuous: bool = sequence > previous_sequence and generation == previous_generation
 var valid_interval: bool = is_finite(elapsed) and is_finite(wall_elapsed) and elapsed > 0 and elapsed <= 5.0 and wall_elapsed > 0 and wall_elapsed <= 5.0 and absf(elapsed - wall_elapsed) <= 1.0
 if previous_eligible and eligible and continuous and valid_interval:
  accrued = minf(elapsed,wall_elapsed)
 previous_eligible = eligible and sequence > previous_sequence and valid_interval
 previous_sequence = sequence
 previous_generation = generation
 return accrued
