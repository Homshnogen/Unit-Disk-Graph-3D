extends Node

const STATE_PAUSED := 0
const STATE_AUTO := 1
const STATE_INSTANT := 2
var state := STATE_AUTO
var idle_spin := 0.00

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if (Input.is_action_just_pressed("pause_state")) :
		state = STATE_PAUSED
	elif Input.is_action_just_pressed("auto_state") :
		state = STATE_AUTO
	elif Input.is_action_just_pressed("instant_state") :
		state = STATE_INSTANT
