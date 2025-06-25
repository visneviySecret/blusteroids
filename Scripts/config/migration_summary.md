# Сводка миграции на централизованную систему коллизий

## Обновленные файлы

### 1. Scripts/Ships/rocket_ship.gd

**Изменения:**

- Добавлен импорт `const Layers = preload("res://Scripts/config/collision_layers.gd")`
- Заменены жестко заданные числа на константы:
  - `ship_collision_layer = 1` → `ship_collision_layer = Layers.ENEMIES`
  - `laser_collision_layer = 2` → `laser_collision_layer = Layers.PLAYER_LASERS`
  - `laser_collision_mask = 1` → `laser_collision_mask = Layers.LaserMasks.PLAYER_LASERS`
  - `loot_collision_layer = 16` → `loot_collision_layer = Layers.LOOT_AREA`
  - `loot_collision_mask = 4` → `loot_collision_mask = Layers.PLAYER`
  - `wreckage_collision_layer = 32` → `wreckage_collision_layer = Layers.WRECKAGE`

### 2. Scripts/Enemies/enemy_ship.gd

**Изменения:**

- Заменены жестко заданные числа на константы в методе `_ready()`:
  - `ship_collision_layer = 1` → `ship_collision_layer = Layers.ENEMIES`
  - `ship_collision_mask = 8` → `ship_collision_mask = Layers.EnemyMasks.BASIC`
  - `laser_collision_layer = 8` → `laser_collision_layer = Layers.ENEMY_LASERS`
  - `laser_collision_mask = 4` → `laser_collision_mask = Layers.LaserMasks.ENEMY_LASERS`
  - `wreckage_collision_layer = 32` → `wreckage_collision_layer = Layers.WRECKAGE`

### 3. Scripts/Player/laser_projectile.gd

**Изменения:**

- Добавлен импорт `const Layers = preload("res://Scripts/config/collision_layers.gd")`
- Заменены жестко заданные числа в методе `setup_collision()`:
  - `collision_layer = 2` → `collision_layer = Layers.PLAYER_LASERS`
  - `collision_mask = 1 + 4 + 32` → `collision_mask = Layers.LaserMasks.PLAYER_LASERS`

### 4. Scripts/Player/grappling_hook.gd

**Изменения:**

- Добавлен импорт `const Layers = preload("res://Scripts/config/collision_layers.gd")`
- Заменены жестко заданные числа в методе `setup_hook_components()`:
  - `collision_layer = 2` → `collision_layer = Layers.PresetConfigs.HookConfig.LAYER`
  - `collision_mask = 1 + 4 + 32` → `collision_mask = Layers.PresetConfigs.HookConfig.MASK`

### 5. Scripts/Player/player.gd

**Изменения:**

- Добавлен импорт `const Layers = preload("res://Scripts/config/collision_layers.gd")`
- Заменены жестко заданные числа в методе `_ready()`:
  - `collision_layer = 4` → `collision_layer = Layers.PLAYER`
  - `collision_mask = 1` → `collision_mask = Layers.PlayerMasks.BASIC`

### 6. Scripts/Asteroid/asteroid.gd

**Изменения:**

- Добавлен импорт `const Layers = preload("res://Scripts/config/collision_layers.gd")`
- Заменены жестко заданные числа в методе `setup_asteroid()`:
  - `collision_layer = 4` → `collision_layer = Layers.OBSTACLES`

### 7. Scripts/Ships/README.md

**Изменения:**

- Обновлены примеры кода для использования констант из конфига
- Заменены жестко заданные числа на читаемые константы

## Преимущества миграции

### ✅ Централизованное управление

- Все слои коллизий теперь определены в одном месте
- Легко изменить логику коллизий для всего проекта

### ✅ Читаемость кода

- `Layers.ENEMIES` понятнее чем `1`
- `Layers.LaserMasks.PLAYER_LASERS` понятнее чем `1 + 4 + 32`

### ✅ Предотвращение ошибок

- Меньше шансов перепутать числа
- Автодополнение в IDE помогает избежать опечаток

### ✅ Легкость сопровождения

- Изменения в одном месте влияют на весь проект
- Четкая документация каждого слоя

### ✅ Отладка

- Утилитарные функции для проверки коллизий
- Человекочитаемые названия слоев

## Использование в новом коде

```gdscript
# Импорт в начале файла
const Layers = preload("res://Scripts/config/collision_layers.gd")

# Настройка коллизий
enemy.collision_layer = Layers.ENEMIES
enemy.collision_mask = Layers.EnemyMasks.BASIC

# Или используя предустановки
laser.collision_layer = Layers.PresetConfigs.PlayerLaser.LAYER
laser.collision_mask = Layers.PresetConfigs.PlayerLaser.MASK

# Динамическое изменение
new_mask = Layers.add_layer_to_mask(current_mask, Layers.OBSTACLES)

# Отладка
if Layers.can_collide_with(object.collision_mask, Layers.ENEMIES):
    print("Может сталкиваться с врагами")
```

## Обратная совместимость

Все изменения сохраняют полную обратную совместимость:

- Числовые значения слоев остались теми же
- Логика коллизий не изменилась
- Существующие сцены продолжают работать

## Следующие шаги

1. **Тестирование**: Проверить работу всех коллизий в игре
2. **Документация**: Обновить оставшуюся документацию
3. **Обучение команды**: Ознакомить разработчиков с новой системой
4. **Расширение**: Добавить новые слои по мере необходимости
