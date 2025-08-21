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

# --- Motion JSON específica para Avatar 2 ---
const AVATAR2_TALK_MOTION = {
    "Version": 3,
    "Meta": {
        "Duration": 1.2,
        "Fps": 30.0,
        "Loop": true,
        "AreBeziersRestricted": true,
        "CurveCount": 4,
        "TotalSegmentCount": 22,
        "TotalPointCount": 78,
        "UserDataCount": 0,
        "TotalUserDataSize": 0
    },
    "Curves": [
        {
            "Target": "Parameter",
            "Id": "ParamMouthOpenY",
            "Segments": [
                0,
                0,
                1,
                0.044,
                0,
                0.089,
                0.7,
                0.133,
                0.7,
                1,
                0.178,
                0.7,
                0.222,
                0.3,
                0.267,
                0.3,
                1,
                0.311,
                0.3,
                0.356,
                1,
                0.4,
                1,
                1,
                0.5,
                1,
                0.6,
                0.1,
                0.7,
                0.1,
                1,
                0.789,
                0.1,
                0.878,
                0.85,
                0.967,
                0.85,
                1,
                1.044,
                0.85,
                1.122,
                0,
                1.2,
                0
            ]
        },
        {
            "Target": "Parameter",
            "Id": "ParamMouthForm",
            "Segments": [
                0,
                0,
                1,
                0.1,
                0,
                0.2,
                0.5,
                0.3,
                0.5,
                1,
                0.433,
                0.5,
                0.567,
                -0.4,
                0.7,
                -0.4,
                1,
                0.867,
                -0.4,
                1.033,
                0.2,
                1.2,
                0.2
            ]
        },
        {
            "Target": "Parameter",
            "Id": "ParamBodyAngleZ",
            "Segments": [
                0,
                0,
                1,
                0.4,
                0,
                0.8,
                1.5,
                1.2,
                1.5
            ]
        },
        {
            "Target": "Parameter",
            "Id": "ParamBreath",
            "Segments": [
                0,
                0,
                1,
                0.5,
                0,
                1,
                1,
                1.2,
                1
            ]
        }
    ]
}

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

# Función específica para reproducir la motion JSON del Avatar 2
func play_avatar2_talk_motion(avatar_node) -> void:
	if not avatar_node.has_method("start_motion_from_json"):
		print("⚠️ El nodo del avatar no tiene el método start_motion_from_json")
		# Fallback al método original si no existe el método JSON
		avatar_node.start_motion("talk", 0, 3)
		return
	
	# Convertir la motion JSON a string y reproducirla
	var motion_json_string = JSON.stringify(AVATAR2_TALK_MOTION)
	avatar_node.start_motion_from_json(motion_json_string)
	print("✅ Reproduciendo motion JSON personalizada para Avatar 2")

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