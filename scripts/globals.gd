extends Node

#Emitted when the player enters a bubble.
signal bubble_entered(bubble: Area2D)

# Emitted when a bubble is popped.
signal bubble_popped(bubble: Area2D)

# Emitted when a popped bubble respawns.
signal bubble_respawned(bubble: Area2D)

# Emitted whenever the floating state changes (useful for audio / UI).
signal bubble_state_changed(is_floating: bool)

# State tracking
var is_in_bubble: bool = false
var current_bubble: Area2D = null
var score:=0


# Called when the player enters a bubble.
func enter_bubble(bubble: Area2D) -> void:
	is_in_bubble = true
	current_bubble = bubble
	bubble_entered.emit(bubble)
	bubble_state_changed.emit(true)


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
	bubble_state_changed.emit(false)


func addpoint():
	score+=1
