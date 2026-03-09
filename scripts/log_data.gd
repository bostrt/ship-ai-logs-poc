class_name LogData

const LOGS: Array[Dictionary] = [
	{"time": "12:00:00", "system": "REACTOR", "message": "Reactor output nominal at 88%."},
	{"time": "12:01:15", "system": "COOLING", "message": "Cooling pump 3 pressure drop detected."},
	{"time": "12:01:42", "system": "COOLING", "message": "Cooling pump 3 offline. Switching to backup routing."},
	{"time": "12:02:10", "system": "THERMAL", "message": "Hull section C temperature rising. Currently 42°C."},
	{"time": "12:02:38", "system": "REACTOR", "message": "Reactor output climbing: 96%."},
	{"time": "12:03:05", "system": "THERMAL", "message": "Hull section C temperature critical: 68°C."},
	{"time": "12:03:22", "system": "REACTOR", "message": "Reactor output: 104%. Exceeding safe operating parameters."},
	{"time": "12:03:30", "system": "REACTOR", "message": "Automatic SCRAM triggered. Reactor shutdown initiated."},
	{"time": "12:03:45", "system": "POWER", "message": "Main power offline. Emergency batteries engaged."},
	{"time": "12:04:00", "system": "LIFE_SUPPORT", "message": "Life support switching to low-power mode."},
]


static func get_plain_text() -> String:
	var lines := PackedStringArray()
	for entry in LOGS:
		lines.append("[%s] %s: %s" % [entry.time, entry.system, entry.message])
	return "\n".join(lines)


static func get_bbcode() -> String:
	var lines := PackedStringArray()
	for entry in LOGS:
		var color := _system_color(entry.system)
		lines.append("[color=#888888][%s][/color] [color=%s]%s:[/color] %s" % [
			entry.time, color, entry.system, entry.message
		])
	return "\n".join(lines)


static func _system_color(system: String) -> String:
	match system:
		"REACTOR":
			return "#ff6666"
		"COOLING":
			return "#6699ff"
		"THERMAL":
			return "#ffaa33"
		"POWER":
			return "#ffff66"
		"LIFE_SUPPORT":
			return "#66ff66"
		_:
			return "#aaaaaa"
