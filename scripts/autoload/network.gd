extends Node

const DEFAULT_PORT := 7777
const MAX_CLIENTS := 7

signal connected
signal connection_failed
signal disconnected
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)

var port: int = DEFAULT_PORT

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func start_offline() -> Error:
	var peer := OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = peer
	GameState.mode = GameState.Mode.OFFLINE
	return OK

func host_listen(p_port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(p_port, MAX_CLIENTS)
	if err != OK:
		return err
	port = p_port
	multiplayer.multiplayer_peer = peer
	GameState.mode = GameState.Mode.HOST
	return OK

func join(ip: String, p_port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip.strip_edges(), p_port)
	if err != OK:
		return err
	port = p_port
	multiplayer.multiplayer_peer = peer
	GameState.mode = GameState.Mode.CLIENT
	return OK

func shutdown() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	GameState.reset_session()

func lan_ips() -> PackedStringArray:
	var out := PackedStringArray()
	for a in IP.get_local_addresses():
		if a.begins_with("127.") or ":" in a or a.begins_with("169.254."):
			continue
		out.append(a)
	return out

func _on_connected() -> void:
	connected.emit()

func _on_connection_failed() -> void:
	shutdown()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	shutdown()
	disconnected.emit()

func _on_peer_connected(id: int) -> void:
	peer_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	peer_disconnected.emit(id)
