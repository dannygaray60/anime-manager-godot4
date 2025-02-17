extends Control

## icons
## https://fonts.google.com/icons?icon.category=UI+actions&selected=Material+Symbols+Outlined:menu:FILL@0;wght@400;GRAD@0;opsz@24&icon.size=24&icon.color=%23e8eaed
## material ui images
## https://www.google.com/search?client=firefox-b-d&sca_esv=2074af11bd466d63&sxsrf=AHTn8zrFy7O_94QukgPMTgh90qB3AXXGSA:1739654336675&q=material+ui+app+example&udm=2&fbs=ABzOT_BnMAgCWdhr5zilP5f1cnRvK9uZj3HA_MTJAA6lXR8yQIHhBi298nC38CQZOY2HEJbZvsLV77zEUv5_mptgx3dxu7alGxEWn27GN9liFjHwoLqfvuCM6MxwA4m6OosrwHGpcA90BNO4k19v2tGU63rkdwXtw3oJZnz7mM-v4sUbwpJlA761VvesLNvrgC8ZYXKnJnB9&sa=X&ved=2ahUKEwjk25O2zcaLAxVqhIQIHYSTPVIQtKgLegQIEBAB&biw=1920&bih=947&dpr=1#vhid=wFCYLED_nEKFwM&vssid=mosaic

var AnimePanel = preload("res://src/panel_main_anime.tscn")
var EpisodeButton = preload("res://src/button_episode.tscn")

var new_anime : Dictionary = {"website":"animeflv"}
var Cnf := ConfigFile.new()
var cnf_path : String = "user://database.ini"
var _err : int
var _url_anime : String

func _ready():
	$HTTPRequest.request_completed.connect(_on_request_completed)
	var _total_anime : int = 0
	## leer database
	if Cnf.load(cnf_path) == OK:
		for uuid_anime in Cnf.get_sections():
			var _anime_data_to_send : Dictionary
			_anime_data_to_send[uuid_anime] = {}
			_anime_data_to_send["uuid"] = uuid_anime
			for _section in Cnf.get_section_keys(uuid_anime):
				_anime_data_to_send[uuid_anime][_section] = Cnf.get_value(uuid_anime,_section)
			if _anime_data_to_send.is_empty() == false:
				add_anime_to_tree(_anime_data_to_send[uuid_anime],uuid_anime)
			_total_anime += 1
	%LblAnimeListResume.text = "Anime list (%d)" % [_total_anime]
	
	%ChkBtnUseWebVideoCastApp.set_pressed_no_signal(Config.Cnf.get_value("main","use_webvideocastapp",false)) 
	%ChkBtnHideUpToDate.set_pressed_no_signal(Config.Cnf.get_value("main","hide_uptodate",false))

## añadir anime a db local
## { "website": "animeflv", "uuid": "bf6cb088-84aa-4d3c-835a-19b49029a7e7", "name": "UniteUp! Uni:Birth", "img_url": "https://www3.animeflv.net/uploads/animes/covers/4127.jpg", "img_filename": "animeflv_4127.jpg", "description": "Segunda temporada UniteUp!" }
func add_anime_to_db(anime_data:Dictionary) -> int:
	
	if anime_data.size() < 3:
		return 1

	Cnf.load(cnf_path)
	
	##TODO comprobar duplicados
	
	Cnf.set_value(anime_data["uuid"], "name", anime_data["name"])
	Cnf.set_value(anime_data["uuid"], "website", anime_data["website"])
	Cnf.set_value(anime_data["uuid"], "anime_url", anime_data["anime_url"])
	Cnf.set_value(anime_data["uuid"], "current_episode", 0)
	Cnf.set_value(anime_data["uuid"], "description", anime_data["description"])
	Cnf.set_value(anime_data["uuid"], "img_url", anime_data["img_url"])
	Cnf.set_value(anime_data["uuid"], "img_filename", anime_data["img_filename"])
	_err = Cnf.save(cnf_path)
	
	if _err == OK:
		add_anime_to_tree(anime_data,anime_data["uuid"])
	
	return _err

## añadir anime panel al tree de la app
func add_anime_to_tree(animedata:Dictionary,uuid:String) -> void:
	var AnimePanelInstance = AnimePanel.instantiate()
	AnimePanelInstance.name = uuid
	AnimePanelInstance.uuid = uuid
	AnimePanelInstance.anime_data = animedata
	AnimePanelInstance.popup_requested.connect(_on_animepanel_seemore_requested)
	%GridAnimeItems.add_child(AnimePanelInstance)

## del xml dumpeado a string, retornar dict con datos de la serie
## uuid, name, img_url, img_filename(file.jpg), description
func get_anime_data(url_or_buffer:Variant) -> Dictionary:
	
	var uuid_util = load('res://src/scripts/uuid.gd')
	
	var xml : XMLDocument
	
	if url_or_buffer is String:
		xml = XML.parse_file(url_or_buffer)
	elif url_or_buffer is PackedByteArray:
		xml = XML.parse_buffer(url_or_buffer)
	
	#var xml_dict : Dictionary = xml.root.to_dict()
	var xml_str_dumped : String = xml.root.dump_str()
	
	var _dict : Dictionary = {
		"uuid": uuid_util.v4(),
		"name":"Unknown",
		"current_episode":0
	}
	var _txt : String
	var result : RegExMatch
	
	var regex = RegEx.new()
	regex.compile("(?<=var anime_info = )(.*?)(?=;)")
	## Si se encuentra una coincidencia
	result = regex.search(xml_str_dumped)
	if result:
		_txt = result.get_string()
		## ["4105","Ao no Exorcist: Yosuga-hen","ao-no-exorcist-yosugahen","2025-02-22"]
		var _dict_animeinfo : Array = str_to_var(_txt)
		_dict["name"] = _dict_animeinfo[1]
		_dict["img_url"] = "https://www3.animeflv.net/uploads/animes/covers/%d.jpg" % [int(_dict_animeinfo[0])]
		_dict["img_filename"] = "animeflv_%d.jpg" % [int(_dict_animeinfo[0])]
	else:
		OS.alert("Error scrapping")
		return {}
	
	var regex_c = RegEx.new()
	regex_c.compile('(?<=content=")(.*?)(?=">)')
	## Si se encuentra una coincidencia
	result = regex_c.search(xml_str_dumped)
	if result:
		_dict["description"] = result.get_string().strip_edges()
	
	return _dict

func _on_animepanel_seemore_requested(anime_data:Dictionary) -> void:
	for n in %VBxEpisodes.get_children():
		n.queue_free()
	%CtrlAnimeDetails.visible = true
	%LblTitle.text = anime_data["name"]
	%LblDescription.text = anime_data["description"]
	%TextureCoverAnime.texture = anime_data["cover_texture"]
	%LblCurrentEpisode.text = "%d" % [Cnf.get_value(anime_data["uuid"],"current_episode",0)]
	%BtnGoAnimeUrl.editor_description = anime_data["anime_url"]
	%BtnDeleteAnime.editor_description = anime_data["tree_node_name"]
	var _episodes_data : Dictionary = get_node(
		"%%GridAnimeItems/%s" % [%BtnDeleteAnime.editor_description]
	).episodes_data
	## "e_int":["Titulo","url"]
	for n in _episodes_data:
		var EpisodeButtonInstance = EpisodeButton.instantiate()
		EpisodeButtonInstance.number = int(n.replace("e_",""))
		EpisodeButtonInstance.title = _episodes_data[n][0]
		EpisodeButtonInstance.url = _episodes_data[n][1]
		EpisodeButtonInstance.watched.connect(
			self._on_episode_watched.bind(
				EpisodeButtonInstance.number,anime_data["uuid"]
			)
		)
		%VBxEpisodes.add_child(EpisodeButtonInstance)
	%LblEpisodesResume.text = "Episodes list (%d)" % [_episodes_data.size()]

func _on_episode_watched(number:int,uuid:String) -> void:
	_change_current_episode(str(number),uuid)

## request web de anime a añadir
func _on_request_completed(_result, response_code, _headers, body) -> void:
	%CtrlLoading.visible = false
	#response code: HTTPClient.RESPONSE_OK == 200
	if response_code != HTTPClient.RESPONSE_OK:
		OS.alert("Error scanning website Error Response code:%d"%[response_code])
		return
	new_anime.merge(get_anime_data(body))
	_err = add_anime_to_db(new_anime)
	if _err != OK:
		OS.alert("Error adding anime:%d"%[_err])

## -------- botones inferiores
## salir de app
func _on_btn_exit_pressed() -> void:
	get_tree().quit()
## mostrar popup añadir anime url
func _on_btn_add_anime_pressed() -> void:
	%LnUrl.text = ""
	%CtrlAddNewAnime.visible = true
## ocultar popup añadir anime url
func _on_btn_hide_add_new_anime_popup_pressed() -> void:
	%CtrlAddNewAnime.visible = false
## pegar clipboard a lineedit de añadir anime
func _on_btn_paste_clipboard_pressed() -> void:
	%LnUrl.text = DisplayServer.clipboard_get()
## ocultar popup de detalles del anime
func _on_btn_hide_anime_details_popup_pressed() -> void:
	%CtrlAnimeDetails.visible = false
## mostrar/ocultar popup de websites
func _on_btn_close_websites_pressed() -> void:
	%CtrlVisitWebsites.visible = false
func _on_btn_see_websites_pressed() -> void:
	%CtrlVisitWebsites.visible = true
## actualizar data de episodios en general de todos los animepanel
func _on_btn_refresh_episodes_data_pressed() -> void:
	get_tree().reload_current_scene()

## ir a la url del anime
func _on_btn_go_anime_url_pressed() -> void:
	if Config.Cnf.get_value("main","use_webvideocastapp",false) == true:
		OS.shell_open("wvc-x-callback://open?url=%s"%[%BtnGoAnimeUrl.editor_description])
	else:
		OS.shell_open(%BtnGoAnimeUrl.editor_description)
## borrar entrada de anime
func _on_btn_delete_anime_pressed() -> void:
	var uuid_to_delete : String = get_node(
		"%%GridAnimeItems/%s" % [%BtnDeleteAnime.editor_description]
	).uuid
	##TODO confirm action
	%CtrlAnimeDetails.visible = false
	## borrar cover
	if Cnf.get_value(uuid_to_delete,"img_filename","") != "":
		DirAccess.remove_absolute(
			"user://covers/%s" % [Cnf.get_value(uuid_to_delete,"img_filename")]
		)
	## borrar de db
	Cnf.erase_section(uuid_to_delete)
	Cnf.save(cnf_path)
	get_node(
		"%%GridAnimeItems/%s" % [%BtnDeleteAnime.editor_description]
	).queue_free()
	
## aumentar o decrementar current_episode, usar + o -
func _change_current_episode(opt:String="+",uuid:String="") -> void:
	var _current : int = Cnf.get_value(uuid,"current_episode",0)
	if opt == "+":
		_current += 1
	elif opt == "-" and _current > 0:
		_current -= 1
	elif opt.is_valid_int():
		_current = int(opt)
	Cnf.set_value(uuid,"current_episode",_current)
	Cnf.save(cnf_path)
	%LblCurrentEpisode.text = "%d" % [_current]
	get_node(
		"%%GridAnimeItems/%s" % [uuid]
	).anime_data["current_episode"] = _current
	get_node(
		"%%GridAnimeItems/%s" % [uuid]
	).refresh_main_panel_info()
	
	
## señales de los botones
func _on_btn_decrease_current_episode_pressed() -> void:
	_change_current_episode("-",%BtnDeleteAnime.editor_description)
func _on_btn_increase_current_episode_pressed() -> void:
	_change_current_episode("+",%BtnDeleteAnime.editor_description)

## añadir anime de la url proporcionada
func _on_btn_add_anime_url_pressed() -> void:
	%CtrlAddNewAnime.visible = false
	%CtrlLoading.visible = true
	var anime_url : String = %LnUrl.text.strip_edges()
	
	if anime_url.begins_with("res://"):
		pass ## debug
	elif anime_url.is_empty() or anime_url.begins_with("http") == false:
		%CtrlLoading.visible = false
		OS.alert("Not Valid Url")
		return
	
	if anime_url.contains("animeflv.net"):
		## url para visitar
		new_anime["anime_url"] = anime_url
		## reemplazar version mobile a web en link a hacer request
		anime_url = anime_url.replace("https://m.","https://www3.")
		## sitioweb utilizado
		new_anime["website"] = "animeflv"
	else:
		%CtrlLoading.visible = false
		OS.alert("Website can't be scanned.")
		return
	
	#_url_anime = anime_url
	
	if anime_url.begins_with("res://"):
		## debug
		new_anime.merge(get_anime_data(anime_url))
		add_anime_to_db(new_anime)
		%CtrlLoading.visible = false
	else:
		var headers : PackedStringArray
		## añadir user agent de pc para forzar la version pc en animeflv si estamos en mobile
		if OS.has_feature("mobile") == true:
			headers = ["User-Agent:Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:135.0) Gecko/20100101 Firefox/135.0"]
		$HTTPRequest.request(anime_url,headers)


func _on_chk_btn_hide_up_to_date_toggled(toggled_on: bool) -> void:
	Config.Cnf.set_value("main","hide_uptodate",toggled_on)
	Config.Cnf.save(Config.cnf_path)
	get_tree().call_group("anime_panel","hide_if_uptodate")
func _on_chk_btn_use_web_video_cast_app_toggled(toggled_on: bool) -> void:
	Config.Cnf.set_value("main","use_webvideocastapp",toggled_on)
	Config.Cnf.save(Config.cnf_path)


## abrir/cerrar ajustes
func _on_btn_close_settings_pressed() -> void:
	%CtrlSettings.visible = false
func _on_btn_open_settings_pressed() -> void:
	%CtrlSettings.visible = true


func _on_website_goto(website: String) -> void:
	var url : String
	match website:
		"animeflv":
			if OS.has_feature("mobile") == true:
				url = "https://m.animeflv.net/"
			else:
				url = "https://www3.animeflv.net/"
	if Config.Cnf.get_value("main","use_webvideocastapp",false) == true:
		OS.shell_open("wvc-x-callback://open?url=%s"%[url])
	else:
		OS.shell_open(url)
