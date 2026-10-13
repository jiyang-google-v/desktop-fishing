extends RefCounted

static func validate(value, token: String, now: float) -> Dictionary:
 if not value is Dictionary or value.get("token","") != token:
  return {}
 for key in ["supported","foreground","locked"]:
  if not value.get(key) is bool:
   return {}
 for key in ["idle_seconds","sampled_at","sequence","epoch"]:
  var number = value.get(key)
  if not (number is int or number is float) or not is_finite(float(number)) or number < 0:
   return {}
 if value.sequence < 1 or value.sequence != floor(value.sequence) or value.epoch != floor(value.epoch):
  return {}
 var age: float = now - float(value.sampled_at)
 if age < 0 or age > 3.0 or not value.supported:
  return {}
 return value
