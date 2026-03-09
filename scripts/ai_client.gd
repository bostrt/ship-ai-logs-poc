extends HTTPRequest

signal response_received(text: String)
signal request_failed(error_message: String)
signal summary_updated(summary: String)

var _requesting := false
var _summary_request: HTTPRequest


func _ready() -> void:
	timeout = 30.0
	request_completed.connect(_on_request_completed)

	_summary_request = HTTPRequest.new()
	_summary_request.timeout = 15.0
	add_child(_summary_request)
	_summary_request.request_completed.connect(_on_summary_completed)


func send_query(user_message: String, history_summary: String = "") -> void:
	if _requesting:
		request_failed.emit("A query is already in progress.")
		return

	var log_text: String = LogData.get_plain_text()
	var system_content: String = Config.system_prompt + "\n\nShip logs:\n" + log_text
	if history_summary != "":
		system_content += "\n\nPrevious conversation summary:\n" + history_summary

	var body := {
		"model": Config.model_name,
		"temperature": Config.temperature,
		"messages": [
			{"role": "system", "content": system_content},
			{"role": "user", "content": user_message},
		],
	}

	var json_body := JSON.stringify(body)
	var headers := ["Content-Type: application/json"]
	var url: String = Config.api_url + "/v1/chat/completions"

	var err := request(url, headers, HTTPClient.METHOD_POST, json_body)
	if err != OK:
		request_failed.emit("Failed to connect to Ship AI (error %d)." % err)
		return

	_requesting = true


func summarize_history(previous_summary: String, last_query: String, last_response: String) -> void:
	var prompt: String = "Compress this into a brief conversation summary (2-3 sentences max)."
	if previous_summary != "":
		prompt += "\n\nPrevious summary:\n" + previous_summary
	prompt += "\n\nLatest exchange:\nUser: " + last_query + "\nAI: " + last_response

	var body := {
		"model": Config.model_name,
		"temperature": 0.1,
		"messages": [
			{"role": "system", "content": "You are a summarizer. Output only the summary, nothing else."},
			{"role": "user", "content": prompt},
		],
	}

	var json_body := JSON.stringify(body)
	var headers := ["Content-Type: application/json"]
	var url: String = Config.api_url + "/v1/chat/completions"

	_summary_request.request(url, headers, HTTPClient.METHOD_POST, json_body)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_requesting = false

	if result != RESULT_SUCCESS:
		var msg := "Connection failed"
		match result:
			RESULT_CANT_CONNECT:
				msg = "Cannot connect to Ship AI server."
			RESULT_CANT_RESOLVE:
				msg = "Cannot resolve Ship AI server address."
			RESULT_TIMEOUT:
				msg = "Ship AI request timed out."
			RESULT_CONNECTION_ERROR:
				msg = "Connection error with Ship AI server."
			_:
				msg = "Ship AI request failed (result %d)." % result
		request_failed.emit(msg)
		return

	if response_code != 200:
		request_failed.emit("Ship AI returned HTTP %d." % response_code)
		return

	var json := JSON.new()
	var parse_err := json.parse(body.get_string_from_utf8())
	if parse_err != OK:
		request_failed.emit("Failed to parse Ship AI response.")
		return

	var data: Dictionary = json.data
	if not data.has("choices") or data.choices.is_empty():
		request_failed.emit("Ship AI returned an empty response.")
		return

	var text: String = data.choices[0].message.content
	response_received.emit(text.strip_edges())


func _on_summary_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		return

	var data: Dictionary = json.data
	if not data.has("choices") or data.choices.is_empty():
		return

	var text: String = data.choices[0].message.content
	summary_updated.emit(text.strip_edges())
