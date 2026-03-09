extends Control

@onready var log_display: RichTextLabel = %LogDisplay
@onready var response_text: RichTextLabel = %ResponseText
@onready var player_input: LineEdit = %PlayerInput
@onready var ai_client: HTTPRequest = %AIClient

var _history_summary := ""
var _last_query := ""
var _last_response := ""


func _ready() -> void:
	log_display.bbcode_enabled = true
	log_display.text = ""
	log_display.append_text(LogData.get_bbcode())

	response_text.bbcode_enabled = true
	response_text.text = ""
	response_text.append_text("[color=#55aa55]Starting Ship AI...[/color]")

	player_input.editable = false
	player_input.text_submitted.connect(_on_input_submitted)
	ai_client.response_received.connect(_on_response)
	ai_client.request_failed.connect(_on_error)
	ai_client.summary_updated.connect(_on_summary_updated)

	LLMServer.server_ready.connect(_on_server_ready)
	LLMServer.server_failed.connect(_on_server_failed)


func _on_server_ready() -> void:
	response_text.text = ""
	response_text.append_text("[color=#55aa55]Ship AI online. Enter a query below.[/color]")
	player_input.editable = true
	player_input.grab_focus()


func _on_server_failed(msg: String) -> void:
	response_text.text = ""
	response_text.append_text("[color=#ff4444]Ship AI failed to start: " + msg + "[/color]")


func _on_input_submitted(text: String) -> void:
	var query := text.strip_edges()
	if query.is_empty():
		return

	player_input.clear()

	response_text.text = ""
	response_text.append_text("[color=#55aa55]Processing query...[/color]")

	# Fold the previous turn into the summary before sending the new query
	if _last_response != "":
		ai_client.summarize_history(_history_summary, _last_query, _last_response)
		_last_response = ""

	_last_query = query
	ai_client.send_query(query, _history_summary)


func _on_response(text: String) -> void:
	response_text.text = ""
	response_text.append_text("[color=#33ff33]" + text + "[/color]")
	player_input.grab_focus()

	_last_response = text


func _on_summary_updated(summary: String) -> void:
	_history_summary = summary


func _on_error(error_message: String) -> void:
	response_text.text = ""
	response_text.append_text("[color=#ff4444]ERROR: " + error_message + "[/color]")
	player_input.grab_focus()
