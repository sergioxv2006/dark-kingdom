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
@onready var som_pulo: AudioStreamPlayer2D = $SomPulo
@onready var som_derrota: AudioStreamPlayer2D = $SomDerrota
@onready var som_ataque: AudioStreamPlayer2D = $SomAtaque
@onready var som_dano: AudioStreamPlayer2D = $SomDano
@onready var vidas_ui = $HUD/VidasUI # Pega a referência do contêiner de coraçõea
@onready var tempo_invulneravel: Timer = $TempoInvulneravel

@export var vidas_maximas = 3
var vidas_atuais = 3

@export var max_speed = 100
@export var acceleration = 500
@export var deceleration = 300
const JUMP_VELOCITY = -300.0

var direction = 0
var status: PlayerState
var atacando = false

func _ready() -> void:
	vidas_atuais = vidas_maximas
	go_to_idle_state()

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Morte por queda: Se a posição Y passar de um certo valor (ex: 1000)
	# Ajuste esse "1000" dependendo da profundidade da sua fase
	if global_position.y > 1000:
		if vidas_atuais > 0:
			morte_instantanea()
	
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
	som_pulo.play() # Toca o som do pulo
	
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
	
	som_ataque.play() # Toca o som da espadada
		
func exit_from_downswing_state():
	# Retorna à colisão padrão ao fim do ataque
	colisao_agachado.disabled = true
	colisao_em_pe.disabled = false

	# Zera o offset para o personagem não ficar flutuando nas outras animações
	anim.offset.y = 0
	
	hitbox_collision_shape.shape.size.y = 30
	hitbox_collision_shape.position.y = 0.0
	
func go_to_hurt_state():
	# 1. A BARREIRA DE AÇO: Se o timer ainda está rodando, IGNORA o dano totalmente!
	if not tempo_invulneravel.is_stopped():
		return
	
	# Se o jogo passar daqui, significa que pode tomar dano. Inicia o relógio!
	tempo_invulneravel.start() 
	
	# Desconta apenas 1 vida com segurança
	vidas_atuais = -1
	
	# Mensagem de debug para você ver no console:
	print("Tomou 1 hit do inimigo! Vidas restantes: ", vidas_atuais)
	
	atualizar_ui_vidas() # Chama a função que apaga o coração
	
	status = PlayerState.hurt
	anim.play("hurt")
	
	if vidas_atuais <= 0:
		# Se acabou a vida, toca o som de derrota e morre
		som_derrota.play()
		velocity.x = 0
		reload_timer.start()
		# (O timer vai reiniciar a cena quando acabar)
	else:
		# Tomou dano, mas continua vivo.
		# Aplica um "Knockback" (empurrão) para trás para tirá-lo de dentro do inimigo
		velocity.y = -200
		velocity.x = -150 if not anim.flip_h else 150
		som_dano.play()
		
		# Efeito de piscar (50% transparente)
		anim.modulate.a = 0.5
		
		# Espera 1.5 segundos de segurança para acabar a invulnerabilidade
		await get_tree().create_timer(1.5).timeout
		
		# Retorna ao normal
		anim.modulate.a = 1.0
		
func _on_animated_sprite_2d_animation_finished() -> void:
	atacando = false
	
	# Se a animação de dano terminar e ele ainda tiver vida, volta pro idle
	if anim.animation == "hurt" and vidas_atuais > 0:
		go_to_idle_state()

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
	if area.is_in_group("MorteInstantanea"):
		morte_instantanea()
		return
		
	# PRIORIDADE 1: Avaliar os projéteis antes do inimigos
	if area.is_in_group("LethalArea"):
		if status == PlayerState.downswing:
			# REBATEU O PROJÉTIL!
			# O set_deferred desliga a colisão na mesma hora para evitar o "dano fantasma"
			area.set_deferred("monitoring", false)
			area.queue_free()
		else:
			go_to_hurt_state()
			area.set_deferred("monitoring", false)
			area.queue_free() # Destrói o osso aqui também para não dar hit duplo!
		return # O return garante que ele não vai tentar rodar o código de baixo
		
	# PRIORIDADE 2: Bater no corpo do inimigo
	if area.is_in_group("Enemies"):
		hit_enemy(area)
			
func _on_hitbox_body_entered(body: Node2D) -> void:
	# Agora ele detecta se a Lava (TileMap ou StaticBody) tem o grupo MorteInstantanea
	if body.is_in_group("MorteInstantanea"):
		morte_instantanea()
		return
	
	if body.is_in_group("LethalArea"):
		# Se o projétil for um Body ao invés de Area, a defesa funciona aqui também
		if status == PlayerState.downswing:
			body.queue_free()
		else:
			go_to_hurt_state()
			body.queue_free()
	
func hit_enemy(area: Area2D):
	# Verifica se o jogador está executando o ataque com a espada (tecla X)
	if status == PlayerState.downswing:
		# Inimigo morre/toma dano
		area.get_parent().take_damage()
	else:
			go_to_hurt_state()
	
func hit_lethal_area():
		go_to_hurt_state()

func _on_reload_timer_timeout() -> void:
	if vidas_atuais <= 0:
		get_tree().reload_current_scene()	
	else:
		go_to_idle_state() # Volta ao normal após tomar um hit
	
func atualizar_ui_vidas():
	# Conta de trás para frente e esconde o coração correspondente
	var coracoes = vidas_ui.get_children()
	for i in range(coracoes.size()):
		if i < vidas_atuais:
			coracoes[i].show() # Mantém visível se tem a vida
		else:
			coracoes[i].hide() # Esconde se perdeu a vida 

func morte_instantanea():
	# Se já está no estado de dano, não faz nada para não repetir
	if status == PlayerState.hurt:
		return
	
	# Zera a vida e atualiza os corações
	vidas_atuais = 0
	atualizar_ui_vidas()
	
	# Executa a morte de forma independente
	som_derrota.play()
	status = PlayerState.hurt
	anim.play("hurt")
	velocity.x = 0
	
	# Inicia o tempo para resnacer
	reload_timer.start()
	
	
	
