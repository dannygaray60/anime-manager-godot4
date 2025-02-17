extends HBoxContainer

@warning_ignore("unused_signal")
signal watched

var number : int = 0
var title : String
var url : String

func _ready() -> void:
	$Label.text = title
	$BtnGo.text = "Watch %d" % [number]

func _on_btn_go_pressed() -> void:
	emit_signal("watched")
	if Config.Cnf.get_value("main","use_webvideocastapp",false) == true:
		OS.shell_open("wvc-x-callback://open?url=%s"%[url])
	else:
		OS.shell_open(url)
