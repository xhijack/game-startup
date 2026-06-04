class_name Research
extends RefCounted
## Logika kombinasi talent → fitur (DNA Kairosoft). MURNI, tanpa node.
## Bekerja atas Array[Talent] (punya properti .type & .skill).

static func team_total_skill(talents: Array) -> int:
	var s := 0
	for t in talents:
		s += t.skill
	return s

## True bila tim punya MINIMAL satu talent untuk tiap tipe yang dibutuhkan.
static func team_has_types(talents: Array, required_types: Array) -> bool:
	for rt in required_types:
		var found := false
		for t in talents:
			if t.type == rt:
				found = true
				break
		if not found:
			return false
	return true

## Syarat fitur terpenuhi: tipe talent lengkap DAN total skill tim cukup.
static func meets_requirements(feature: Dictionary, talents: Array) -> bool:
	var req: Dictionary = feature.get("requires", {})
	if not team_has_types(talents, req.get("types", [])):
		return false
	if team_total_skill(talents) < int(req.get("min_team_skill", 0)):
		return false
	return true
