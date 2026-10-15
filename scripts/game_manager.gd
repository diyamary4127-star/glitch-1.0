extends Node

@onready var label: Label = $"../Player1/Camera2D/Label"





# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
var score=0
func addpoint():
	score+=1
	label.text="SCORE : "+str(score)
	
	
