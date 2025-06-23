extends GPUParticles2D

class_name JetpackSmoke

# Параметры эффекта
@export var max_intensity: float = 1.0
@export var min_velocity: float = 50.0
@export var max_velocity: float = 150.0
@export var smoke_color: Color = Color(0.7, 0.7, 0.7, 0.6)

# Внутренние переменные
var particle_material: ParticleProcessMaterial
var current_intensity: float = 0.0
var last_velocity: Vector2 = Vector2.ZERO
var direction_change_timer: float = 0.0

func _ready():
	setup_smoke_particles()

func setup_smoke_particles():
	# Основные параметры частиц
	amount = 80
	lifetime = 3.0
	emitting = false
	
	# Создаем материал процесса
	particle_material = ParticleProcessMaterial.new()
	process_material = particle_material
	
	# Пытаемся загрузить текстуру дыма
	var smoke_texture_path = "res://Assets/Textures/Effects/smoke_particle.png"
	if ResourceLoader.exists(smoke_texture_path):
		texture = load(smoke_texture_path)
	else:
		# Используем стандартную текстуру Godot, если наша не найдена
		print("Текстура дыма не найдена, используется стандартная")
	
	# Настройка направления и скорости (начальное направление - вниз)
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.initial_velocity_min = min_velocity
	particle_material.initial_velocity_max = max_velocity
	particle_material.angular_velocity_min = -180.0
	particle_material.angular_velocity_max = 180.0
	
	# Физические свойства
	particle_material.gravity = Vector3(0, -20, 0)  # Слабая гравитация вверх
	particle_material.linear_accel_min = -10.0
	particle_material.linear_accel_max = -30.0
	
	# Размер и масштабирование
	particle_material.scale_min = 0.4
	particle_material.scale_max = 1.5
	particle_material.scale_over_velocity_min = 0.0
	particle_material.scale_over_velocity_max = 0.3
	
	# Цвет и прозрачность
	particle_material.color = smoke_color
	
	# Увеличиваем разброс для более естественного вида
	particle_material.spread = 35.0
	particle_material.flatness = 0.0
	
	# Затухание со временем
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 0.8))
	gradient.add_point(0.3, Color(1, 1, 1, 0.6))
	gradient.add_point(0.8, Color(1, 1, 1, 0.3))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	
	# В Godot 4 используем color_ramp вместо color_over_lifetime
	particle_material.color_ramp = gradient_texture

func start_emission():
	"""Запускает эмиссию дыма"""
	emitting = true

func stop_emission():
	"""Останавливает эмиссию дыма"""
	emitting = false

func set_intensity(intensity: float):
	"""Устанавливает интенсивность эффекта от 0.0 до 1.0"""
	current_intensity = clamp(intensity, 0.0, max_intensity)
	
	if particle_material:
		# Изменяем скорость частиц
		var vel_factor = 0.5 + current_intensity * 0.5  # От 50% до 100%
		particle_material.initial_velocity_min = min_velocity * vel_factor
		particle_material.initial_velocity_max = max_velocity * vel_factor
		
		# Изменяем количество частиц плавно
		var target_amount = int(40 + current_intensity * 40)  # От 40 до 80 частиц
		amount = target_amount

func set_direction_smooth(velocity: Vector2):
	"""Плавно устанавливает направление на основе скорости"""
	if not particle_material:
		return
		
	# Проверяем, изменилось ли направление значительно
	var direction_change = velocity.normalized() - last_velocity.normalized()
	
	if direction_change.length() > 0.3:  # Значительное изменение направления
		direction_change_timer = 0.5  # Полсекунды плавного перехода
	
	# Если есть таймер перехода, делаем направление более рассеянным
	if direction_change_timer > 0:
		direction_change_timer -= get_process_delta_time()
		# Увеличиваем разброс при смене направления
		particle_material.spread = 50.0
	else:
		# Обычный разброс
		particle_material.spread = 35.0
	
	# Устанавливаем направление противоположное движению
	if velocity.length() > 5.0:
		var particle_dir = -velocity.normalized()
		particle_material.direction = Vector3(particle_dir.x, particle_dir.y, 0)
	else:
		# При остановке - направление вниз
		particle_material.direction = Vector3(0, 1, 0)
	
	last_velocity = velocity

func update_effect(velocity: Vector2, max_speed: float):
	"""Обновляет эффект на основе скорости движения"""
	var speed = velocity.length()
	
	if speed > 15.0:  # Минимальная скорость для активации
		if not emitting:
			start_emission()
		
		set_intensity(speed / max_speed)
		set_direction_smooth(velocity)
	else:
		# При остановке постепенно уменьшаем интенсивность
		if emitting and current_intensity > 0.1:
			set_intensity(current_intensity * 0.95)  # Постепенное затухание
		else:
			stop_emission() 
