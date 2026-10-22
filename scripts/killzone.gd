extends Area2D

@onready var timer: Timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var label: Label = get_node_or_null("/root/Game/Player1/Camera2D/Label")


var collision_shape # The player's collision shape (disabled during death)
var bod: Node2D     # The player body that touched the killzone


func _on_body_entered(body: Node2D) -> void:
	# Only trigger for bodies that have a CollisionShape2D (the player)
	collision_shape = body.get_node_or_null("CollisionShape2D")
	bod = body
	if collision_shape == null:
		return

	# Prevent re-triggering if the player is already dead or dying
	if Globals.is_dying:
		return
	if "is_dead" in body and body.is_dead:
		return
	if not timer.is_stopped():
		return

	Globals.is_dying = true
	Engine.time_scale = 0.5 # Slow motion during death
	if body.has_method("die"):
		body.die()
		collision_shape.set_deferred("disabled", true) # Lets the frog fall through the floor safely
		audio_stream_player_2d.play()
		timer.start()


# Runs when the death delay ends: either game over or respawn.
func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0 # Back to normal speed
	Globals.is_dying = false
	Globals.health -= 1

	if label != null and is_instance_valid(label):
		label.text = "Score: " + str(Globals.score) + "\nHealth: " + str(Globals.health)

	if Globals.health <= 0:
		Globals.health = 0
		Globals.trigger_game_over()
	else:
		# Respawn: tell the player (resets is_dead, velocity, animation)
		if bod != null and is_instance_valid(bod):
			bod.global_position = Globals.spawn_position # Respawn point (Bubble 7 if reached)
		if collision_shape != null and is_instance_valid(collision_shape):
			collision_shape.set_deferred("disabled", false)
		
		# If respawning at bubble 7, ensure bubble 7 captures the player
		if Globals.has_reached_bubble_7 and is_instance_valid(Globals.bubble_7_ref) and bod != null and is_instance_valid(bod):
			Globals.bubble_7_ref.respawn()
			Globals.bubble_7_ref.carried_body = bod
			Globals.bubble_7_ref.collision_shape.set_deferred("disabled", true)
			Globals.enter_bubble(Globals.bubble_7_ref)

		Globals.player_respawned()
		Globals.trigger_health_lost(Globals.health)
