# Legacy idle preference normalization for v1-v3 save migration only.
extends RefCounted

static func idle_minutes(value) -> int:
 if (value is int or value is float) and float(value) in [5.0,10.0,20.0]:
  return int(value)
 return 10
