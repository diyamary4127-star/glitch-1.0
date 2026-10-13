extends Area2D

@onready var timer: Timer = $Timer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _on_body_entered(body: Node2D) -> void:
	# Only trigger for bodies that have a CollisionShape2D (the player)
	var collision_shape = body.get_node_or_null("CollisionShape2D")
	if collision_shape == null:
		return
	
	# Prevent re-triggering if the death sequence is already in progress
	if not timer.is_stopped():
		return
	
	Engine.time_scale = 0.5
	if body.has_method("die"):
		body.die()
	collision_shape.queue_free()
	audio_stream_player_2d.play()
	timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	Globals.reset()
	get_tree().reload_current_scene()
