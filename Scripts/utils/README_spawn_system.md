# Система Спавна (SpawnSystem)

Общая переиспользуемая система для спавна объектов за пределами экрана.

## Возможности

- ✅ **Универсальный спавн** - работает с любыми объектами
- ✅ **Спавн за экраном** - объекты появляются за пределами видимой области
- ✅ **Гибкие параметры** - настраиваемые отступы и ограничения
- ✅ **Работа с камерой** - автоматический учет позиции камеры
- ✅ **Ограничения по дистанции** - минимальная/максимальная дистанция от цели
- ✅ **Утилитарные методы** - проверка позиций, границы удаления

## Структуры данных

### SpawnParams

Параметры для настройки спавна:

```gdscript
var params = SpawnSystem.SpawnParams.new(
    screen_margin,           # Отступ за пределы экрана
    min_distance_from_target, # Минимальная дистанция от цели
    max_distance_from_target, # Максимальная дистанция от цели
    additional_offset        # Дополнительный отступ
)
```

## Основные методы

### get_offscreen_spawn_position()

Главный метод для получения позиции спавна за пределами экрана:

```gdscript
var spawn_pos = SpawnSystem.get_offscreen_spawn_position(
    get_viewport(),    # Viewport для получения размера экрана
    target_node,       # Целевой узел (игрок) или null
    spawn_params       # Параметры спавна или null для значений по умолчанию
)
```

### get_simple_offscreen_position()

Упрощенная версия без дополнительных параметров:

```gdscript
var spawn_pos = SpawnSystem.get_simple_offscreen_position(
    get_viewport(),
    camera,           # Камера или null
    100.0            # Отступ за пределы экрана
)
```

### get_random_screen_target()

Получение случайной точки на экране как цели для движения:

```gdscript
var target_pos = SpawnSystem.get_random_screen_target(
    get_viewport(),
    camera           # Камера или null
)
```

## Утилитарные методы

### is_position_outside_screen()

Проверка, находится ли позиция за пределами экрана:

```gdscript
var is_outside = SpawnSystem.is_position_outside_screen(
    position,        # Проверяемая позиция
    get_viewport(),
    camera,          # Камера или null
    margin          # Дополнительный отступ
)
```

### get_deletion_bounds()

Получение границ для удаления объектов:

```gdscript
var bounds = SpawnSystem.get_deletion_bounds(
    get_viewport(),
    camera,          # Камера или null
    2.0             # Масштаб (2.0 = в 2 раза больше экрана)
)
```

## Примеры использования

### Спавн астероидов

```gdscript
# Настройка параметров
var max_asteroid_size = max_scale * 100.0
var spawn_params = SpawnSystem.SpawnParams.new(
    300.0,              # Отступ за экран
    0.0,                # Мин. дистанция (не используется)
    0.0,                # Макс. дистанция (не используется)
    max_asteroid_size   # Дополнительный отступ для больших астероидов
)

# Спавн
var spawn_pos = SpawnSystem.get_offscreen_spawn_position(get_viewport(), null, spawn_params)
var target_pos = SpawnSystem.get_random_screen_target(get_viewport(), camera)
```

### Спавн врагов

```gdscript
# Настройка параметров
var spawn_params = SpawnSystem.SpawnParams.new(
    100.0,    # Отступ за экран
    800.0,    # Минимальная дистанция от игрока
    1200.0,   # Максимальная дистанция от игрока
    0.0       # Дополнительный отступ не нужен
)

# Спавн
var spawn_pos = SpawnSystem.get_offscreen_spawn_position(get_viewport(), player, spawn_params)
```

### Проверка границ для удаления

```gdscript
# Получаем границы удаления
var deletion_bounds = SpawnSystem.get_deletion_bounds(get_viewport(), camera, 2.0)

# Проверяем объекты
for obj in objects:
    if not deletion_bounds.has_point(obj.global_position):
        obj.queue_free()  # Удаляем объект вышедший за границы
```

## Интеграция в существующие спавнеры

### Обновление AsteroidSpawner

```gdscript
const SpawnSystem = preload("../utils/spawn_system.gd")

var spawn_params: SpawnSystem.SpawnParams

func setup_spawner():
    var max_asteroid_size = max_scale * 100.0
    spawn_params = SpawnSystem.SpawnParams.new(
        spawn_distance, 0.0, 0.0, max_asteroid_size
    )

func spawn_asteroid():
    var spawn_pos = SpawnSystem.get_offscreen_spawn_position(get_viewport(), null, spawn_params)
    var target_pos = SpawnSystem.get_random_screen_target(get_viewport(), camera)
```

### Обновление EnemyShipSpawner

```gdscript
const SpawnSystem = preload("../utils/spawn_system.gd")

var spawn_params: SpawnSystem.SpawnParams

func _ready():
    spawn_params = SpawnSystem.SpawnParams.new(
        screen_margin, spawn_distance_min, spawn_distance_max, 0.0
    )

func spawn_enemy():
    var spawn_pos = SpawnSystem.get_offscreen_spawn_position(get_viewport(), player, spawn_params)
```

## Преимущества

1. **Переиспользование кода** - одна система для всех типов спавна
2. **Консистентность** - одинаковое поведение во всех спавнерах
3. **Гибкость** - легкая настройка под разные нужды
4. **Поддержка** - централизованные исправления и улучшения
5. **Читаемость** - понятный и документированный API

## Совместимость

- ✅ Работает с любыми Node2D объектами
- ✅ Поддерживает Camera2D
- ✅ Не зависит от конкретных классов игровых объектов
- ✅ Обратная совместимость с существующими спавнерами
