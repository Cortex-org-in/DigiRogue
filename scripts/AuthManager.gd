extends Node

# ─────────────────────────────────────────────────────
#  AUTHMANAGER — Google Auth + Firestore cloud save
#  Web: bridges to Firebase JS SDK via JavaScriptBridge.
#  Desktop: native OAuth 2.0 with PKCE + Firestore REST API.
# ─────────────────────────────────────────────────────

signal auth_changed(user_info: Dictionary)

const FIREBASE_PROJECT = "fir-1-82a66"
const TOKEN_SAVE_PATH = "user://auth_tokens.json"

var CLIENT_ID: String = ""
var CLIENT_SECRET: String = ""

var is_web: bool = false
var current_user: Dictionary = {}

# Desktop OAuth state
var _callback_port: int = 18321
var _code_verifier: String
var _oauth_state: String
var _auth_timer: Timer
var _poll_timer: Timer
var _access_token: String = ""
var _refresh_token: String = ""
var _token_expiry: int = 0
var _is_processing_callback: bool = false
var _callback_file: String = ""
var _ps_process_id: int = -1

func _ready():
	var cfg = ConfigFile.new()
	if cfg.load("res://config.cfg") == OK:
		CLIENT_ID = cfg.get_value("auth", "client_id", "")
		CLIENT_SECRET = cfg.get_value("auth", "client_secret", "")
	is_web = OS.has_feature("web")
	if not is_web:
		_load_tokens()

# ─────────────────────────────────────────────────────
#  PUBLIC API
# ─────────────────────────────────────────────────────

func is_logged_in() -> bool:
	if is_web:
		return _is_logged_in_web()
	return _is_logged_in_desktop()

func login_google():
	auth_changed.emit({"_loading": true})
	if is_web:
		_login_web()
	else:
		await _login_desktop()

func logout():
	if is_web:
		_eval("window.firebaseLogout()")
	_kill_callback_server()
	_access_token = ""
	_refresh_token = ""
	_token_expiry = 0
	current_user = {}
	if not is_web and FileAccess.file_exists(TOKEN_SAVE_PATH):
		DirAccess.remove_absolute(TOKEN_SAVE_PATH)
	auth_changed.emit({})
	print("AuthManager: Logged out")

func save_to_cloud(data: Dictionary) -> bool:
	if is_web:
		return await _save_to_cloud_web(data)
	return await _save_to_cloud_desktop(data)

func load_from_cloud() -> Dictionary:
	if is_web:
		return await _load_from_cloud_web()
	return await _load_from_cloud_desktop()

# ─────────────────────────────────────────────────────
#  WEB AUTH (Firebase JS SDK — unchanged)
# ─────────────────────────────────────────────────────

func _eval(code: String):
	if is_web:
		return JavaScriptBridge.eval(code, true)
	return null

func _is_logged_in_web() -> bool:
	var raw = _eval("window.getCurrentUser()")
	if raw == null or raw == "" or raw == "null":
		current_user = {}
		return false
	var dict = JSON.parse_string(str(raw))
	if dict != null and typeof(dict) == TYPE_DICTIONARY and dict.size() > 0:
		current_user = dict
		return true
	current_user = {}
	return false

func _login_web():
	_eval("window._authResult = null; window.googleLogin().then(function(r){ window._authResult = JSON.stringify(r); }).catch(function(e){ window._authResult = JSON.stringify({error: e.message || e}); });")

	if _auth_timer and is_instance_valid(_auth_timer):
		_auth_timer.stop()
	_auth_timer = Timer.new()
	add_child(_auth_timer)
	_auth_timer.wait_time = 0.2
	_auth_timer.one_shot = false
	_auth_timer.timeout.connect(_check_web_auth_result)
	_auth_timer.start()

	await get_tree().create_timer(30.0).timeout
	if _auth_timer and is_instance_valid(_auth_timer):
		_auth_timer.stop()
		_auth_timer.queue_free()
		_auth_timer = null
		current_user = {}
		auth_changed.emit({})
		push_warning("AuthManager: Login timed out")

func _check_web_auth_result():
	var raw = _eval("window._authResult")
	if raw == null or raw == "":
		return
	if _auth_timer and is_instance_valid(_auth_timer):
		_auth_timer.stop()
		_auth_timer.queue_free()
		_auth_timer = null
	_eval("window._authResult = null")
	var dict = JSON.parse_string(str(raw))
	if dict != null and typeof(dict) == TYPE_DICTIONARY:
		if dict.has("error"):
			push_warning("AuthManager: Login failed: " + str(dict["error"]))
			current_user = {}
			auth_changed.emit({})
		else:
			current_user = dict
			print("AuthManager: Logged in as ", current_user.get("email", "unknown"))
			auth_changed.emit(current_user)
	else:
		current_user = {}
		auth_changed.emit({})

# ─────────────────────────────────────────────────────
#  DESKTOP AUTH (Native OAuth 2.0 + PKCE)
# ─────────────────────────────────────────────────────

func _kill_callback_server():
	if _ps_process_id > 0:
		OS.kill(_ps_process_id)
		_ps_process_id = -1
	_callback_file = OS.get_user_data_dir().replace("\\", "/") + "/oauth_callback.txt"
	if FileAccess.file_exists(_callback_file):
		DirAccess.remove_absolute(_callback_file)

func _is_logged_in_desktop() -> bool:
	return _access_token != "" and not current_user.is_empty()

func _login_desktop():
	# Clean up any existing login attempt
	if _poll_timer and is_instance_valid(_poll_timer):
		_poll_timer.stop()
		_poll_timer.queue_free()
		_poll_timer = null
	_is_processing_callback = false

	# Kill any leftover OAuth callback server process
	_kill_callback_server()

	# Clean up old callback file
	_callback_file = OS.get_user_data_dir().replace("\\", "/") + "/oauth_callback.txt"
	if FileAccess.file_exists(_callback_file):
		DirAccess.remove_absolute(_callback_file)

	# Generate PKCE code verifier and challenge
	_code_verifier = _generate_code_verifier()
	var code_challenge = _generate_code_challenge(_code_verifier)
	_oauth_state = _generate_random_state()

	# Launch PowerShell OAuth callback server as subprocess
	var script_path = ProjectSettings.globalize_path("res://scripts/oauth_callback_server.ps1")
	var output_file = _callback_file
	var ps_args = ["-ExecutionPolicy", "Bypass", "-NoProfile", "-File", script_path, "-Port", str(_callback_port), "-OutputFile", output_file]
	_ps_process_id = OS.create_process("powershell.exe", ps_args)
	print("AuthManager: Launched OAuth callback server on port %d (PID %d)" % [_callback_port, _ps_process_id])

	# Build Google OAuth URL with PKCE
	var redirect_uri = "http://localhost:%d" % _callback_port
	var auth_url = "https://accounts.google.com/o/oauth2/v2/auth"
	auth_url += "?client_id=" + CLIENT_ID.uri_encode()
	auth_url += "&redirect_uri=" + redirect_uri.uri_encode()
	auth_url += "&response_type=code"
	auth_url += "&scope=" + "openid email profile".uri_encode()
	auth_url += "&code_challenge=" + code_challenge.uri_encode()
	auth_url += "&code_challenge_method=S256"
	auth_url += "&state=" + _oauth_state.uri_encode()

	# Open browser
	OS.shell_open(auth_url)
	print("AuthManager: Opened browser for Google login")

	# Start polling for the callback file
	_poll_timer = Timer.new()
	add_child(_poll_timer)
	_poll_timer.wait_time = 0.5
	_poll_timer.one_shot = false
	_poll_timer.timeout.connect(_poll_desktop_callback)
	_poll_timer.start()

	# Safety timeout — clean up after 120 seconds if no callback
	await get_tree().create_timer(120.0).timeout
	if _poll_timer and is_instance_valid(_poll_timer):
		_poll_timer.stop()
		_poll_timer.queue_free()
		_poll_timer = null
	if current_user.is_empty():
		current_user = {}
		auth_changed.emit({})
		push_warning("AuthManager: Desktop login timed out")

func _poll_desktop_callback():
	if _is_processing_callback:
		return

	# Check if callback file exists
	if not FileAccess.file_exists(_callback_file):
		return

	# Read the callback URL
	var file = FileAccess.open(_callback_file, FileAccess.READ)
	if file == null:
		return
	var callback_url = file.get_as_text().strip_edges()
	file.close()

	print("AuthManager: Found callback file, URL length: ", callback_url.length())

	# Parse auth code and state from URL
	var auth_code = _parse_url_param(callback_url, "code")
	var returned_state = _parse_url_param(callback_url, "state")

	# Clean up callback file
	DirAccess.remove_absolute(_callback_file)

	print("AuthManager: auth_code empty: ", auth_code == "", " state match: ", returned_state == _oauth_state)

	if auth_code == "" or returned_state != _oauth_state:
		push_warning("AuthManager: Invalid callback — state mismatch or missing code")
		print("AuthManager: Stale/invalid callback, discarding and continuing to poll...")
		return

	# Valid callback — stop polling
	_is_processing_callback = true
	if _poll_timer and is_instance_valid(_poll_timer):
		_poll_timer.stop()
		_poll_timer.queue_free()
		_poll_timer = null

	# Exchange auth code for tokens
	await _exchange_code_for_tokens(auth_code)
	_is_processing_callback = false

func _parse_url_param(url: String, param_name: String) -> String:
	var query_start = url.find("?")
	if query_start == -1:
		return ""
	var query = url.substr(query_start + 1)
	for p in query.split("&"):
		var eq = p.find("=")
		if eq == -1:
			continue
		var key = p.substr(0, eq)
		var value = p.substr(eq + 1)
		if key == param_name:
			return value.uri_decode()
	return ""

func _exchange_code_for_tokens(auth_code: String):
	var redirect_uri = "http://localhost:%d" % _callback_port

	var http = HTTPRequest.new()
	add_child(http)

	print("AuthManager: Token exchange redirect_uri: ", redirect_uri)

	var body = "code=%s&client_id=%s&client_secret=%s&redirect_uri=%s&grant_type=authorization_code&code_verifier=%s" % [
		auth_code.uri_encode(),
		CLIENT_ID.uri_encode(),
		CLIENT_SECRET.uri_encode(),
		redirect_uri.uri_encode(),
		_code_verifier.uri_encode()
	]

	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	http.request("https://oauth2.googleapis.com/token", headers, HTTPClient.METHOD_POST, body)

	var result = await http.request_completed
	var response_code = result[1]
	var response_body = result[3]
	http.queue_free()

	if response_code != 200:
		var err_text = response_body.get_string_from_utf8()
		push_error("AuthManager: Token exchange failed (HTTP %d): %s" % [response_code, err_text])
		print("AuthManager: Token exchange FAILED - HTTP ", response_code, " - ", err_text)
		current_user = {}
		auth_changed.emit({})
		return

	print("AuthManager: Token exchange OK, fetching user info...")

	var json = JSON.parse_string(response_body.get_string_from_utf8())
	if json == null or not json.has("access_token"):
		push_error("AuthManager: Invalid token response")
		current_user = {}
		auth_changed.emit({})
		return

	_access_token = json["access_token"]
	_refresh_token = json.get("refresh_token", "")
	_token_expiry = Time.get_unix_time_from_system() + json.get("expires_in", 3600) - 60

	# Fetch user info from Google
	await _fetch_user_info()

func _fetch_user_info():
	print("AuthManager: _fetch_user_info called")
	var http = HTTPRequest.new()
	add_child(http)

	var headers = ["Authorization: Bearer " + _access_token]
	http.request("https://www.googleapis.com/oauth2/v2/userinfo", headers, HTTPClient.METHOD_GET)

	var result = await http.request_completed
	var response_code = result[1]
	var response_body = result[3]
	http.queue_free()

	if response_code != 200:
		push_error("AuthManager: Failed to fetch user info (HTTP %d)" % response_code)
		current_user = {}
		auth_changed.emit({})
		return

	var json = JSON.parse_string(response_body.get_string_from_utf8())
	if json == null:
		push_error("AuthManager: Invalid user info response")
		current_user = {}
		auth_changed.emit({})
		return

	current_user = {
		"uid": json.get("id", ""),
		"email": json.get("email", ""),
		"displayName": json.get("name", "")
	}

	_save_tokens()
	print("AuthManager: Logged in as ", current_user.get("email", "unknown"))
	auth_changed.emit(current_user)

func _refresh_access_token() -> bool:
	if _refresh_token == "":
		return false

	var http = HTTPRequest.new()
	add_child(http)

	var body = "client_id=%s&refresh_token=%s&grant_type=refresh_token" % [
		CLIENT_ID.uri_encode(),
		_refresh_token.uri_encode()
	]

	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	http.request("https://oauth2.googleapis.com/token", headers, HTTPClient.METHOD_POST, body)

	var result = await http.request_completed
	var response_code = result[1]
	var response_body = result[3]
	http.queue_free()

	if response_code != 200:
		push_warning("AuthManager: Token refresh failed — please log in again")
		_access_token = ""
		_refresh_token = ""
		_token_expiry = 0
		current_user = {}
		if FileAccess.file_exists(TOKEN_SAVE_PATH):
			DirAccess.remove_absolute(TOKEN_SAVE_PATH)
		return false

	var json = JSON.parse_string(response_body.get_string_from_utf8())
	if json == null or not json.has("access_token"):
		return false

	_access_token = json["access_token"]
	_token_expiry = Time.get_unix_time_from_system() + json.get("expires_in", 3600) - 60
	_save_tokens()
	return true

# ─────────────────────────────────────────────────────
#  TOKEN PERSISTENCE (desktop only)
# ─────────────────────────────────────────────────────

func _save_tokens():
	var data = {
		"access_token": _access_token,
		"refresh_token": _refresh_token,
		"token_expiry": _token_expiry,
		"user": current_user,
	}
	var file = FileAccess.open(TOKEN_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_tokens():
	if not FileAccess.file_exists(TOKEN_SAVE_PATH):
		return
	var file = FileAccess.open(TOKEN_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null or not json is Dictionary:
		return
	_access_token = json.get("access_token", "")
	_refresh_token = json.get("refresh_token", "")
	_token_expiry = json.get("token_expiry", 0)
	current_user = json.get("user", {})

# ─────────────────────────────────────────────────────
#  PKCE & STATE GENERATION
# ─────────────────────────────────────────────────────

func _generate_code_verifier() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
	var result = ""
	for i in range(128):
		result += chars[randi() % chars.length()]
	return result

func _generate_code_challenge(verifier: String) -> String:
	var sha256 = HashingContext.new()
	sha256.start(HashingContext.HASH_SHA256)
	sha256.update(verifier.to_utf8_buffer())
	var hash = sha256.finish()
	return Marshalls.raw_to_base64(hash).replace("+", "-").replace("/", "_").rstrip("=")

func _generate_random_state() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	var result = ""
	for i in range(32):
		result += chars[randi() % chars.length()]
	return result

# ─────────────────────────────────────────────────────
#  WEB CLOUD SAVE/LOAD (Firebase JS SDK — unchanged)
# ─────────────────────────────────────────────────────

func _save_to_cloud_web(data: Dictionary) -> bool:
	if not current_user.has("uid"):
		return false
	var json_data = JSON.stringify(data)
	var uid = current_user["uid"]
	var key = "_save_" + str(Time.get_ticks_msec())
	_eval("window.firestoreSave('%s', %s).then(function(r){ window['%s'] = JSON.stringify(r); }).catch(function(e){ window['%s'] = JSON.stringify({ok:false, error:e.message}); });" % [uid, json_data, key, key])
	await get_tree().create_timer(2.0).timeout
	var raw = _eval("window['%s']" % key)
	if raw != null and raw != "":
		_eval("delete window['%s']" % key)
		var dict = JSON.parse_string(str(raw))
		if dict != null and typeof(dict) == TYPE_DICTIONARY:
			return dict.get("ok", false)
	_eval("delete window['%s']" % key)
	return false

func _load_from_cloud_web() -> Dictionary:
	if not current_user.has("uid"):
		return {}
	var uid = current_user["uid"]
	var key = "_load_" + str(Time.get_ticks_msec())
	_eval("window.firestoreLoad('%s').then(function(r){ window['%s'] = JSON.stringify(r); }).catch(function(e){ window['%s'] = JSON.stringify({ok:false, error:e.message}); });" % [uid, key, key])
	await get_tree().create_timer(3.0).timeout
	var raw = _eval("window['%s']" % key)
	if raw != null and raw != "":
		_eval("delete window['%s']" % key)
		var dict = JSON.parse_string(str(raw))
		if dict != null and typeof(dict) == TYPE_DICTIONARY:
			if dict.get("ok", false) and dict.has("data"):
				var d = dict["data"]
				if typeof(d) == TYPE_DICTIONARY:
					return d
	_eval("delete window['%s']" % key)
	return {}

# ─────────────────────────────────────────────────────
#  DESKTOP CLOUD SAVE/LOAD (Firestore REST API)
# ─────────────────────────────────────────────────────

func _save_to_cloud_desktop(data: Dictionary) -> bool:
	if not current_user.has("uid") or _access_token == "":
		return false
	# Refresh token if expired
	if Time.get_unix_time_from_system() >= _token_expiry:
		if not await _refresh_access_token():
			return false
	var uid = current_user["uid"]
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [FIREBASE_PROJECT, uid]
	var http = HTTPRequest.new()
	add_child(http)
	var firestore_data = _dict_to_firestore(data)
	var body = JSON.stringify(firestore_data)
	var headers = [
		"Authorization: Bearer " + _access_token,
		"Content-Type: application/json",
	]
	http.request(url, headers, HTTPClient.METHOD_PATCH, body)
	var result = await http.request_completed
	http.queue_free()
	var response_code = result[1]
	if response_code == 401:
		if await _refresh_access_token():
			return await _save_to_cloud_desktop(data)
		return false
	return response_code == 200

func _load_from_cloud_desktop() -> Dictionary:
	if not current_user.has("uid") or _access_token == "":
		return {}
	# Refresh token if expired
	if Time.get_unix_time_from_system() >= _token_expiry:
		if not await _refresh_access_token():
			return {}
	var uid = current_user["uid"]
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/users/%s" % [FIREBASE_PROJECT, uid]
	var http = HTTPRequest.new()
	add_child(http)
	var headers = ["Authorization: Bearer " + _access_token]
	http.request(url, headers, HTTPClient.METHOD_GET)
	var result = await http.request_completed
	http.queue_free()
	var response_code = result[1]
	var response_body = result[3]
	if response_code == 401:
		if await _refresh_access_token():
			return await _load_from_cloud_desktop()
		return {}
	if response_code == 404:
		return {}
	if response_code != 200:
		return {}
	var json = JSON.parse_string(response_body.get_string_from_utf8())
	if json == null:
		return {}
	return _firestore_to_dict(json)

# ─────────────────────────────────────────────────────
#  FIRESTORE FORMAT CONVERSION
# ─────────────────────────────────────────────────────

func _dict_to_firestore(data: Dictionary) -> Dictionary:
	var fields = {}
	for key in data.keys():
		var value = data[key]
		if value is int:
			fields[key] = {"integerValue": str(value)}
		elif value is float:
			fields[key] = {"doubleValue": value}
		elif value is String:
			fields[key] = {"stringValue": value}
		elif value is bool:
			fields[key] = {"booleanValue": value}
		elif value is Dictionary:
			fields[key] = {"mapValue": _dict_to_firestore(value)}
		elif value is Array:
			var array_values = []
			for item in value:
				if item is Dictionary:
					array_values.append(_dict_to_firestore(item))
				elif item is int:
					array_values.append({"integerValue": str(item)})
				else:
					array_values.append({"stringValue": str(item)})
			fields[key] = {"arrayValue": {"values": array_values}}
	return {"fields": fields}

func _firestore_to_dict(doc: Dictionary) -> Dictionary:
	var result = {}
	var fields = doc.get("fields", {})
	for key in fields.keys():
		var field = fields[key]
		if field.has("integerValue"):
			result[key] = int(field["integerValue"])
		elif field.has("doubleValue"):
			result[key] = field["doubleValue"]
		elif field.has("stringValue"):
			result[key] = field["stringValue"]
		elif field.has("booleanValue"):
			result[key] = field["booleanValue"]
		elif field.has("mapValue"):
			result[key] = _firestore_to_dict(field["mapValue"])
		elif field.has("arrayValue"):
			var arr = []
			for item in field["arrayValue"].get("values", []):
				if item.has("mapValue"):
					arr.append(_firestore_to_dict(item["mapValue"]))
				elif item.has("stringValue"):
					arr.append(item["stringValue"])
				elif item.has("integerValue"):
					arr.append(int(item["integerValue"]))
			result[key] = arr
	return result
