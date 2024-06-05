extends CharacterBody3D

@onready var standing_col = get_node("standing_col")
@onready var crouching_col = get_node("crouching_col")
@onready var cam_pivot = get_node("cam_pivot")

@onready var top_head = get_node("all_raycast/top_head")
@onready var face_lvl = get_node("all_raycast/face")
@onready var new_pos = get_node("all_raycast/new_pos")

var speed = 1
var jump_vel = 4.5
var mouse_sensitivity = 0.002

var can_mantle = true
var is_crouching = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	
	control_loop(delta)
	head_control()
	run_state()
	check_mantle()
	move_and_slide()
	
	
func control_loop(delta):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_vel

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
func head_control():
	
	#The cam_pivot expo. springarm for 3rd person
	if Input.is_action_just_pressed("ui_cancel"):
		#places mouse cursor to center of screen, then locks it to center
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE
	
func run_state():
	
	if Input.is_action_pressed("run"):
		
		speed = 3
		
	else:
		
		speed = 1
	
func check_mantle():
	
	var has_ledge = (face_lvl.is_colliding() and not top_head.is_colliding())
	
	if can_mantle:
		
		#we are at a ledge
		if has_ledge:
			
			velocity.y = 0
			gravity = 0
			
			if has_ledge and Input.is_action_just_pressed("jump"):
				
				var climb_tween = create_tween()
				climb_tween.tween_property(self,"position",  new_pos.global_position,0.50)
				#self.global_position = new_pos.global_position
			
		else:
			
			gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
func _input(event):
	
	if event is InputEventMouseMotion:
		
		rotate_y(-event.relative.x * mouse_sensitivity)
		cam_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		#keeps camera from being able to 360, sprite should be parented to camera
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x,-PI/2, PI/2)
		
		
	if event.is_action_pressed("crouch"):
		
		check_crouch_state()
		is_crouching = not is_crouching
	
func check_crouch_state():
	
	standing_col.disabled = not is_crouching
	crouching_col.disabled = is_crouching
	
	
func _on_above_head_body_entered(_body):
	
	can_mantle = false
	
func _on_above_head_body_exited(_body):
	
	can_mantle = true
