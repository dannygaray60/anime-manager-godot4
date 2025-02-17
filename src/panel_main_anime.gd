extends PanelContainer

signal popup_requested(animedata:String)

var uuid : String
var anime_data : Dictionary
var episodes_data : Dictionary
var _current_episode : int = 0
var _last_episode : int = 0

func _ready() -> void:
	%LblTitle.text = anime_data["name"]
	check_anime_cover()
	refresh_episodes_data()
	#refresh_main_panel_info()

func hide_if_uptodate() -> void:
	if (
		Config.Cnf.get_value("main","hide_uptodate",false) == true
		and _current_episode >= _last_episode
	):
		visible = false
	else:
		visible = true
	

func refresh_main_panel_info() -> void:

	_current_episode = anime_data["current_episode"]
	%LblEpisodesInfo.text = "Current: %d  / Last: %d" % [_current_episode,_last_episode]
	
	if _current_episode < _last_episode:
		%BtnSeeMore.visible = true
		%BtnSeeMore2.visible = false
	else:
		%BtnSeeMore.visible = false
		%BtnSeeMore2.visible = true
	
	%ProgressBar.max_value = _last_episode
	%ProgressBar.value = _current_episode
	
	hide_if_uptodate()

func check_anime_cover() -> void:
	
	if DirAccess.dir_exists_absolute("user://covers") == false:
		DirAccess.make_dir_absolute("user://covers")
	
	## cover no existe, crearlo
	if FileAccess.file_exists("user://covers/%s"%[anime_data["img_filename"]]) == false:
		var Request = HTTPRequest.new()
		add_child(Request)
		Request.request_completed.connect(self._on_http_img_request_completed)
		Request.set_download_file("user://covers/%s"%[anime_data["img_filename"]])
		Request.request(anime_data["img_url"])
	## cover existe, ponerlo en el nodo
	else:
		_refresh_img()

func refresh_episodes_data() -> void:
	var headers : PackedStringArray
	var _anime_url = anime_data["anime_url"]
	_anime_url = _anime_url.replace("https://m.","https://www3.")
	## añadir user agent de pc para forzar la version pc en animeflv si estamos en mobile
	if OS.has_feature("mobile") == true:
		headers = ["User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:135.0) Gecko/20100101 Firefox/135.0"]
	$HTTPRequest.request(_anime_url,headers)

func _refresh_img() -> void:
	var cover_path : String = "user://covers/%s"%[anime_data["img_filename"]]
	var image = Image.load_from_file(cover_path)
	%TextureCover.texture = ImageTexture.create_from_image(image)

func _on_http_img_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == OK and response_code == HTTPClient.RESPONSE_OK:
		_refresh_img()

func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == OK and response_code == HTTPClient.RESPONSE_OK:
		episodes_data = get_anime_episodes(body)
		_last_episode = episodes_data.size()
		refresh_main_panel_info()
	else:
		OS.alert("Error scanning website Error Response code:%d"%[response_code])
		return
	
## obtener episodios "e_int":["Titulo","url"]
func get_anime_episodes(url_or_buffer:Variant) -> Dictionary:
	var episodes : Dictionary
	var result : RegExMatch
	var xml : XMLDocument
	var _txt : String
	var _animestring_id_url : String
	
	if url_or_buffer is String:
		xml = XML.parse_file(url_or_buffer)
	elif url_or_buffer is PackedByteArray:
		xml = XML.parse_buffer(url_or_buffer)
	
	var xml_str_dumped : String = xml.root.dump_str()
	
	var regex = RegEx.new()
	regex.compile("(?<=var anime_info = )(.*?)(?=;)")
	## Si se encuentra una coincidencia
	result = regex.search(xml_str_dumped)
	if result:
		_txt = result.get_string()
		var _dict_animeinfo : Array = str_to_var(_txt)
		## ["4105","Ao no Exorcist: Yosuga-hen","ao-no-exorcist-yosugahen","2025-02-22"]
		_animestring_id_url = _dict_animeinfo[2]
	
	var regex_b = RegEx.new()
	regex_b.compile("(?<=var episodes = )(.*?)(?=;)")
	## Si se encuentra una coincidencia
	result = regex_b.search(xml_str_dumped)
	if result:
		_txt = result.get_string()
		## [[7,66373],[6,66315],[5,66248],[4,66191],[3,66133],[2,66076],[1,66023]]
		var _arr_episodes : Array = str_to_var(_txt)
		#_arr_episodes.reverse()
		var _url_to_return : String = "https://www3.animeflv.net/ver/%s-%d"
		if OS.has_feature("mobile") == true:
			_url_to_return = "https://m.animeflv.net/ver/%s-%d"
		for n in _arr_episodes:
			episodes["e_%d"%[n[0]]] = [
				"Episode %d"%[n[0]],
				_url_to_return % [_animestring_id_url,n[0]]
			]
	
	return episodes

func _on_btn_see_more_pressed() -> void:
	var anime_data_send : Dictionary = anime_data
	## adjuntar la textura del cover
	anime_data_send["cover_texture"] = %TextureCover.texture
	## adjuntar el uuid de la base de datos local
	anime_data_send["uuid"] = uuid
	## adjuntar nombre del nodo en el tree
	anime_data_send["tree_node_name"] = name
	emit_signal("popup_requested",anime_data_send)
