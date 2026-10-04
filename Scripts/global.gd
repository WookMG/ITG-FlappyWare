extends Node

#Some signals that fire based on certain events. Other functions are called when these fire.
signal start_game
signal scored
signal end_game
signal restart_game

#Speed of bird used to move other objects.
#Note that we must SUBTRACT this speed from current position to get movement.
const MAX_BIRD_SPEED = 5
var bird_speed = 5

#Scores tracked throughout the game
var score = 0
var high_score = 0

#States the game can be in.
# IDLE is before the game has started
# PLAYING is while the bird is able to control itself
# DEAD is when you have died and need to restart
enum States{
	Idle,
	Playing,
	Dead,
}
var current_state : States = States.Idle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	end_game.connect(on_end_game)
	restart_game.connect(on_restart_game)
	start_game.connect(on_start_game)

func on_start_game():
	current_state = States.Playing

func on_end_game():
	if current_state != States.Dead: #Ensures end only fires once
		current_state = States.Dead
		await zero_bird_speed().finished #this waits for bird_speed variable to zero out before continuing
		while true:
			if Input.is_action_just_pressed("Jump"):
				break
			await get_tree().process_frame
		Global.restart_game.emit()
	
	
func on_restart_game():
	await BlackScreen.fade_black_in().finished
	get_tree().reload_current_scene()
	current_state = States.Idle
	bird_speed = MAX_BIRD_SPEED
	BlackScreen.fade_black_out()
	
	
func zero_bird_speed():
	var tween = create_tween()
	tween.tween_property(self, "bird_speed", 0, 1.5)
	return tween
