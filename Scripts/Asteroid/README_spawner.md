# Спавнер Астероидов

Система автоматического спавна астероидов с вариативностью размера и скорости.

## Возможности

- ✅ **Автоматический спавн** - астероиды появляются за пределами экрана
- ✅ **Вариативность размера** - от 50% до 200% базового размера
- ✅ **Разные скорости** - каждый астероид летит со своей скоростью
- ✅ **Автоудаление** - астероиды исчезают при выходе за границы экрана × 2
- ✅ **Масштабируемое здоровье** - больше астероид = больше здоровья
- ✅ **Случайные текстуры** - поддержка множественных текстур
- ✅ **Управление камерой** - спавн относительно позиции камеры

## Быстрый старт

### 1. Добавление в сцену

```gdscript
# Создайте Node2D и добавьте скрипт
extends Node2D

var spawner: AsteroidSpawner

func _ready():
    spawner = AsteroidSpawner.new()
    add_child(spawner)
    spawner.start_spawning()
```

### 2. Настройка параметров

```gdscript
# Частота спавна
spawner.spawn_rate = 2.0  # 2 астероида в секунду
spawner.max_asteroids = 15  # Максимум на экране

# Размеры
spawner.min_scale = 0.5  # 50% размера
spawner.max_scale = 2.0  # 200% размера

# Скорости
spawner.min_speed = 50.0
spawner.max_speed = 200.0
```

### 3. Подключение сигналов

```gdscript
spawner.asteroid_spawned.connect(_on_asteroid_spawned)
spawner.asteroid_destroyed.connect(_on_asteroid_destroyed)

func _on_asteroid_spawned(asteroid: Asteroid):
    print("Новый астероид!")

func _on_asteroid_destroyed(asteroid: Asteroid):
    print("Астероид уничтожен!")
```

## Параметры экспорта

| Параметр                  | Тип              | Описание              |
| ------------------------- | ---------------- | --------------------- |
| `spawn_rate`              | float            | Астероидов в секунду  |
| `max_asteroids`           | int              | Максимум на экране    |
| `spawn_distance`          | float            | Расстояние за экраном |
| `min_scale` / `max_scale` | float            | Диапазон размеров     |
| `min_speed` / `max_speed` | float            | Диапазон скоростей    |
| `base_health`             | float            | Базовое здоровье      |
| `health_scale_multiplier` | float            | Множитель здоровья    |
| `asteroid_scene`          | PackedScene      | Сцена астероида       |
| `asteroid_textures`       | Array[Texture2D] | Массив текстур        |

## Методы управления

```gdscript
# Управление спавном
spawner.start_spawning()
spawner.stop_spawning()
spawner.clear_all_asteroids()

# Настройка параметров
spawner.set_spawn_rate(3.0)
spawner.set_max_asteroids(20)
spawner.set_speed_range(30.0, 150.0)
spawner.set_scale_range(0.3, 2.5)

# Получение информации
var count = spawner.get_active_asteroid_count()
var info = spawner.get_spawn_info()
```

## Демонстрация

Используйте `asteroid_spawner_demo.gd` для тестирования:

**Управление:**

- `Enter` - включить/выключить спавн
- `Escape` - удалить все астероиды
- `↑/↓` - изменить частоту спавна
- `←/→` - изменить максимум астероидов

## Интеграция с игрой

### Подключение к системе счета

```gdscript
spawner.asteroid_destroyed.connect(_on_asteroid_destroyed)

func _on_asteroid_destroyed(asteroid: Asteroid):
    # Начисляем очки в зависимости от размера
    var points = int(asteroid.scale.x * 100)
    add_score(points)
```

### Настройка сложности

```gdscript
func set_difficulty_level(level: int):
    match level:
        1:
            spawner.set_spawn_rate(1.0)
            spawner.set_max_asteroids(8)
        2:
            spawner.set_spawn_rate(1.5)
            spawner.set_max_asteroids(12)
        3:
            spawner.set_spawn_rate(2.5)
            spawner.set_max_asteroids(18)
```

## Требования

- Сцена астероида: `res://Scene/asteroid.tscn`
- Класс астероида: `Scripts/Asteroid/asteroid.gd`
- Текстуры астероидов (опционально): `res://Assets/Images/Asteroid/`

## Примечания

- Спавнер автоматически находит камеру в сцене
- Астероиды спавнятся со всех 4 сторон экрана
- Удаление происходит при выходе за границы экрана × 2
- Здоровье астероида = `base_health × scale^health_scale_multiplier`
- Поддерживается работа с крюк-кошкой игрока
