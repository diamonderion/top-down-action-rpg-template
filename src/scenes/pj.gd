extends KinematicBody2D

class_name Player

export(int) var WALK_SPEED = 350
export(int) var ROLL_SPEED = 1000

var linear_vel = Vector2()
var roll_direction = Vector2.DOWN

export(String, "up", "down", "left", "right") var facing = "down"

var anim = ""
var new_anim = ""

enum { STATE_BLOCKED, STATE_IDLE, STATE_WALKING, STATE_ATTACK, STATE_ROLL }

var state = STATE_IDLE

# Called when the node enters the scene tree for the first time.
func _ready():
	var spawnpoints = get_tree().get_nodes_in_group("spawnpoints")
	for spawnpoint in spawnpoints:
		if spawnpoint.name == Globals.spawnpoint:
			global_position = spawnpoint.global_position
	Dialogs.connect("dialog_started", self, "_on_dialog_started")
	Dialogs.connect("dialog_ended", self, "_on_dialog_ended")
	pass # Replace with function body.

func _physics_process(_delta):
	
	## PROCESS STATES
	match state:
		STATE_BLOCKED:
			new_anim = "idle_" + facing
			pass
		STATE_IDLE:
			if (
					Input.is_action_pressed("move_down") or
					Input.is_action_pressed("move_left") or
					Input.is_action_pressed("move_right") or
					Input.is_action_pressed("move_up")
				):
					state = STATE_WALKING
			if Input.is_action_just_pressed("attack"):
				state = STATE_ATTACK
			if Input.is_action_just_pressed("roll"):
				state = STATE_ROLL
				roll_direction = Vector2(
						- int( Input.is_action_pressed("move_left") ) + int( Input.is_action_pressed("move_right") ),
						-int( Input.is_action_pressed("move_up") ) + int( Input.is_action_pressed("move_down") )
					).normalized()
				_update_facing(roll_direction)
			new_anim = "idle_" + facing
			pass
		STATE_WALKING:
			if Input.is_action_just_pressed("attack"):
				state = STATE_ATTACK
			if Input.is_action_just_pressed("roll"):
				state = STATE_ROLL
			
			linear_vel = move_and_slide(linear_vel)
			
			var target_speed = Vector2()
			
			if Input.is_action_pressed("move_down"):
				target_speed += Vector2.DOWN
			if Input.is_action_pressed("move_left"):
				target_speed += Vector2.LEFT
			if Input.is_action_pressed("move_right"):
				target_speed += Vector2.RIGHT
			if Input.is_action_pressed("move_up"):
				target_speed += Vector2.UP
			
			target_speed *= WALK_SPEED
			linear_vel = linear_vel.linear_interpolate(target_speed, 0.1)
			roll_direction = linear_vel.normalized()
			
			_update_facing(linear_vel)
			
			if linear_vel.length() > 5:
				new_anim = "walk_" + facing
			else:
				goto_idle()
			pass
		STATE_ATTACK:
			new_anim = "slash_" + facing
			pass
		STATE_ROLL:
			if roll_direction == Vector2.ZERO:
				state = STATE_IDLE
			else:
				linear_vel = move_and_slide(linear_vel)
				var target_speed = Vector2()
				target_speed = roll_direction
				target_speed *= ROLL_SPEED
				linear_vel = linear_vel.linear_interpolate(target_speed, 0.9)
				new_anim = "roll"
			pass
	
	## UPDATE ANIMATION
	if new_anim != anim:
		anim = new_anim
		$anims.play(anim)
	pass


func _on_dialog_started():
	state = STATE_BLOCKED

func _on_dialog_ended():
	state = STATE_IDLE


## HELPER FUNCS
func goto_idle():
	linear_vel = Vector2.ZERO
	new_anim = "idle_" + facing
	state = STATE_IDLE

func _update_facing(direction_vector):
	if abs(direction_vector.x) > abs(direction_vector.y):
		if direction_vector.x < 0:
			facing = "left"
		if direction_vector.x > 0:
			facing = "right"
	if abs(direction_vector.y) >= abs(direction_vector.x):
		if direction_vector.y < 0:
			facing = "up"
		if direction_vector.y > 0:
			facing = "down"
