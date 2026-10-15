extends Area2D

@onready var timer: Timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var label: Label = $Label
@onready var timer_2: Timer = $Timer2

var collision_shape # The player's collision shape (disabled during death)
var bod: Node2D     # The player body that touched the killzone


func _on_body_entered(body: Node2D) -> void:
	# Only trigger for bodies that have a CollisionShape2D (the player)
	collision_shape = body.get_node_or_null("CollisionShape2D")
	bod = body
	if collision_shape == null:
		return

	# Prevent re-triggering if the death sequence is already in progress
	if not timer.is_stopped():
		return

	Engine.time_scale = 0.5 # Slow motion during death
	if body.has_method("die"):
		body.die()
		collision_shape.disabled = true # Lets the frog fall through the floor
		audio_stream_player_2d.play()
		timer.start()


# Runs when the death delay ends: either game over or respawn.
func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0 # Back to normal speed
	if Globals.health == 0:
		# Out of lives: reset global state and restart the level
		Globals.reset()
		get_tree().reload_current_scene()
	else:
		# Respawn: tell the player (resets is_dead, velocity, animation)
		Globals.player_respawned()
		collision_shape.disabled = false
		bod.global_position = Vector2(-56, 10) # Respawn point
		Globals.health -= 1
