extends Control
#adb shell am start -n com.instantbits.cast.webvideo/.WebBrowser -d https://www3.animeflv.net/

func _on_button_pressed() -> void:
	pass
	#OS.shell_open("wvc-x-callback://open?url=https://www3.animeflv.net/")
	#var output = []
	#var code = OS.execute("am",[
		#"start",
		#"-n",
		#"com.instantbits.cast.webvideo/.WebBrowser",
		#"-d",
		#"https://www3.animeflv.net/"
	#],output,true,true)
	##var code = OS.execute("adb",[],output,true,true)
	#print(code,output)
