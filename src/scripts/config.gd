extends Node
var Cnf := ConfigFile.new()
var cnf_path : String = "user://settings.ini"
var _err : int

var current_website : String

func _ready() -> void:
	if Cnf.load(cnf_path) == OK:
		Cnf.save(cnf_path)
