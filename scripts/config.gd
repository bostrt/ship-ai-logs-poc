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


func _exe_dir() -> String:
	return OS.get_executable_path().get_base_dir()


func _resolve_path(subdir: String) -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://").path_join(subdir)
	return _exe_dir().path_join(subdir)


func ensure_extracted() -> void:
	if OS.has_feature("editor"):
		return
	var bin_sub := "bin/windows" if OS.get_name() == "Windows" else "bin/linux"
	_extract_dir(bin_sub)
	_extract_dir("models")


func _extract_dir(subdir: String) -> void:
	var src := "res://" + subdir
	var dst := _exe_dir().path_join(subdir)
	DirAccess.make_dir_recursive_absolute(dst)
	var dir := DirAccess.open(src)
	if not dir:
		push_warning("[Config] cannot open: " + src)
		return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir():
			var dst_file := dst.path_join(fname)
			if not FileAccess.file_exists(dst_file):
				print("[Config] extracting: ", fname)
				_copy_file(src.path_join(fname), dst_file)
		fname = dir.get_next()
	dir.list_dir_end()


func _copy_file(src: String, dst: String) -> void:
	var f_in := FileAccess.open(src, FileAccess.READ)
	if not f_in:
		push_warning("[Config] cannot read: " + src)
		return
	var f_out := FileAccess.open(dst, FileAccess.WRITE)
	if not f_out:
		push_warning("[Config] cannot write: " + dst)
		return
	while f_in.get_position() < f_in.get_length():
		f_out.store_buffer(f_in.get_buffer(1_048_576))  # 1 MB chunks
