extends Node

# Сигнал активации зоны
signal zone_completed(zone_name)

# Словарь для отслеживания, какие зоны уже активированы
var activated_zones = {
	"Zone1": false,
	"Zone2": false,
	"Zone3": false
}

var completed_zones_count = 0  # Сколько зон активировано
const REQUIRED_ZONES = 3  # Сколько нужно активировать для финала

func _ready() -> void:
	# make gorgon invisible
	$Gorgon/AnimatedSprite2D.visible = false
	
	print("GameManager готов")
	print("Начальное значение completed_zones_count:", completed_zones_count)
	
	# Добавим отладочную проверку каждые 2 секунды
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_on_debug_timer_timeout)
	add_child(timer)

func _on_debug_timer_timeout() -> void:
	print("[DEBUG] Текущее количество активированных зон:", completed_zones_count)
	print("[DEBUG] Статус зон:", JSON.stringify(activated_zones))

func register_zone_activation(zone_name: String) -> void:
	print("Регистрация активации зоны:", zone_name)
	
	# Если зона ещё не была активирована
	if not activated_zones.get(zone_name, false):
		activated_zones[zone_name] = true
		completed_zones_count += 1
		
		print("Зона зарегистрирована:", zone_name)
		print("Прогресс:", completed_zones_count, "/", REQUIRED_ZONES)
		
		# Сигнал для всех заинтересованных объектов
		emit_signal("zone_completed", zone_name)
		
		# Если собрали все зоны - разрешаем финальное событие
		if completed_zones_count >= REQUIRED_ZONES:
			enable_final_event()
	else:
		print("Зона", zone_name, "уже была активирована ранее")

func get_completed_zones_count() -> int:
	print("Запрошено количество активированных зон:", completed_zones_count)
	return completed_zones_count

func enable_final_event() -> void:
	print("Все зоны собраны! Финальное событие доступно")
