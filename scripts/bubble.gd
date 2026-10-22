class_name Bubble
extends Area2D

# Emitted when this specific bubble pops.
signal popped
# Emitted when this specific bubble finishes its respawn timer.
signal respawned

@export var respawn_time: float = 4.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var timer: Timer = $Timer

var spawn_position: Vector2
var carried_body: CharacterBody2D = null
var is_popped: bool = false


func _ready() -> void:
	spawn_position = global_position
	timer.one_shot = true
	animated_sprite.play("normal")
	animated_sprite.frame = 0


func _process(_delta: float) -> void:
	# Keep bubble centered on the carried player
	if carried_body and is_instance_valid(carried_body) and not is_popped:
		global_position = carried_body.global_position


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if name == "bubble7" or name.to_lower() == "bubble7":
			Globals.reach_bubble_7(self)

	if Globals.is_in_bubble:# we dont check if we are hitting already popped bubbles coz their collision will be disabled eitherhow
		return
	
	if body is CharacterBody2D:
		if "is_dead" in body and body.is_dead:
			return
		carried_body = body
		# Temporarily disable collision shape while inside
		collision_shape.set_deferred("disabled", true)
		Globals.enter_bubble(self)


func _on_body_exited(_body: Node2D) -> void:
	#popping is handled via pop() rather than physics area exit
	pass


# Pops this bubble, triggers animation, and starts the respawn timer.
func pop() -> void:
	is_popped = true
	carried_body = null
	animated_sprite.play("pop")
	$AudioStreamPlayer.play()
	
	popped.emit()
	timer.start(respawn_time)


func _on_timer_timeout() -> void:
	respawn()


## Resets the bubble back to its original spawn position and re-enables collision.
func respawn() -> void:
	timer.stop()
	global_position = spawn_position
	is_popped = false
	carried_body = null
	animated_sprite.show()
	animated_sprite.play("normal")
	collision_shape.set_deferred("disabled", false)
	
	respawned.emit()
	Globals.bubble_respawned.emit(self)


func _on_animated_sprite_2d_animation_finished() -> void:
	if(animated_sprite.animation=="pop"):
			animated_sprite.hide()
