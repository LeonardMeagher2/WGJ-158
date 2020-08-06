extends Node

signal evidence_changed(type)
signal inspecting(spatial, distance)
signal done_inspecting(spatial)

const no_evidence = preload("res://Evidence/none.tres")

var random = RandomNumberGenerator.new()
var session_seed
var inspecting_spatial:Spatial = null

var evidence_log = {
	Evidence.TYPE.STATEMENT: {"All":[]},
	Evidence.TYPE.OBSERVATION: {"All":[]},
	Evidence.TYPE.ITEM: {"All":[]}
}

func _ready():
	randomize()
	session_seed = randi()
	reset_random()
	emit_signal("evidence_changed", null)

func reset_random():
	random.seed = session_seed
	
func collect_evidence(evidence:Array):
	var new = false
	var focus_category = null
	for e in evidence:
		if e == no_evidence:
			continue
		var category = evidence_log[e.type]
		if e.source:
			if not category.has(e.source):
				category[e.source] = []
			if not category[e.source].has(e):
				category[e.source].append(e)
		if not category["All"].has(e):
			new = true
			focus_category = e.type
			category["All"].append(e)
	if new:
		emit_signal("evidence_changed", focus_category)
		
func inspect_item(spatial:Spatial, distance:float = 1.0):
	inspecting_spatial = spatial
	emit_signal("inspecting", spatial, distance)
	
func stop_inspecting():
	var spatial = inspecting_spatial
	inspecting_spatial = null
	emit_signal("done_inspecting", spatial)
	

