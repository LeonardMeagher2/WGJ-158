extends Resource
class_name Proof

export(Array, Resource) var evidence = []

func equal(other:Proof):
	if other.evidence.size() != evidence.size():
		return false
	
	for e in other.evidence:
		if not evidence.has(e):
			return false
	return true
