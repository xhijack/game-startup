extends GutTest
## Test untuk Research (sistem kombinasi talent, core murni).

func _t(type: String, skill: int) -> Talent:
	return Talent.new({ "type": type, "skill": skill })

func test_team_total_skill() -> void:
	assert_eq(Research.team_total_skill([_t("engineer", 4), _t("marketing", 3)]), 7)

func test_team_has_types() -> void:
	var team := [_t("engineer", 4), _t("marketing", 3)]
	assert_true(Research.team_has_types(team, ["engineer", "marketing"]))
	assert_false(Research.team_has_types(team, ["designer"]))

func test_meets_requirements_skill_gate() -> void:
	var f := { "requires": { "types": ["engineer"], "min_team_skill": 10 } }
	assert_false(Research.meets_requirements(f, [_t("engineer", 5)]))
	assert_true(Research.meets_requirements(f, [_t("engineer", 6), _t("designer", 5)]))

func test_meets_requirements_type_gate() -> void:
	var f := { "requires": { "types": ["engineer", "designer"], "min_team_skill": 0 } }
	assert_false(Research.meets_requirements(f, [_t("engineer", 5)]))
	assert_true(Research.meets_requirements(f, [_t("engineer", 5), _t("designer", 5)]))
