extends CharacterBody2D

@export var geschwindigkeit: float = 150.0
@export var gravitation: float = 400.0
@export var fall_multiplier: float = 2.5
@export var klettern_geschwindigkeit: float = 100.0
@export var klettern_seitlich: float = 50.0
@export var klettern_beschleunigung: float = 800.0


var klettern_sperre: float = 0.0

var angriffs_index: int = 0
var gestorben: bool = false

var gegner_im_bereich: Array[Node2D] = []
var gegner_bereits_getroffen: Array[Node2D] = []

var flying_random: bool = false
var fly_velocity: Vector2 = Vector2.ZERO
var fly_speed: float = 300.0
var fly_timer: float = 0.0
var fly_change_interval: float = 0.2

var spawn: Vector2

var coyote_time: float = 0.15
var coyote_time_left: float = 0.0


func _ready() -> void:
	$SpielerSprite.animation_finished.connect(_animation_fertig)

	spawn = position


func Spring() -> void:
	var Sprunghoehe: float = 140.0
	Sprunghoehe = _update_internal_value(Sprunghoehe)

	velocity.y = -Sprunghoehe
	Global.springt = true

	$SpielerSprite.play("springen")


func _process(_delta: float) -> void:
	if Global.tot and not gestorben:
		$SpielerSprite.play("sterben")
		gestorben = true

		await get_tree().create_timer(3.0).timeout

		respawn()

	if Global.angreift:
		for gegner in gegner_im_bereich:
			if not Global.gegner_getroffen.has(gegner) and not gegner_bereits_getroffen.has(gegner):
				Global.gegner_getroffen.append(gegner)
				gegner_bereits_getroffen.append(gegner)


func _physics_process(delta: float) -> void:
	if Global.win:
		winMovement(delta)
		return

	if Global.tot:
		Global.klettert = false
		velocity.y = 100.0
		velocity.x = 0.0
		move_and_slide()
		return

	klettern_sperre = max(klettern_sperre - delta, 0.0)
	var vertikal_input: float = Input.get_axis("move_up", "move_down")

	if Global.klettert:
		if Global.leitern == 0 or (is_on_floor() and vertikal_input > 0.0):
			Global.klettert = false
	elif Global.leitern > 0 and klettern_sperre <= 0.0 and not Global.angreift:
		if vertikal_input < 0.0 or (vertikal_input > 0.0 and not is_on_floor()):
			Global.klettert = true
			Global.springt = false
			velocity = Vector2.ZERO

	if Global.klettert:
		klettern(delta, vertikal_input)
		return

	# Coyote Time
	if is_on_floor():
		coyote_time_left = coyote_time
	else:
		coyote_time_left = max(coyote_time_left - delta, 0.0)

	# Gravitation
	if velocity.y > 0.0:
		velocity.y += gravitation * fall_multiplier * delta
	else:
		velocity.y += gravitation * delta

	# Variable jump height
	if velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		velocity.y = move_toward(
			velocity.y,
			0.0,
			delta * 1200.0
		)

	# Horizontal movement
	if Global.angreift:
		velocity.x = 0.0
	else:
		horizontal_bewegung()

	# Animation
	if not Global.angreift:
		spieler_animation()

	# Apply movement
	move_and_slide()

	# Reset jump state after landing
	if is_on_floor() and Global.springt:
		Global.springt = false


func respawn() -> void:
	Global.tot = false
	gestorben = false
	position = spawn


func _input(event: InputEvent) -> void:
	if Global.tot:
		return

	# Attack
	if event.is_action_pressed("attack") and is_on_floor() and not Global.angreift:
		Global.angreift = true
		$AngriffKollision.monitoring = true

		if angriffs_index == 0:
			$SpielerSprite.play("angreifen_1")
		else:
			$SpielerSprite.play("angreifen_2")

		angriffs_index = 1 - angriffs_index

	# Jump (also allowed from a ladder)
	if event.is_action_pressed("jump") and (coyote_time_left > 0.0 or Global.klettert):
		if Global.klettert:
			Global.klettert = false
			klettern_sperre = 0.3
		Spring()
		coyote_time_left = 0.0


func klettern(delta: float, vertikal_input: float) -> void:
	var horizontal_input: float = Input.get_axis("move_left", "move_right")
	var ziel := Vector2(
		horizontal_input * klettern_seitlich,
		vertikal_input * klettern_geschwindigkeit
	)
	velocity = velocity.move_toward(ziel, klettern_beschleunigung * delta)

	# Lets the player still jump right after climbing off the top
	coyote_time_left = coyote_time

	if horizontal_input != 0.0:
		$SpielerSprite.flip_h = horizontal_input < 0.0

	if ziel != Vector2.ZERO:
		$SpielerSprite.play("klettern_seite")
	else:
		$SpielerSprite.pause()

	move_and_slide()


func horizontal_bewegung() -> void:
	# -1.0 = left
	#  0.0 = nothing
	#  1.0 = right
	var horizontal_input: float = Input.get_axis(
		"move_left",
		"move_right"
	)

	if is_on_floor():
		velocity.x = horizontal_input * geschwindigkeit
	else:
		var air_control_factor: float = 0.5
		velocity.x = horizontal_input * geschwindigkeit * air_control_factor

func spieler_animation() -> void:
	var horizontal_input: float = Input.get_axis(
		"move_left",
		"move_right"
	)

	if horizontal_input < 0.0:
		$SpielerSprite.flip_h = true

		if not Global.springt:
			$SpielerSprite.play("rennen")

	elif horizontal_input > 0.0:
		$SpielerSprite.flip_h = false

		if not Global.springt:
			$SpielerSprite.play("rennen")

	elif is_on_floor() and not Global.springt:
		$SpielerSprite.play("stehen")


func _animation_fertig() -> void:
	var anim: StringName = $SpielerSprite.animation

	if anim == "angreifen_1" or anim == "angreifen_2":
		Global.angreift = false
		gegner_bereits_getroffen.clear()


func _on_angriff_kollision_body_entered(body: Node2D) -> void:
	if body.is_in_group("Gegner") and not gegner_im_bereich.has(body):
		gegner_im_bereich.append(body)


func _on_angriff_kollision_body_exited(body: Node2D) -> void:
	if body.is_in_group("Gegner") and gegner_im_bereich.has(body):
		gegner_im_bereich.erase(body)


func _update_internal_value(v: float) -> float:
	if v > 200.0:
		return 200.0

	return v


func winMovement(delta: float) -> void:
	if not flying_random:
		flying_random = true

		fly_velocity = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * fly_speed

		fly_timer = fly_change_interval

	fly_timer -= delta

	if fly_timer <= 0.0:
		fly_velocity = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized() * fly_speed

		fly_timer = fly_change_interval

	var jitter := Vector2(
		randf_range(-0.5, 0.5),
		randf_range(-0.5, 0.5)
	) * 50.0

	fly_velocity += jitter
	fly_velocity = fly_velocity.limit_length(fly_speed)

	position += fly_velocity * delta

	$SpielerSprite.play("FlyAround")
