extends CanvasLayer

# --- NODES ---
@onready var hud: MarginContainer = $HUD
@onready var score_label: Label = %ScoreLabel
@onready var health_label: Label = %HealthLabel

@onready var start_screen: Control = $StartScreen
@onready var start_button: Button = %StartButton

@onready var ready_overlay: Control = $ReadyOverlay
@onready var ready_label: Label = %ReadyLabel

@onready var health_lost_banner: Control = $HealthLostBanner
@onready var health_lost_text: Label = %HealthLostText
@onready var health_lost_subtext: Label = %HealthLostSubtext

@onready var checkpoint_banner: Control = $CheckpointBanner
@onready var checkpoint_title: Label = %CheckpointTitle
@onready var checkpoint_subtext: Label = %CheckpointSubtext

@onready var finish_warning_banner: Control = $FinishWarningBanner
@onready var finish_warning_title: Label = %FinishWarningTitle
@onready var finish_warning_subtext: Label = %FinishWarningSubtext

@onready var game_over_screen: Control = $GameOverScreen
@onready var final_score_label: Label = %FinalScoreLabel
@onready var play_again_button: Button = %PlayAgainButton

@onready var victory_screen: Control = $VictoryScreen
@onready var victory_score_label: Label = %VictoryScoreLabel
@onready var victory_health_label: Label = %VictoryHealthLabel
@onready var victory_play_again_button: Button = %VictoryPlayAgainButton

@onready var audio_click: AudioStreamPlayer = $AudioClick
@onready var audio_start: AudioStreamPlayer = $AudioStart
@onready var audio_hurt: AudioStreamPlayer = $AudioHurt

var health_banner_tween: Tween
var checkpoint_banner_tween: Tween
var warning_banner_tween: Tween
var ready_tween: Tween

func _ready() -> void:
	# Ensure UI processes even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect signals from Globals
	Globals.score_changed.connect(_on_score_changed)
	Globals.health_changed.connect(_on_health_changed)
	Globals.health_lost.connect(_on_health_lost)
	Globals.game_over.connect(_on_game_over)
	Globals.game_won.connect(_on_game_won)
	Globals.finish_line_blocked.connect(_on_finish_line_blocked)
	Globals.checkpoint_reached.connect(_on_checkpoint_reached)

	# Connect button clicks
	start_button.pressed.connect(_on_start_pressed)
	play_again_button.pressed.connect(_on_play_again_pressed)
	victory_play_again_button.pressed.connect(_on_play_again_pressed)

	# Initial visibility states
	ready_overlay.hide()
	health_lost_banner.hide()
	checkpoint_banner.hide()
	finish_warning_banner.hide()
	game_over_screen.hide()
	victory_screen.hide()

	update_hud()

	# If restarting after game over / win, jump straight into Get Ready
	if Globals.just_restarted:
		Globals.just_restarted = false
		start_screen.hide()
		start_get_ready_sequence()
	else:
		# Initial fresh launch: pause and wait for player to press Start
		start_screen.show()
		get_tree().paused = true
		start_button.grab_focus()


func update_hud() -> void:
	if score_label:
		score_label.text = str(Globals.score) + "/" + str(Globals.total_coins)
	if health_label:
		var hearts := ""
		for i in range(Globals.health):
			hearts += "❤ "
		for i in range(5 - Globals.health):
			hearts += "♡ "
		health_label.text = hearts.strip_edges() + " (" + str(Globals.health) + ")"


func _on_score_changed(_new_score: int) -> void:
	update_hud()


func _on_health_changed(_new_health: int) -> void:
	update_hud()


# --- START BUTTON & GET READY ---
func _on_start_pressed() -> void:
	start_screen.hide()
	start_get_ready_sequence()


func start_get_ready_sequence() -> void:
	get_tree().paused = true
	ready_overlay.show()
	ready_overlay.modulate.a = 0.0

	if audio_start:
		audio_start.play()

	# Animate "GET READY!" with a subtle scale pop and fade
	if ready_tween and ready_tween.is_valid():
		ready_tween.kill()
	ready_tween = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ready_tween.tween_property(ready_overlay, "modulate:a", 1.0, 0.25)
	ready_label.scale = Vector2(0.6, 0.6)
	ready_label.pivot_offset = ready_label.size / 2.0
	ready_tween.tween_property(ready_label, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Wait for 1.5 seconds in real-time (even while paused)
	await get_tree().create_timer(1.5, true, false, true).timeout

	# Fade out Get Ready message
	var fade_out := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_out.tween_property(ready_overlay, "modulate:a", 0.0, 0.3)
	await fade_out.finished
	ready_overlay.hide()

	# Start game
	get_tree().paused = false
	Globals.trigger_game_started()


# --- CHECKPOINT NOTIFICATION ---
func _on_checkpoint_reached(_checkpoint_name: String = "") -> void:
	if audio_click:
		audio_click.play()

	checkpoint_title.text = "★ CHECKPOINT REACHED! ★"
	checkpoint_subtext.text = "RESPAWN POINT SAVED!"

	if checkpoint_banner_tween and checkpoint_banner_tween.is_valid():
		checkpoint_banner_tween.kill()

	checkpoint_banner.show()
	checkpoint_banner.modulate.a = 0.0

	checkpoint_banner_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	checkpoint_banner_tween.tween_property(checkpoint_banner, "modulate:a", 1.0, 0.2)
	checkpoint_banner_tween.tween_interval(1.8)
	checkpoint_banner_tween.tween_property(checkpoint_banner, "modulate:a", 0.0, 0.4)
	checkpoint_banner_tween.tween_callback(checkpoint_banner.hide)


# --- FINISH LINE BLOCKED (REMAINING COINS PROMPT) ---
func _on_finish_line_blocked(remaining_coins: int, total_coins: int) -> void:
	finish_warning_title.text = "COLLECT ALL COINS TO WIN!"
	finish_warning_subtext.text = "Only %d of %d collected! Go collect the remaining %d coin%s!" % [
		Globals.score, total_coins, remaining_coins, ("s" if remaining_coins > 1 else "")
	]

	if warning_banner_tween and warning_banner_tween.is_valid():
		warning_banner_tween.kill()

	finish_warning_banner.show()
	finish_warning_banner.modulate.a = 0.0

	warning_banner_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	warning_banner_tween.tween_property(finish_warning_banner, "modulate:a", 1.0, 0.2)
	warning_banner_tween.tween_interval(2.6)
	warning_banner_tween.tween_property(finish_warning_banner, "modulate:a", 0.0, 0.4)
	warning_banner_tween.tween_callback(finish_warning_banner.hide)


# --- HEALTH LOSS & RESPAWN BANNER ---
func _on_health_lost(remaining_health: int) -> void:
	update_hud()

	health_lost_text.text = "YOU LOST 1 HEALTH!"
	var hearts := ""
	for i in range(remaining_health):
		hearts += "❤ "
	for i in range(5 - remaining_health):
		hearts += "♡ "
	health_lost_subtext.text = hearts.strip_edges() + " (" + str(remaining_health) + " REMAINING)"

	if health_banner_tween and health_banner_tween.is_valid():
		health_banner_tween.kill()

	health_lost_banner.show()
	health_lost_banner.modulate.a = 0.0

	health_banner_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	health_banner_tween.tween_property(health_lost_banner, "modulate:a", 1.0, 0.2)
	health_banner_tween.tween_interval(1.6)
	health_banner_tween.tween_property(health_lost_banner, "modulate:a", 0.0, 0.4)
	health_banner_tween.tween_callback(health_lost_banner.hide)


# --- VICTORY SCREEN ---
func _on_game_won() -> void:
	get_tree().paused = true

	victory_score_label.text = "ALL %d / %d COINS COLLECTED!" % [Globals.score, Globals.total_coins]

	var hearts := ""
	for i in range(Globals.health):
		hearts += "❤ "
	for i in range(5 - Globals.health):
		hearts += "♡ "
	victory_health_label.text = "LIVES REMAINING: " + hearts.strip_edges() + " (" + str(Globals.health) + ")"

	victory_screen.show()
	victory_screen.modulate.a = 0.0

	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(victory_screen, "modulate:a", 1.0, 0.35)

	victory_play_again_button.grab_focus()


# --- GAME OVER & PLAY AGAIN ---
func _on_game_over() -> void:
	get_tree().paused = true

	final_score_label.text = "FINAL SCORE: " + str(Globals.score) + " / " + str(Globals.total_coins)

	game_over_screen.show()
	game_over_screen.modulate.a = 0.0

	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(game_over_screen, "modulate:a", 1.0, 0.35)

	play_again_button.grab_focus()


func _on_play_again_pressed() -> void:
	Globals.reset()
	Globals.just_restarted = true

	get_tree().paused = false
	get_tree().reload_current_scene()
