extends Area2D

var can_trigger_warning: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body.name == "Player1":
		check_finish_line()

func check_finish_line() -> void:
	if Globals.is_dying or Globals.is_game_won:
		return
	
	if Globals.score >= Globals.total_coins and Globals.total_coins > 0:
		Globals.trigger_game_won()
	else:
		if can_trigger_warning:
			can_trigger_warning = false
			var remaining: int = Globals.total_coins - Globals.score
			Globals.trigger_finish_line_blocked(remaining, Globals.total_coins)
			# Cooldown so the warning message doesn't spam repeatedly while staying in the zone
			await get_tree().create_timer(3.0).timeout
			can_trigger_warning = true
