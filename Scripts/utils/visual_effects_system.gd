extends RefCounted
class_name VisualEffectsSystem

# Общая система визуальных эффектов для игровых объектов

# ========== ЭФФЕКТЫ УРОНА ==========

static func show_damage_effect(sprite: Sprite2D, damage_color: Color = Color.RED, duration: float = 0.2):
	"""Показывает эффект получения урона"""
	if not sprite:
		return
	
	# Сохраняем оригинальный цвет
	var original_modulate = sprite.modulate
	
	# Меняем цвет на цвет урона
	sprite.modulate = damage_color
	
	# Создаем таймер для возврата цвета
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if sprite and is_instance_valid(sprite):
			sprite.modulate = original_modulate
		timer.queue_free()
	)
	
	# Добавляем таймер к спрайту
	sprite.add_child(timer)
	timer.start()

static func show_grappling_effect(sprite: Sprite2D, glow_color: Color = Color.CYAN, duration: float = 0.5):
	"""Показывает эффект зацепления крюком"""
	if not sprite:
		return
	
	# Сохраняем оригинальный цвет
	var original_modulate = sprite.modulate
	
	# Применяем свечение
	sprite.modulate = glow_color
	
	# Создаем таймер для возврата цвета
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if sprite and is_instance_valid(sprite):
			sprite.modulate = original_modulate
		timer.queue_free()
	)
	
	# Добавляем таймер к спрайту
	sprite.add_child(timer)
	timer.start()

# ========== ЭФФЕКТЫ МЕРЦАНИЯ ==========

static func create_blinking_effect(sprite: Sprite2D, blink_count: int = 3, blink_duration: float = 0.1):
	"""Создает эффект мерцания спрайта"""
	if not sprite:
		return
	
	var original_modulate = sprite.modulate
	
	# Создаем объект-счетчик для корректной работы с лямбдой
	var blink_counter = BlinkCounter.new()
	blink_counter.remaining = blink_count * 2  # Умножаем на 2 для включения/выключения
	
	var blink_timer = Timer.new()
	blink_timer.wait_time = blink_duration
	blink_timer.timeout.connect(func():
		if sprite and is_instance_valid(sprite):
			# Переключаем видимость
			sprite.modulate.a = 1.0 if sprite.modulate.a < 0.5 else 0.3
			blink_counter.remaining -= 1
			
			if blink_counter.remaining <= 0:
				# Восстанавливаем оригинальный цвет и удаляем таймер
				sprite.modulate = original_modulate
				blink_timer.queue_free()
	)
	
	sprite.add_child(blink_timer)
	blink_timer.start()

static func create_continuous_blinking_effect(sprite: Sprite2D, blink_duration: float = 0.3):
	"""Создает постоянный эффект мерцания спрайта"""
	if not sprite:
		return
	
	# Проверяем, не мерцает ли уже спрайт
	var existing_timer = sprite.get_node_or_null("ContinuousBlinkTimer")
	if existing_timer:
		existing_timer.queue_free()  # Удаляем старый таймер
	
	# Сохраняем ТЕКУЩЕЕ состояние спрайта как базовое
	var base_modulate = sprite.modulate
	var is_bright = true
	
	var blink_timer = Timer.new()
	blink_timer.name = "ContinuousBlinkTimer"
	blink_timer.wait_time = blink_duration
	blink_timer.timeout.connect(func():
		if sprite and is_instance_valid(sprite):
			# Сохраняем текущую альфу (для работы с исчезновением)
			var current_alpha = sprite.modulate.a
			# Переключаем яркость относительно базового состояния, но сохраняем альфу
			if is_bright:
				sprite.modulate = Color(base_modulate.r * 0.3, base_modulate.g * 0.3, base_modulate.b * 0.3, current_alpha)
			else:
				sprite.modulate = Color(base_modulate.r, base_modulate.g, base_modulate.b, current_alpha)
			is_bright = not is_bright
	)
	
	sprite.add_child(blink_timer)
	blink_timer.start()

static func stop_continuous_blinking_effect(sprite: Sprite2D):
	"""Останавливает постоянное мерцание спрайта"""
	if not sprite:
		return
	
	var blink_timer = sprite.get_node_or_null("ContinuousBlinkTimer")
	if blink_timer:
		blink_timer.queue_free()

# Вспомогательный класс для счетчика мерцаний
class BlinkCounter:
	var remaining: int = 0

# ========== ЭФФЕКТЫ УНИЧТОЖЕНИЯ ==========

static func create_destruction_particles(parent: Node, position: Vector2, color: Color = Color.ORANGE, particle_count: int = 40):
	"""Создает эффект частиц при уничтожении"""
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = particle_count
	particles.lifetime = 2.0
	particles.speed_scale = 3.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 2.0
	particles.color = color
	
	# Добавляем частицы в родительскую сцену
	parent.add_child(particles)
	particles.global_position = position
	
	# Удаляем частицы через некоторое время
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 3.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): 
		if particles and is_instance_valid(particles):
			particles.queue_free()
	)
	particles.add_child(cleanup_timer)
	cleanup_timer.start()

# ========== ЭФФЕКТЫ ЛЕЧЕНИЯ ==========

static func show_heal_effect(sprite: Sprite2D, heal_color: Color = Color.GREEN, duration: float = 0.3):
	"""Показывает эффект лечения"""
	show_damage_effect(sprite, heal_color, duration)

# ========== ЭФФЕКТЫ УСИЛЕНИЯ ==========

static func show_power_up_effect(sprite: Sprite2D, power_color: Color = Color.YELLOW, duration: float = 0.4):
	"""Показывает эффект усиления"""
	show_damage_effect(sprite, power_color, duration)

# ========== УТИЛИТАРНЫЕ МЕТОДЫ ==========

static func safe_add_timer_to_node(node: Node, timer: Timer):
	"""Безопасно добавляет таймер к узлу"""
	if node and is_instance_valid(node):
		node.add_child(timer)
	else:
		timer.queue_free()

static func get_damage_color_by_type(damage_type: String) -> Color:
	"""Возвращает цвет эффекта в зависимости от типа урона"""
	match damage_type:
		"laser":
			return Color.RED
		"explosion":
			return Color.ORANGE
		"collision":
			return Color.YELLOW
		"energy":
			return Color.CYAN
		_:
			return Color.RED

static func get_glow_color_by_state(state: String) -> Color:
	"""Возвращает цвет свечения в зависимости от состояния объекта"""
	match state:
		"grappled":
			return Color.CYAN
		"moving":
			return Color.ORANGE
		"idle":
			return Color.YELLOW
		"damaged":
			return Color.RED
		"healed":
			return Color.GREEN
		_:
			return Color.WHITE 
