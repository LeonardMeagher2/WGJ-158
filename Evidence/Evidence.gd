extends Resource
class_name Evidence

enum TYPE {
	ITEM, #hand
	OBSERVATION, #eye
	STATEMENT #mouth
}

export(TYPE) var type:int = 0
export var source:String
export var concept:String
export(String, MULTILINE) var description:String
export var image:Texture

var new:bool = true

func _to_string():
	var type_string = "NONE"
	match type:
		TYPE.STATEMENT:
			type_string = "STATEMENT"
		TYPE.OBSERVATION:
			type_string = "OBSERVATION"
		TYPE.ITEM:
			type_string = "ITEM"
	return "{concept} [{type}]: {description}".format({
		"concept": concept,
		"type": type_string,
		"description": description
	})
