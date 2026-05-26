extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	squat,
	downswing,
	hurt
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var colisao_agachado: CollisionShape2D = $ColisaoAgachado
@onready var colisao_em_pe: CollisionShape2D = $ColisaoEmPe
@onready var reload_timer: Timer = $ReloadTimer
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D


@export var max_speed = 100
@export var acceleration = 500
@export var deceleration = 300
const JUMP_VELOCITY = -300.0

var direction = 0
var status: PlayerState
var atacando = true

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.squat:
			squat_state(delta)
		PlayerState.downswing:
			downswing_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
	
	move_and_slide()

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")
	
func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")
	
func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	
func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	
func go_to_squat_state():
	status = PlayerState.squat
	anim.play("squat")
	colisao_em_pe.disabled = true
	colisao_agachado.disabled = false
	
func exit_from_squat_state():
	colisao_agachado.disabled = true
	colisao_em_pe.disabled = false
	
func go_to_downswing_state():
	status = PlayerState.downswing
	anim.play("downswing")
	
	# Compensa a diferença de tamanho da arte puxando o eixo Y do sprite para cima
	# (Ajuste esse valor -10 até o pé ficar alinhado com o chão)
	anim.offset.y = -8

	# O personagem encolhe durante o golpe, ativamos a colisão menor
	colisao_em_pe.disabled = true
	colisao_agachado.disabled = false

	# Se quiser que ele freie no momento do ataque no chão:
	if is_on_floor():
		velocity.x = 0
		
	hitbox_collision_shape.shape.size.y = 28
	hitbox_collision_shape.position.y = 1.0
		
func exit_from_downswing_state():
	# Retorna à colisão padrão ao fim do ataque
	colisao_agachado.disabled = true
	colisao_em_pe.disabled = false

	# Zera o offset para o personagem não ficar flutuando nas outras animações
	anim.offset.y = 0
	
	hitbox_collision_shape.shape.size.y = 30
	hitbox_collision_shape.position.y = 0.0
	
func go_to_hurt_state():
	if status == PlayerState.hurt:
		return
	status = PlayerState.hurt
	anim.play("hurt")
	velocity.x = 0
	reload_timer.start()
	
func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return 
		
	if Input.is_action_pressed("squat"):
		go_to_squat_state()
		return
		
	if Input.is_action_just_pressed("attack"):
		go_to_downswing_state()
		return
	
func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if Input.is_action_just_pressed("attack"):
		go_to_downswing_state()
		return
		
	if !is_on_floor():
		go_to_fall_state()
		return
	
func jump_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("attack"):
		go_to_downswing_state()
		return
	
	if velocity.y > 0:
		go_to_fall_state()
		return
		
func fall_state(delta):
	move(delta)
	
	if is_on_floor():
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
		
func squat_state(_delta):
	update_direction()
	if Input.is_action_just_released("squat"):
		exit_from_squat_state()
		go_to_idle_state()
		return
			
func downswing_state(delta):
	# Mantém a física rodando (gravidade e inércia do movimento)
	move(delta)
	
	# Verifica se a animação atual chegou ao fim
	# (Isso só funciona se o Loop da animação estiver DESLIGADO no editor)
	if not anim.is_playing() or anim.animation != "downswing":
		
		exit_from_downswing_state()
		
		# Decide para onde ir após o golpe terminar
		if is_on_floor():
			if velocity.x == 0:
				go_to_idle_state()
			else:
				go_to_walk_state()
		else:
			go_to_fall_state()

func hurt_state(_delta):
	# Só tomar dano se NÃO estiver atacando
	if not atacando:
		# Lógica para o personagem morrer
		print("Personagem morreu!")

func move(delta):
	update_direction()
		
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func update_direction():
	direction = Input.get_axis("left", "right")
	
	if direction <0:
		anim.flip_h = true
		# Inverte a Hitbox para a esquerda ao andar para trás
		$Hitbox.scale.x = -1
	elif direction > 0:
		anim.flip_h = false
		# Mantém a Hitbox para a direita ao andar para frente 
		$Hitbox.scale.x = 1
	 
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		# Se a Hitbox tocar no osso e o Player ESTIVER atacando:
		if status == PlayerState.downswing:
			area.queue_free() # Destrói o projétil (rebate a magia!)
		# Se o projétil encostar na espada, mas o Player NÃO estiver atacando:
		else:
			hit_lethal_area()
			
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_hurt_state()
	
func hit_enemy(area: Area2D):
	# Verifica se o jogador está executando o ataque com a espada (tecla X)
	if status == PlayerState.downswing:
		# Inimigo morre/toma dano
		area.get_parent().take_damage()
	else:
		# Se encostar no inimigo sem estar atacando, o Player toma dano
		go_to_hurt_state()
	
func hit_lethal_area():
	go_to_hurt_state()

func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()	

func _on_animated_sprite_2d_animation_finished() -> void:
	atacando = false
	
