extends RefCounted
class_name CollisionLayers

# Конфигурация слоев коллизий для проекта Blasteroids
# Этот класс содержит все константы слоев и масок коллизий

# ============================================================================
# СЛОИ КОЛЛИЗИЙ (collision_layer)
# ============================================================================

# Основные игровые объекты
const ENEMIES: int = 1          # Слой 1 - Живые враги
const PLAYER_LASERS: int = 2    # Слой 2 - Лазеры игрока  
const PLAYER: int = 4           # Слой 3 - Игрок
const ENEMY_LASERS: int = 8     # Слой 4 - Лазеры врагов
const LOOT_AREA: int = 16       # Слой 5 - Область лута (взаимодействие с игроком)
const WRECKAGE: int = 32        # Слой 6 - Обломки кораблей

# Дополнительные слои (зарезервированы для будущего использования)
const OBSTACLES: int = 64       # Слой 7 - Препятствия
const PICKUPS: int = 128        # Слой 8 - Подбираемые предметы
const ENVIRONMENT: int = 256    # Слой 9 - Элементы окружения
const EFFECTS: int = 512        # Слой 10 - Визуальные эффекты

# ============================================================================
# МАСКИ КОЛЛИЗИЙ (collision_mask) 
# ============================================================================

# Маски для основных объектов
class PlayerMasks:
	# С чем может сталкиваться игрок
	const BASIC: int = ENEMIES + ENEMY_LASERS + OBSTACLES + PICKUPS
	const WITH_WRECKAGE: int = BASIC + WRECKAGE

class EnemyMasks:
	# С чем могут сталкиваться враги
	const BASIC: int = PLAYER_LASERS + OBSTACLES
	const WITH_PLAYER: int = BASIC + PLAYER

class LaserMasks:
	# Лазеры игрока сталкиваются с врагами, препятствиями и обломками
	const PLAYER_LASERS: int = ENEMIES + OBSTACLES + WRECKAGE
	
	# Лазеры врагов сталкиваются с игроком и препятствиями
	const ENEMY_LASERS: int = PLAYER + OBSTACLES

class LootMasks:
	# Лут взаимодействует только с игроком
	const LOOT_INTERACTION: int = PLAYER

class WreckageMasks:
	# Обломки пассивны, ни с чем не сталкиваются активно
	const PASSIVE: int = 0

class GrapplingHookMasks:
	# Крюк-кошка может цепляться за врагов, препятствия и обломки
	const HOOK_TARGETS: int = ENEMIES + OBSTACLES + WRECKAGE

# ============================================================================
# УТИЛИТАРНЫЕ ФУНКЦИИ
# ============================================================================

# Функция для проверки, находится ли объект на определенном слое
static func is_on_layer(collision_layer: int, target_layer: int) -> bool:
	return (collision_layer & target_layer) != 0

# Функция для проверки, может ли объект сталкиваться с определенным слоем
static func can_collide_with(collision_mask: int, target_layer: int) -> bool:
	return (collision_mask & target_layer) != 0

# Функция для добавления слоя к маске
static func add_layer_to_mask(current_mask: int, layer_to_add: int) -> int:
	return current_mask | layer_to_add

# Функция для удаления слоя из маски
static func remove_layer_from_mask(current_mask: int, layer_to_remove: int) -> int:
	return current_mask & ~layer_to_remove

# Функция для получения названия слоя (для отладки)
static func get_layer_name(layer: int) -> String:
	match layer:
		ENEMIES:
			return "Враги"
		PLAYER_LASERS:
			return "Лазеры игрока"
		PLAYER:
			return "Игрок"
		ENEMY_LASERS:
			return "Лазеры врагов"
		LOOT_AREA:
			return "Область лута"
		WRECKAGE:
			return "Обломки"
		OBSTACLES:
			return "Препятствия"
		PICKUPS:
			return "Подбираемые предметы"
		ENVIRONMENT:
			return "Окружение"
		EFFECTS:
			return "Эффекты"
		_:
			return "Неизвестный слой: " + str(layer)

# Функция для получения всех активных слоев в маске (для отладки)
static func get_active_layers_in_mask(mask: int) -> Array[String]:
	var active_layers: Array[String] = []
	var layers = [ENEMIES, PLAYER_LASERS, PLAYER, ENEMY_LASERS, LOOT_AREA, 
				  WRECKAGE, OBSTACLES, PICKUPS, ENVIRONMENT, EFFECTS]
	
	for layer in layers:
		if can_collide_with(mask, layer):
			active_layers.append(get_layer_name(layer))
	
	return active_layers

# ============================================================================
# ПРЕДУСТАНОВЛЕННЫЕ КОНФИГУРАЦИИ
# ============================================================================

# Готовые конфигурации для быстрого применения
class PresetConfigs:
	# Конфигурация для игрока
	class Player:
		const LAYER: int = CollisionLayers.PLAYER
		const MASK: int = PlayerMasks.BASIC
	
	# Конфигурация для врагов
	class Enemy:
		const LAYER: int = CollisionLayers.ENEMIES
		const MASK: int = EnemyMasks.BASIC
	
	# Конфигурация для лазеров игрока
	class PlayerLaser:
		const LAYER: int = CollisionLayers.PLAYER_LASERS
		const MASK: int = LaserMasks.PLAYER_LASERS
	
	# Конфигурация для лазеров врагов
	class EnemyLaser:
		const LAYER: int = CollisionLayers.ENEMY_LASERS
		const MASK: int = LaserMasks.ENEMY_LASERS
	
	# Конфигурация для области лута
	class LootArea:
		const LAYER: int = CollisionLayers.LOOT_AREA
		const MASK: int = LootMasks.LOOT_INTERACTION
	
	# Конфигурация для обломков
	class Wreckage:
		const LAYER: int = CollisionLayers.WRECKAGE
		const MASK: int = WreckageMasks.PASSIVE
	
	# Конфигурация для крюка-кошки
	class HookConfig:
		const LAYER: int = CollisionLayers.PLAYER_LASERS  # Используем тот же слой что и лазеры игрока
		const MASK: int = GrapplingHookMasks.HOOK_TARGETS

# ============================================================================
# ДОКУМЕНТАЦИЯ
# ============================================================================

# Описание системы слоев:
#
# Слой 1 (ENEMIES = 1): Живые враги
#   - Используется для всех активных вражеских кораблей
#   - Может получать урон от лазеров игрока
#   - Может сталкиваться с игроком
#
# Слой 2 (PLAYER_LASERS = 2): Лазеры игрока
#   - Снаряды, выпущенные игроком
#   - Наносят урон врагам и уничтожаются при столкновении
#   - Могут попадать в обломки
#
# Слой 3 (PLAYER = 4): Игрок
#   - Основной персонаж игрока
#   - Может получать урон от лазеров врагов
#   - Может взаимодействовать с лутом
#
# Слой 4 (ENEMY_LASERS = 8): Лазеры врагов
#   - Снаряды, выпущенные врагами
#   - Наносят урон игроку
#   - Не могут попадать в других врагов
#
# Слой 5 (LOOT_AREA = 16): Область лута
#   - Невидимые области вокруг обломков кораблей
#   - Обнаруживают приближение игрока для разграбления
#   - Не имеют физических коллизий
#
# Слой 6 (WRECKAGE = 32): Обломки кораблей
#   - Остатки уничтоженных кораблей
#   - Могут получать урон от лазеров (для быстрого уничтожения)
#   - Могут взаимодействовать с крюком-кошкой
#   - Не двигаются и не стреляют 
