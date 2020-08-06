extends KinematicBody
class_name AI

export var enabled:bool = true
export var target:NodePath = @""
export var min_distance:float = 0.0
export var speed:float = 3.0

export var wander:bool = false
export var wander_angle:float = 20.0
export var wander_attention_range:Vector2 = Vector2(1.0, 5.0)
export var wandere_max_distance:float = INF
export(float, 0.0, 1.0) var wander_stop_chance:float = 0.5


var velocity = Vector3()

var wander_timer = 0.0
var stopped = false

var rng = RandomNumberGenerator.new()
onready var starting_position = global_transform.origin

func _ready():
	rng.seed = Game.random.randi()

func _look_at(location:Vector3):
	var at = global_transform.looking_at(location, Vector3.UP)
	var eu = at.basis.get_euler()
	rotation_degrees.y = rad2deg(eu.y)

func _physics_process(delta):
	var movement = Vector3()
	var node = get_node_or_null(target) as Spatial
	var state = PhysicsServer.body_get_direct_state(get_rid())
	
	velocity += state.total_gravity * delta
	velocity *= 1.0-state.total_linear_damp * delta
	
	if enabled:
	
		if node:
			var a = node.global_transform.origin
			
			_look_at(a)
			
			var diff:Vector3 = (a - global_transform.origin)
			
			if diff.length_squared() > min_distance*min_distance:
				diff -= diff.normalized() * min_distance * 0.75
				diff.x = clamp(diff.x, -speed, speed)
				diff.z = clamp(diff.z, -speed, speed)
				movement = diff
		elif wander:
			
			if wander_timer <= 0.0:
				var too_far = starting_position.distance_squared_to(global_transform.origin) >= wandere_max_distance*wandere_max_distance
				stopped = rng.randf() <= wander_stop_chance
				if not stopped:
					if too_far:
						_look_at(starting_position)
					rotation_degrees.y += rng.randf_range(-wander_angle, wander_angle)
				wander_timer = rng.randf_range(wander_attention_range.x, wander_attention_range.y)
			else:
				wander_timer -= delta
				if not stopped:
					movement = (global_transform.xform(Vector3.FORWARD) - global_transform.origin)	
					
					if is_on_wall():
						stopped = true
						wander_timer = rng.randf_range(wander_attention_range.x, wander_attention_range.y)
						rotation_degrees.y += 180.0 + rng.randf_range(-wander_angle, wander_angle)
						
	
		movement.y = velocity.y	
		velocity = movement 
		
		velocity = move_and_slide(velocity, Vector3.UP, false, 4, deg2rad(45), true)


func start_conversation():
	var player = get_tree().get_nodes_in_group("player")[0] as Spatial
	if player:
		_look_at(player.global_transform.origin)
		enabled = false
		print("conversation")


func end_conversation():
	enabled = true
	print("end conversation")

