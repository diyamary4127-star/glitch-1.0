extends CharacterBody2D

# Emitted locally when the player enters a bubble.
signal entered_bubble(bubble: Area2D)
# Emitted locally when the player pops out of a bubble.
signal popped_bubble

@export_group("Movement")
@export var float_speed: float = -100.0      # Upward speed while inside a bubble
@export var steer_speed: float = 200.0       # Left/right speed
@export var gravity: float = 600.0           # Downward pull when outside a bubble
@export var pop_jump_velocity: float = -200.0 # Small hop when a bubble pops

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var fallen: Label = get_node_or_null("Camera2D/fallen")

# True while the frog is dead. Bubbles ignore the player while this is true.
var is_dead: bool = false


func _ready() -> void:
	is_dead = false
	animated_sprite_2d.play("idle")
	# Listen to global bubble/respawn events
	Globals.bubble_entered.connect(_on_bubble_entered)
	Globals.bubble_popped.connect(_on_bubble_popped)
	Globals.player_respawn.connect(_on_player_respawn)


# Called by the killzone when the frog touches something deadly.
func die() -> void:
	if is_dead:
		return # Already dead, don't run twice
	is_dead = true
	# Free the frog from its bubble first (this pops the bubble)
	if Globals.is_in_bubble:
		Globals.pop_bubble()
	# Play death AFTER popping, so nothing overrides it
	animated_sprite_2d.play("death")
	


func _physics_process(delta: float) -> void:
	# DEAD STATE
	if is_dead:
		if animated_sprite_2d.animation != "death":
			animated_sprite_2d.play("death")
		velocity.x = 0
		velocity.y += gravity * delta
		move_and_slide()
		return # Skip all normal movement and animation code below

	# NORMAL STATE
	var input_axis := Input.get_axis("ui_left", "ui_right")

	# Horizontal steering
	velocity.x = input_axis * steer_speed

	# Flip sprite according to direction of movement
	if input_axis > 0:
		animated_sprite_2d.flip_h = false
	elif input_axis < 0:
		animated_sprite_2d.flip_h = true

	if Globals.is_in_bubble:
		# Float upwards while inside the bubble
		velocity.y = float_speed

		# Pop the bubble when the action button is pressed (Space )
		if Input.is_action_just_pressed("ui_accept"):
			Globals.pop_bubble()
	else:
		# Fall under gravity when outside a bubble
		velocity.y += gravity * delta
		_update_ground_air_animation()

	move_and_slide()


# Chooses idle/drop animation depending on whether we're on the ground.
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
	# Don't switch to "drop" if the frog is dying, or it would hide the death animation
	if not is_dead:
		animated_sprite_2d.play("drop")
	popped_bubble.emit()


# Adjusts the sprite offset so each animation lines up with the collision shape.
func _on_animated_sprite_2d_animation_changed() -> void:
	match animated_sprite_2d.animation:
		"idle", "death":
			animated_sprite_2d.offset = Vector2(0.25, -1.75)
		"drop":
			animated_sprite_2d.offset = Vector2(0.28, 4.145)

# Called (via Globals) when the killzone respawns the frog.
func _on_player_respawn() -> void:
	is_dead = false           
	velocity = Vector2.ZERO  
	animated_sprite_2d.play("idle")
