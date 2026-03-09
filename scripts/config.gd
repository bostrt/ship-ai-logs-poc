extends Node

var llama_port: int = 8086
var model_file: String = "granite4-350m.gguf"
var model_name: String = "granite4-350m"
var gpu_layers: int = -1
var ctx_size: int = 2048
var temperature: float = 0.3

var api_url: String:
	get:
		return "http://127.0.0.1:%d" % llama_port

var model_path: String:
	get:
		return _resolve_path("models").path_join(model_file)

var llama_server_path: String:
	get:
		if OS.get_name() == "Windows":
			return _resolve_path("bin/windows").path_join("llama-server.exe")
		else:
			return _resolve_path("bin/linux").path_join("llama-server")

var system_prompt: String = """You are the onboard AI of a deep-space vessel. You analyze ship logs and system data.

Rules:
- Only reference data explicitly provided in the logs below.
- Do not speculate beyond what the logs show.
- Be concise and analytical.
- If the logs do not contain enough information, say so.
- Answer directly. Never start with phrases like "Based on the logs" or "According to the data". Just state the answer.
- If the question is unrelated to the ship or its systems, briefly deflect and remind the user you are a ship AI. Simple greetings are fine to acknowledge."""


func _resolve_path(subdir: String) -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://").path_join(subdir)
	else:
		return OS.get_executable_path().get_base_dir().path_join(subdir)
