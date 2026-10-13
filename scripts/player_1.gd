extends CharacterBody2D
# Emitted locally when the player enters a bubble.
signal entered_bubble(bubble: Area2D)
# Emitted locally when the player pops out of a bubble.
signal popped_bubble

@export_group("Movement")
@export var float_speed: float = -100.0
@export var steer_speed: float = 200.0
@export var gravity: float = 600.0
@export var pop_jump_velocity: float = -200.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


var is_dead: bool = false


func _ready() -> void:
	is_dead = false
	Globals.reset()
	animated_sprite_2d.play("idle")
	# Listen to global bubble events
	Globals.bubble_entered.connect(_on_bubble_entered)
	Globals.bubble_popped.connect(_on_bubble_popped)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	if Globals.is_in_bubble:
		Globals.pop_bubble()
	Globals.reset()
	animated_sprite_2d.play("death")


func _physics_process(delta: float) -> void:
	# When dead or collision shape has been removed, fall in death pose with controls disabled
	var col := get_node_or_null("CollisionShape2D")
	if is_dead or col == null or col.is_queued_for_deletion():
		is_dead = true
		if animated_sprite_2d.animation != "death":
			animated_sprite_2d.play("death")
		velocity.x = 0
		velocity.y += gravity * delta
		move_and_slide()
		return

	var input_axis := Input.get_axis("ui_left", "ui_right")
	
	
	# Horizontal steering
	velocity.x = input_axis * steer_speed
	
	# Flip sprite according to direction of movement
	if input_axis > 0:
		animated_sprite_2d.flip_h = false
	elif input_axis < 0:
		animated_sprite_2d.flip_h = true
	
	if Globals.is_in_bubble:
		# Float upwards while inside bubble
		velocity.y = float_speed
		
		# Pop the bubble when player presses action button (e.g. Space / Enter)
		if Input.is_action_just_pressed("ui_accept"):
			Globals.pop_bubble()
	else:
		# Fall under gravity when outside bubble
		velocity.y += gravity * delta
		_update_ground_air_animation()

	move_and_slide()
	


func _update_ground_air_animation() -> void:
	if is_on_floor():
		if animated_sprite_2d.animation != "idle":
			animated_sprite_2d.play("idle")
	else:
		if velocity.y > 0 and animated_sprite_2d.animation != "drop":
			animated_sprite_2d.play("drop")


func _on_bubble_entered(bubble: Area2D) -> void:
	animated_sprite_2d.play("idle")
	entered_bubble.emit(bubble)


func _on_bubble_popped(_bubble: Area2D) -> void:
	# Give the frog a slight hop upward when bursting free
	velocity.y = pop_jump_velocity
	animated_sprite_2d.play("drop")
	popped_bubble.emit()


func _on_animated_sprite_2d_animation_changed() -> void:
	match animated_sprite_2d.animation:
		"idle", "death":
			animated_sprite_2d.offset = Vector2(0.25, -1.75)
		"drop":
			animated_sprite_2d.offset = Vector2(0.28, 4.145)


func _on_popped_bubble() -> void:
	print("CHECK") # Replace with function body.
