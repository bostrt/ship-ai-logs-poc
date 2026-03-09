extends Node

signal server_ready
signal server_failed(msg: String)

var _pid: int = -1
var _health_request: HTTPRequest
var _retries: int = 0

const MAX_RETRIES := 60  # 30 seconds at 0.5s intervals
const RETRY_INTERVAL := 0.5


func _ready() -> void:
	var bin_path: String = Config.llama_server_path
	print("[LLMServer] looking for binary at: ", bin_path)
	if not FileAccess.file_exists(bin_path):
		print("[LLMServer] ERROR: binary not found!")
		server_failed.emit("llama-server not found at: " + bin_path)
		return

	var model_path: String = Config.model_path
	print("[LLMServer] looking for model at: ", model_path)
	if not FileAccess.file_exists(model_path):
		print("[LLMServer] ERROR: model not found!")
		server_failed.emit("Model not found at: " + model_path)
		return

	_kill_stale_server()

	var bin_dir := bin_path.get_base_dir()
	var log_path := ProjectSettings.globalize_path("user://llama-server.log")

	print("[LLMServer] bin_path: ", bin_path)
	print("[LLMServer] model_path: ", model_path)
	print("[LLMServer] log_path: ", log_path)

	if OS.get_name() == "Windows":
		var args := PackedStringArray([
			"--model", model_path,
			"--port", str(Config.llama_port),
			"--ctx-size", str(Config.ctx_size),
			"--host", "127.0.0.1",
			"-ngl", str(Config.gpu_layers),
			"--log-file", log_path,
		])
		print("[LLMServer] launching: ", bin_path, " ", " ".join(args))
		_pid = OS.create_process(bin_path, args)
	else:
		# exec replaces the shell so OS.kill(_pid) kills llama-server directly.
		var cmd := "LD_LIBRARY_PATH='%s' exec '%s' --model '%s' --port %d --ctx-size %d --host 127.0.0.1 -ngl %d > '%s' 2>&1" % [
			bin_dir, bin_path, model_path,
			Config.llama_port, Config.ctx_size, Config.gpu_layers, log_path,
		]
		_pid = OS.create_process("/bin/sh", PackedStringArray(["-c", cmd]))
	print("[LLMServer] pid: ", _pid)
	if _pid <= 0:
		server_failed.emit("Failed to launch llama-server.")
		return

	_health_request = HTTPRequest.new()
	_health_request.timeout = 2.0
	add_child(_health_request)
	_health_request.request_completed.connect(_on_health_response)

	_poll_health()


func _poll_health() -> void:
	var url := Config.api_url + "/health"
	var err := _health_request.request(url)
	if err != OK:
		_schedule_retry()


func _on_health_response(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		server_ready.emit()
		return
	_schedule_retry()


func _schedule_retry() -> void:
	_retries += 1
	if _retries >= MAX_RETRIES:
		server_failed.emit("llama-server did not become ready in time.")
		return
	get_tree().create_timer(RETRY_INTERVAL).timeout.connect(_poll_health)


func _kill_stale_server() -> void:
	if OS.get_name() == "Windows":
		return
	var output: Array = []
	# Find any process already bound to our port
	OS.execute("fuser", PackedStringArray(["%d/tcp" % Config.llama_port]), output, true)
	if output.is_empty():
		return
	var pids: String = str(output[0]).strip_edges()
	var parts: PackedStringArray = pids.split(" ", false)
	for i in parts.size():
		var pid_str: String = parts[i]
		if pid_str.is_valid_int():
			OS.kill(pid_str.to_int())


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		_kill_server()


func _kill_server() -> void:
	if _pid > 0:
		OS.kill(_pid)
		_pid = -1
