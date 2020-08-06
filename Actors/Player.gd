extends KinematicBody


const SPEED = 4.0 # units per second
const RUNNING_SPEED = 6.0
const JUMP = 3.0

export var enabled = true

var mouse_sensitivity = Vector2(0.5,0.7) # TODO move to config

var pitch_yaw = Vector2()
var velocity = Vector3()
var can_jump = false

onready var tween = $Tween
onready var camera = $Camera
onready var action_ray = $Camera/ActionRay
onready var remote_transform = $Camera/RemoteTransform

onready var hand_sprite = Ui.get_node("Center/Hand/Sprite")
onready var hand_label = Ui.get_node("Center/Hand/Label")

var can_interact = false
var look_target = null

func _ready():
	pitch_yaw = Vector2(
		camera.rotation_degrees.x,
		rotation_degrees.y
	)
	Game.connect("inspecting", self, "_on_Game_inspecting")
	Game.connect("done_inspecting", self, "_on_Game_done_inspecting")
	Ui.connect("showing_menu", self, "showing_menu")
	Ui.dialog.connect("speak_look_at", self, "_on_Dialog_speak_look_at")
	
func showing_menu(showing):
	enabled = not showing
	action_ray.enabled = not showing
	
func look(delta:float):
	
	var at = camera.global_transform.looking_at(look_target, Vector3.UP)
	var euler = at.basis.get_euler()
	
	var look = Vector2(rad2deg(euler.x), rad2deg(euler.y))
	
	pitch_yaw.x = clamp(pitch_yaw.x, -90, 90)
	pitch_yaw.y = fposmod(pitch_yaw.y, 360.0)
	
	var diff = fmod(look.y - pitch_yaw.y, 360.0)
	
	look.x = clamp(look.x, -90, 90)
	look.y = pitch_yaw.y + (fmod(diff * 2.0, 360.0) - diff)
	
	var distance = pitch_yaw.distance_to(look)
	pitch_yaw = pitch_yaw.linear_interpolate(look, 1.0/0.2 * delta)

func _physics_process(delta):
	
	var movement = Vector3()
	var state = PhysicsServer.body_get_direct_state(get_rid())
	
	var show_hand = false
	if action_ray.is_colliding():
		var area = action_ray.get_collider() as EvidenceArea
		var frame = area.type * 2
		
		if area:
			hand_label.text = area.name
			show_hand = true
			hand_sprite.frame = frame
			
			
			if can_interact:
				if Input.is_action_pressed("interact"):
					hand_sprite.frame = frame+1
				
				var released = Input.is_action_just_released("interact")
				if released:
					can_interact = false
				if released and area.has_signal("interact"):
					area.emit_signal("interact")
	
	if not Input.is_action_pressed("interact"):
		hand_label.visible = show_hand
		hand_sprite.visible = show_hand
	
	velocity += state.total_gravity * delta
	velocity *= 1.0-state.total_linear_damp * delta
	
	if look_target:
		look(delta)
	
	rotation_degrees.y = pitch_yaw.y
	camera.rotation_degrees.x = pitch_yaw.x
	
	if enabled:
		movement.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		movement.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
		var basis = global_transform.basis
		movement = basis.xform(movement.normalized() * SPEED)
	
	movement.y = velocity.y
	
	if enabled and Input.is_action_just_pressed("jump") and can_jump:
		movement.y = JUMP
		can_jump = false
		
	velocity = movement 
	
	velocity = move_and_slide(velocity, Vector3.UP, false, 4, deg2rad(45), false)
	
	if is_on_floor():
		can_jump = true

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			var rel = event.relative * mouse_sensitivity
			pitch_yaw -= Vector2(
				rel.y,
				rel.x
			)
			pitch_yaw.y = fposmod(pitch_yaw.y, 360.0)
			pitch_yaw.x = clamp(pitch_yaw.x, -90, 90)
	
	if event.is_action_pressed("interact"):
		can_interact = true
	
	if enabled and event.is_action_pressed("restart"):
		Game.reset_random()
		get_tree().reload_current_scene()
	
func _on_Game_inspecting(spatial:Spatial, distance:float):
	spatial.set_meta("_inspecting_original_transform", spatial.transform)
	look_target = spatial.global_transform.origin
	remote_transform.rotation = Vector3()
	remote_transform.translation = Vector3(-0.5*distance,0,-distance)
	remote_transform.remote_path = spatial.get_path()

func _on_Game_done_inspecting(spatial:Spatial):
	remote_transform.remote_path = @""
	var meta_key = "_inspecting_original_transform"
	if spatial and spatial.has_meta(meta_key):
		spatial.transform =  spatial.get_meta(meta_key)
		spatial.remove_meta(meta_key)
	look_target = null

func _on_Dialog_speak_look_at(location):
	look_target = location
