# Control.gd - MODIFICADO para usar el sistema dinámico con motions JSON integradas
extends Control

# --- Referencias a nodos ---
@onready var history_label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var input_line: LineEdit = $VBoxContainer/HBoxContainer/LineEdit
@onready var send_button: Button = $VBoxContainer/HBoxContainer/Button

# --- AI dinámico ---
var current_ai: BaseAI = null
var is_ready = false

# --- Mapeo de motions por avatar ---
const AVATAR_MOTION_MAP = {
	0: { # Avatar 1 (índice 0)
		"talk": {"group": "motions", "index": 2},  # Ajusta estos valores
		"idle": {"group": "idle", "index": 0},
		"happy": {"group": "happy", "index": 0}
	},
	1: { # Avatar 2 (índice 1)
		"talk": {"group": "talk", "index": 0},
		"idle": {"group": "idle", "index": 0},
		"happy": {"group": "happy", "index": 0}
	}
}

# --- Funciones hardcodeadas para Avatar 2 basadas en el JSON ---
func calculate_avatar2_mouth_open_curve(progress: float) -> float:
	"""Calcular el valor de apertura de boca basado en la curva de la motion del Avatar 2"""
	# Esta función replica la curva de ParamMouthOpenY del JSON
	# Los valores están basados en los segmentos de la motion
	
	if progress <= 0.0:
		return 0.0  # Boca cerrada
	elif progress <= 0.044:
		# Transición suave de cerrada a abierta
		var t = progress / 0.044
		return lerp(0.0, 0.089, ease_in_out_cubic(t))
	elif progress <= 0.089:
		return 0.089
	elif progress <= 0.133:
		# Transición a 0.7
		var t = (progress - 0.089) / (0.133 - 0.089)
		return lerp(0.089, 0.7, ease_in_out_cubic(t))
	elif progress <= 0.178:
		return 0.7
	elif progress <= 0.222:
		# Transición a 0.3
		var t = (progress - 0.178) / (0.222 - 0.178)
		return lerp(0.7, 0.3, ease_in_out_cubic(t))
	elif progress <= 0.267:
		return 0.3
	elif progress <= 0.311:
		# Mantiene 0.3
		return 0.3
	elif progress <= 0.356:
		# Transición a 1.0
		var t = (progress - 0.311) / (0.356 - 0.311)
		return lerp(0.3, 1.0, ease_in_out_cubic(t))
	elif progress <= 0.4:
		return 1.0
	elif progress <= 0.5:
		# Mantiene 1.0
		return 1.0
	elif progress <= 0.6:
		# Transición a 0.1
		var t = (progress - 0.5) / (0.6 - 0.5)
		return lerp(1.0, 0.1, ease_in_out_cubic(t))
	elif progress <= 0.7:
		return 0.1
	elif progress <= 0.789:
		# Mantiene 0.1
		return 0.1
	elif progress <= 0.878:
		# Transición a 0.85
		var t = (progress - 0.789) / (0.878 - 0.789)
		return lerp(0.1, 0.85, ease_in_out_cubic(t))
	elif progress <= 0.967:
		return 0.85
	elif progress <= 1.044:
		# Mantiene 0.85
		return 0.85
	elif progress <= 1.122:
		# Transición a 0.0
		var t = (progress - 1.044) / (1.122 - 1.044)
		return lerp(0.85, 0.0, ease_in_out_cubic(t))
	else:
		return 0.0  # Boca cerrada

func calculate_avatar2_mouth_form_curve(progress: float) -> float:
	"""Calcular el valor de forma de boca basado en la curva de la motion del Avatar 2"""
	# Esta función replica la curva de ParamMouthForm del JSON
	
	if progress <= 0.0:
		return 0.0
	elif progress <= 0.1:
		# Transición suave
		var t = progress / 0.1
		return lerp(0.0, 0.0, ease_in_out_cubic(t))
	elif progress <= 0.2:
		# Transición a 0.5
		var t = (progress - 0.1) / (0.2 - 0.1)
		return lerp(0.0, 0.5, ease_in_out_cubic(t))
	elif progress <= 0.3:
		return 0.5
	elif progress <= 0.433:
		# Mantiene 0.5
		return 0.5
	elif progress <= 0.567:
		# Transición a -0.4
		var t = (progress - 0.433) / (0.567 - 0.433)
		return lerp(0.5, -0.4, ease_in_out_cubic(t))
	elif progress <= 0.7:
		return -0.4
	elif progress <= 0.867:
		# Mantiene -0.4
		return -0.4
	elif progress <= 1.033:
		# Transición a 0.2
		var t = (progress - 0.867) / (1.033 - 0.867)
		return lerp(-0.4, 0.2, ease_in_out_cubic(t))
	elif progress <= 1.2:
		return 0.2
	else:
		return 0.2

func calculate_avatar2_body_angle_curve(progress: float) -> float:
	"""Calcular el valor del ángulo del cuerpo basado en la curva de la motion del Avatar 2"""
	# Esta función replica la curva de ParamBodyAngleZ del JSON
	
	if progress <= 0.0:
		return 0.0
	elif progress <= 0.4:
		# Transición suave
		var t = progress / 0.4
		return lerp(0.0, 0.0, ease_in_out_cubic(t))
	elif progress <= 0.8:
		# Transición a 1.5
		var t = (progress - 0.4) / (0.8 - 0.4)
		return lerp(0.0, 1.5, ease_in_out_cubic(t))
	elif progress <= 1.2:
		return 1.5
	else:
		return 1.5

func calculate_avatar2_breath_curve(progress: float) -> float:
	"""Calcular el valor de respiración basado en la curva de la motion del Avatar 2"""
	# Esta función replica la curva de ParamBreath del JSON
	
	if progress <= 0.0:
		return 0.0
	elif progress <= 0.5:
		# Transición suave
		var t = progress / 0.5
		return lerp(0.0, 0.0, ease_in_out_cubic(t))
	elif progress <= 1.0:
		# Transición a 1.0
		var t = (progress - 0.5) / (1.0 - 0.5)
		return lerp(0.0, 1.0, ease_in_out_cubic(t))
	elif progress <= 1.2:
		return 1.0
	else:
		return 1.0

# Función de utilidad para easing
func ease_in_out_cubic(t: float) -> float:
	"""Función de easing cúbico suave"""
	return t * t * (3.0 - 2.0 * t)

func _ready() -> void:
	# Crear el AI según el avatar seleccionado
	var selected_avatar = Gamedata.get_selected_avatar_index()
	current_ai = AIFactory.create_ai_for_avatar(selected_avatar)
	
	if current_ai:
		add_child(current_ai)
		print("✅ AI creado para avatar ", selected_avatar, ": ", current_ai.name)
	else:
		push_error("❌ No se pudo crear AI para avatar " + str(selected_avatar))
		return
	
	# Resto del código igual
	send_button.pressed.connect(_on_send_pressed)
	input_line.text_submitted.connect(_on_send_pressed)
	GlobalEvents.yuki_starts_talking.connect(_on_yuki_response_received)
	
	# Mensaje inicial personalizado según el avatar
	var avatar_name = Gamedata.get_selected_avatar_name()
	history_label.append_text("🤖 " + avatar_name + ": ¡Hola! ¿En qué puedo ayudarte?\n")
	input_line.grab_focus()
	
	is_ready = true

func _on_send_pressed() -> void:
	var user_text = input_line.text
	if user_text.strip_edges().is_empty():
		return
	
	history_label.append_text("\n👤 Tú: " + user_text + "\n")
	
	# Usar el AI actual (puede ser YukiAI o SakuraAI)
	if current_ai:
		current_ai.send_message(user_text)
	
	input_line.clear()
	input_line.grab_focus()
	
	var avatar_name = Gamedata.get_selected_avatar_name()
	history_label.append_text("🤖 " + avatar_name + ": ...\n")

func _on_yuki_response_received(dialogue: String, emotion: String, gesture: String):
	var avatar_name = Gamedata.get_selected_avatar_name()
	var current_text = history_label.text.replace("🤖 " + avatar_name + ": ...\n", "🤖 " + avatar_name + ": ")
	history_label.text = current_text
	history_label.append_text(dialogue + "\n")
	
	# Reproducir motion con el mapeo correcto
	if is_ready:
		play_avatar_motion("talk")
	
	print("Emoción recibida: ", emotion)
	print("Gesto recibido: ", gesture)

# Nueva función para reproducir motions con mapeo y JSON integrado
func play_avatar_motion(motion_name: String) -> void:
	var avatar_node = get_avatar_node()
	if not avatar_node:
		print("⚠️ No se pudo encontrar el nodo del avatar")
		return
	
	var selected_avatar = Gamedata.get_selected_avatar_index()
	
	# Caso especial para Avatar 2 (índice 1) con motion JSON
	if selected_avatar == 1 and motion_name == "talk":
		play_avatar2_talk_motion(avatar_node)
		return
	
	# Verificar si existe el mapeo para este avatar
	if not AVATAR_MOTION_MAP.has(selected_avatar):
		print("⚠️ No hay mapeo de motions para avatar ", selected_avatar)
		return
	
	var avatar_motions = AVATAR_MOTION_MAP[selected_avatar]
	
	# Verificar si existe la motion solicitada
	if not avatar_motions.has(motion_name):
		print("⚠️ Motion '", motion_name, "' no encontrada para avatar ", selected_avatar)
		return
	
	var motion_data = avatar_motions[motion_name]
	avatar_node.start_motion(motion_data.group, motion_data.index, 3)

# Función específica para reproducir la motion hardcodeada del Avatar 2
func play_avatar2_talk_motion(avatar_node) -> void:
	# Crear un timer para animar la motion
	var animation_timer = Timer.new()
	animation_timer.wait_time = 0.04  # 30 FPS (1/30 ≈ 0.033)
	animation_timer.one_shot = false
	add_child(animation_timer)
	
	var current_time = 0.0
	var total_duration = 1.2  # Duración total de la motion
	
	# Función que se ejecuta en cada frame de la animación
	animation_timer.timeout.connect(func():
		var progress = current_time / total_duration
		
		# Calcular valores de cada parámetro
		var mouth_open = calculate_avatar2_mouth_open_curve(progress)
		var mouth_form = calculate_avatar2_mouth_form_curve(progress)
		var body_angle = calculate_avatar2_body_angle_curve(progress)
		var breath = calculate_avatar2_breath_curve(progress)
		
		# Aplicar los valores al avatar
		if avatar_node.has_method("set_parameter_value"):
			avatar_node.set_parameter_value("ParamMouthOpenY", mouth_open)
			avatar_node.set_parameter_value("ParamMouthForm", mouth_form)
			avatar_node.set_parameter_value("ParamBodyAngleZ", body_angle)
			avatar_node.set_parameter_value("ParamBreath", breath)
		else:
			# Fallback si no existe el método set_parameter_value
			print("⚠️ El nodo del avatar no tiene el método set_parameter_value")
			avatar_node.start_motion("talk", 0, 3)
			animation_timer.queue_free()
			return
		
		current_time += animation_timer.wait_time
		
		# Detener la animación cuando termine
		if current_time >= total_duration:
			animation_timer.stop()
			animation_timer.queue_free()
			print("✅ Motion hardcodeada completada para Avatar 2")
	)
	
	# Iniciar la animación
	animation_timer.start()
	print("✅ Reproduciendo motion hardcodeada personalizada para Avatar 2")

# Función para obtener el nodo del avatar dinámicamente
func get_avatar_node():
	# Buscar el nodo Avatar en la escena
	var avatar_container = get_node_or_null("../../Avatar")
	if not avatar_container:
		return null
	
	# Buscar el Sprite2D activo (el que está visible)
	for child in avatar_container.get_children():
		if child is Sprite2D and child.visible:
			# Buscar el GDCubismUserModel dentro del Sprite2D
			for grandchild in child.get_children():
				if grandchild.has_method("start_motion"):
					return grandchild
	
	return null