extends Node


@export var speed = 1.0

var enimy: Enimy
var sprite: AnimatedSprite2D


func _ready():
	enimy = get_parent()
	sprite = enimy.get_node("AnimatedSprite2D")


func _physics_process(delta):

	var player_position = GameMenager.player_position
	var difference = player_position - enimy.position
	var Input_vector = difference.normalized()

	enimy.velocity = Input_vector * speed * 100.0
	enimy.move_and_slide()

	if Input_vector.x > 0:
		sprite.flip_h = false
	elif Input_vector.x < 0:
		sprite.flip_h = true
