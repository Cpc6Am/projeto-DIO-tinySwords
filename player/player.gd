class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var speed = 3
@export_category("Sword")
@export var sword_damage: int = 2
@export_category("Ritual")
@export var ritual_damage: int = 1
@export var ritual_interval: float = 30
@export var ritual_scene: PackedScene
@export_category("Life")
@export var health: int = 50
@export var max_health: int = 50
@export var death_prefab: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

var Input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var ritual_cooldown: float = 0.0


signal meat_collected(volue:int)


func _ready():

	GameMenager.player = self


func _process(delta):

	GameMenager.player_position = position

	read_input()

	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack()

	play_run_idle_animation()
	if not is_attacking:
		rotate_sprite()

	update_hitbox_detection(delta)

	update_ritual(delta)

	health_progress_bar.max_value = max_health
	health_progress_bar.value = health


func _physics_process(delta):

	var target_velocity = Input_vector * speed * 100.0
	if is_attacking:
		target_velocity *= 0.20
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()


func update_attack_cooldown(delta):

	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")


func update_ritual(delta):

	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	ritual_cooldown = ritual_interval

	var ritual = ritual_scene.instantiate()
	ritual.damage_amount = ritual_damage
	add_child(ritual)


func read_input():

	Input_vector = Input.get_vector("move_left","move_right","move_up","move_down")

	was_running = is_running
	is_running = not Input_vector.is_zero_approx()


func play_run_idle_animation():

	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")


func rotate_sprite():

	if Input_vector.x > 0:
		sprite.flip_h = false
	elif Input_vector.x < 0:
		sprite.flip_h = true

func attack():

	if is_attacking:
		return

	animation_player.play("attack_side_1")

	attack_cooldown = 0.6

	is_attacking = true


func deal_damage_to_enimies():

	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enimies"):
			var enimy: Enimy = body
			
			var direction_to_enimy = (enimy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			var dot_product = direction_to_enimy.dot(attack_direction)
			if dot_product >= 0.4:
				enimy.damage(sword_damage)


func update_hitbox_detection(delta):

	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return

	hitbox_cooldown = 0.5

	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enimies"):
			var enimy: Enimy = body
			var damage_amount = 1
			damage(damage_amount)


func damage(amount: int):

	if health <= 0: return

	health -= amount

	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

	if health <= 0:
		die()


func die():

	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)

	queue_free()


func heal(amount: int):

	health += amount
	if health > max_health:
		health = max_health
	return health
