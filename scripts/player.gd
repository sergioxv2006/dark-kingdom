extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 90.0
const JUMP_VELOCITY = -300.0

func _physics_process(delta: float) -> void:
	# Adiciona a gravidade.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Gerencia o pulo e a descida de plataformas.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		# Verifica se a tecla para baixo está pressionada ("ui_down" é o padrão, mude para "down" se você criou uma ação própria)
		if Input.is_action_pressed("down"):
			position.y += 2 # Desloca o personagem para baixo para ignorar a colisão temporariamente
		else:
			velocity.y = JUMP_VELOCITY

	# As good practice, you should replace UI actions with custom gameplay actions.
	# Pega a direção do input e gerencia o movimento.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Gerencia as animações
	if is_on_floor():
		if direction > 0:
			anim.flip_h = false
			anim.play("walk")
		elif direction < 0:
			anim.flip_h = true
			anim.play("walk")
		else:
			anim.play("idle")
	else:
		anim.play("jump")
	move_and_slide()
