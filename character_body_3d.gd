extends CharacterBody3D

@onready var cam_pivot = get_node("cam_pivot")

@onready var stand_col = get_node("standing_col")
@onready var crouch_col = get_node("crouch_col")


@onready var anim_tree = get_node("AnimationTree").get("parameters/playback")

#explain when doing the animations and mantling state
@onready var above_head = get_node("above_head") #col_shape, is something above player head?
@onready var head_cast = get_node("all_raycast/head_cast")
@onready var head_cast2 = get_node("all_raycast/head_cast2")
@onready var new_pos = get_node("all_raycast/new_pos")
@onready var waist_cast = get_node("all_raycast/waist_cast")

var speed = 1
var jump_velocity = 4
var mouse_sensitivity = 0.002

var is_crouching = false
#var can_hop_over = false
var can_mantle = true

var released_buttons = ["left","right", "forward", "backwards"]

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready():
	
	#Needs a starting animation, or first trans anim, will cause frame jump
	anim_tree.travel("standing_idle")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_node("AnimationTree").active = true
	
func _physics_process(delta):
	
	control_loop(delta)
	head_control()
	#talk about the input func
	wall_run()
	run_state()
	check_mantle()
	
func control_loop(delta):
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backwards")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
	#This code was added
		if not is_crouching:
		
			if not waist_cast.is_colliding():
			
				anim_tree.travel("head_bob")
				
			if waist_cast.is_colliding():
			
				anim_tree.travel("standing_idle")
		
	else:
		
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		#anim_tree.travel("standing_idle")

	move_and_slide()
	
func head_control():
	
	#The cam_pivot expo. springarm for 3rd person
	if Input.is_action_just_pressed("ui_cancel"):
		#places mouse cursor to center of screen, then locks it to center
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE
	
func check_mantle():
	
	var has_ledge = (head_cast2.is_colliding() and not head_cast.is_colliding())
	
	if can_mantle:
		
		#we are at a ledge
		if has_ledge:
			
			velocity.y = 0
			gravity = 0
			
			if has_ledge and Input.is_action_just_pressed("jump"):
				
				anim_tree.travel("mantle")
				#needs a smooth transition
				var peek = create_tween()
				peek.tween_property(self,"position",  new_pos.global_position,0.50)
				#self.global_position = new_pos.global_position
			
		else:
			
			gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
			#anim_tree.travel("standing_idle")
	
func run_state():
	
	if Input.is_action_pressed("run"):
		
		speed = 3
		
	else:
		
		speed = 1
	
func hop_over_trigger():
	pass
	#can_hop_over = true
	
func check_crouch_state():
	
	if is_crouching:
		
		#check_player_collision_state(is_crouching)
		anim_tree.travel("standing_idle")
		
	if not is_crouching:
		
		#check_player_collision_state(is_crouching)
		anim_tree.travel("crouch_idle")
		
func change_collision_state():
	
	#should add a raycast to see if can uncrouch
	stand_col.disabled = not is_crouching
	crouch_col.disabled = is_crouching
	
func check_input_release(event):
	
	for x in released_buttons.size():
		
		if event.is_action_released(released_buttons[x]):
			
			if not is_crouching:
				
				anim_tree.travel("standing_idle")
				
			if is_crouching:
				
				anim_tree.travel("crouch_idle")
	
func _input(event):
	
	if event is InputEventMouseMotion:
		
		rotate_y(-event.relative.x * mouse_sensitivity)
		cam_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		#keeps camera from being able to 360, sprite should be parented to camera
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x,-PI/2, PI/2)
	
	check_input_release(event)
	
	if event.is_action_pressed("crouch"):
		
		check_crouch_state()
		change_collision_state()
		is_crouching = not is_crouching
		
	if not is_crouching:
		
		if event.is_action_pressed("lean_left"):
			
			anim_tree.travel("lean_left")
			
		if event.is_action_released("lean_left"):
			
			anim_tree.travel("standing_idle")
			
		if event.is_action_pressed("lean_right"):
			
			anim_tree.travel("lean_right")
			
		if event.is_action_released("lean_right"):
			
			anim_tree.travel("standing_idle")
	
func _on_above_head_body_entered(_body):
	
	#nothing above our head, can mantle over
	print("something")
	can_mantle = false
	
func _on_above_head_body_exited(_body):
	print("nothing")
	#Somethings above our head, can't mantle over
	can_mantle = true
	
	
func wall_run():
	
	pass
