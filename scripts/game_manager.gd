extends Node

const GAME_UI_SCENE = preload("res://scenes/game_ui.tscn")
const FINISH_LINE_SCENE = preload("res://scenes/finish_line.tscn")

@onready var label: Label = get_node_or_null("../Player1/Camera2D/Label")

var can_trigger_finish_warning: bool = true

func _ready() -> void:
	# Instantiate and attach the GameUI CanvasLayer
	var ui = GAME_UI_SCENE.instantiate()
	add_child(ui)
	
	# Hide the legacy world-space camera label so only the clean HUD displays
	if label != null and is_instance_valid(label):
		label.hide()

	# Count total coins in the level
	var coins_node = get_node_or_null("../coins")
	if coins_node:
		Globals.total_coins = coins_node.get_child_count()
	else:
		Globals.total_coins = 25

	# Cache Bubble 7 reference if present
	var bubble7_node = get_node_or_null("../bubbles/bubble7")
	if bubble7_node:
		Globals.bubble_7_ref = bubble7_node

	# Wire up 'area' (placed by user at Bubble 7) as a checkpoint trigger
	var area_bubble7 = get_node_or_null("../area/Area2D")
	if area_bubble7:
		area_bubble7.body_entered.connect(func(body: Node2D):
			if body is CharacterBody2D or body.name == "Player1":
				var b7 = bubble7_node if bubble7_node else Globals.current_bubble
				Globals.reach_bubble_7(b7)
		)

	# Wire up 'area2' (placed by user at purple tiles) or instantiate finish_line
	var area_finish = get_node_or_null("../area2/Area2D")
	if area_finish:
		# Ensure collision shape covers the purple tiles (columns 54-58, rows -25 to -23)
		var shape_node = area_finish.get_node_or_null("CollisionShape2D")
		if shape_node and shape_node.shape is RectangleShape2D:
			shape_node.shape = shape_node.shape.duplicate()
			shape_node.shape.size = Vector2(84, 52)
			shape_node.position = Vector2(10, 20)
		area_finish.body_entered.connect(func(body: Node2D):
			if body is CharacterBody2D or body.name == "Player1":
				_on_finish_line_entered()
		)
	else:
		var finish_instance = FINISH_LINE_SCENE.instantiate()
		finish_instance.name = "finish_line"
		# Center of purple tiles: cols 54..58 (x: 864..944 -> 904), rows -25..-23 (y: -400..-352 -> -376)
		finish_instance.position = Vector2(904, -376)
		get_parent().call_deferred("add_child", finish_instance)


func _on_finish_line_entered() -> void:
	if Globals.is_dying or Globals.is_game_won:
		return
	
	if Globals.score >= Globals.total_coins and Globals.total_coins > 0:
		Globals.trigger_game_won()
	else:
		if can_trigger_finish_warning:
			can_trigger_finish_warning = false
			var remaining: int = Globals.total_coins - Globals.score
			Globals.trigger_finish_line_blocked(remaining, Globals.total_coins)
			await get_tree().create_timer(3.0).timeout
			can_trigger_finish_warning = true


func addpoint() -> void:
	Globals.addpoint()
	if label != null and is_instance_valid(label):
		label.text = "Score: " + str(Globals.score) + "/" + str(Globals.total_coins) + "\nHealth: " + str(Globals.health)


func _on_area_child_entered_tree(_node: Node) -> void:
	pass
