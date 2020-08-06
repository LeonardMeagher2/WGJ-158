extends RichTextLabel

func _ready():
	bbcode_text = ""
	visible = false

func _on_reading_evidence(reading, evidence):
	if reading:
		bbcode_text = evidence.description
		visible = true
	else:
		text = ""
		visible = false
