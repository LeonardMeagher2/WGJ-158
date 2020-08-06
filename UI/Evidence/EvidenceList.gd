extends ScrollContainer

signal evidence_selected(evidence)
signal reading_evidence(reading, evidence)

var EvidenceButton = preload("res://UI/Evidence/EvidenceButton.tscn")

export(Evidence.TYPE) var type:int = 0
export var filter:String = "All"
export var button_group:ButtonGroup

onready var items = $VBoxContainer/Items
onready var menu_button = $VBoxContainer/OptionButton

var category:Dictionary

func _ready():
	Game.connect("evidence_changed",self, "_on_Game_evidence_changed")
	var menu = menu_button.get_popup()
	menu.connect("index_pressed", self, "filter_changed")
	
func filter_changed(idx):
	var menu = menu_button.get_popup()
	filter = menu.get_item_text(idx)
	update_list()

func _on_Game_evidence_changed(_type):
	category = Game.evidence_log[type]
	var menu = menu_button.get_popup()
	menu.clear()
	for key in category:
		menu.add_item(key)
	update_list()

func update_list():
#	if category.has(filter):
#		menu_button.text = filter
#	else:
#		menu_button.text = "All"
	
	var evidence = category[filter]
	var children = items.get_children()
	var l = max(items.get_child_count(), evidence.size())
	var add = items.get_child_count() < evidence.size()
	
	menu_button.visible = category.size() > 2
	
	for i in l:
		
		if add and i >= children.size():
			var item = EvidenceButton.instance()
			items.add_child(item)
			item.evidence = evidence[i]
			item.get_node("Read").group = button_group
			item.connect("pressed", self, "item_selected", [evidence[i]])
			item.connect("reading", self, "item_reading", [evidence[i]])
			
		elif not add and i >= evidence.size():
			var item = items.get_child(i)
			item.queue_free()
		else:
			var item = items.get_child(i)
			item.evidence = evidence[i]
	
	pass

func item_selected(evidence:Evidence):
	emit_signal("evidence_selected", evidence)

func item_reading(reading, evidence):
	emit_signal("reading_evidence", reading, evidence)
