extends Node

#Emitted when the player enters a bubble.
signal bubble_entered(bubble: Area2D)

# Emitted when a bubble is popped.
signal bubble_popped(bubble: Area2D)

# Emitted when a popped bubble respawns.
signal bubble_respawned(bubble: Area2D)

# Emitted whenever the floating state changes (useful for audio / UI).
signal player_respawn
signal bubble_state_changed(is_floating: bool)

signal health_changed(new_health: int)
signal health_lost(remaining_health: int)
signal score_changed(new_score: int)
signal game_over
signal game_started
signal checkpoint_reached(checkpoint_name: String)
signal finish_line_blocked(remaining_coins: int, total_coins: int)
signal game_won

var health: int = 5
var max_health: int = 5
var text: String = ""
var respawn: bool = false

# State tracking
var is_in_bubble: bool = false
var current_bubble: Area2D = null
var score: int = 0
var high_score: int = 0
var total_coins: int = 25

var is_game_started: bool = false
var just_restarted: bool = false
var is_dying: bool = false
var is_game_won: bool = false

# Checkpoint / Respawn state (Bubble 7)
const DEFAULT_SPAWN_POSITION: Vector2 = Vector2(-56, 10)
var spawn_position: Vector2 = DEFAULT_SPAWN_POSITION
var has_reached_bubble_7: bool = false
var bubble_7_ref: Area2D = null


# Called when the player enters a bubble.
func enter_bubble(bubble: Area2D) -> void:
	is_in_bubble = true
	current_bubble = bubble
	if bubble != null and (bubble.name == "bubble7" or bubble.name.to_lower() == "bubble7"):
		reach_bubble_7(bubble)
	bubble_entered.emit(bubble)
	bubble_state_changed.emit(true)


# Called when Bubble 7 is reached (entered or touched)
func reach_bubble_7(bubble: Area2D) -> void:
	if not has_reached_bubble_7:
		has_reached_bubble_7 = true
		bubble_7_ref = bubble
		if "spawn_position" in bubble:
			spawn_position = bubble.spawn_position
		else:
			spawn_position = bubble.global_position
		checkpoint_reached.emit("Bubble 7")


# Called to pop the active bubble (e.g. via jump input or obstacle).
func pop_bubble() -> void:
	if not is_in_bubble:# if space bar is pressed when not in bubble
		return
	
	var bubble := current_bubble
	is_in_bubble = false
	current_bubble = null
	if bubble and is_instance_valid(bubble):
		bubble.pop()
		bubble_popped.emit(bubble)
	bubble_state_changed.emit(false)

func reset() -> void:
	is_in_bubble = false
	current_bubble = null
	health = 5   # Restore lives
	score = 0
	is_game_started = false
	is_dying = false
	is_game_won = false
	has_reached_bubble_7 = false
	bubble_7_ref = null
	spawn_position = DEFAULT_SPAWN_POSITION
	bubble_state_changed.emit(false)
	health_changed.emit(health)
	score_changed.emit(score)


func addpoint() -> void:
	score += 1
	score_changed.emit(score)
	
func player_respawned() -> void:
	player_respawn.emit()

func trigger_health_lost(remaining: int) -> void:
	health_lost.emit(remaining)
	health_changed.emit(health)

func trigger_game_over() -> void:
	is_game_started = false
	game_over.emit()

func trigger_game_started() -> void:
	is_game_started = true
	game_started.emit()

func trigger_game_won() -> void:
	if is_game_won:
		return
	is_game_won = true
	game_won.emit()

func trigger_finish_line_blocked(remaining: int, total: int) -> void:
	finish_line_blocked.emit(remaining, total)
