extends Node
class_name MainGame

const TEST_ROOM_UID : String = "uid://dc3fng2b6qkvg"

const PLAYER_SCENE_UID : String = "uid://13hsnihbrg14"

var player : Player
var current_room : Room

@onready var systems: Node = %Systems
@onready var level_root: Node = %LevelRoot
@onready var dialogue_box: CanvasLayer = %DialogueBox
@onready var gui: CanvasLayer = %Gui
@onready var room_transitioner: CanvasLayer = %RoomTransitioner


func _ready() -> void:
	load_room(TEST_ROOM_UID)


func load_room(room_scene : String, player_spawner_index : int = 0):
	deferred_load_room.call_deferred(room_scene, player_spawner_index)


func deferred_load_room(room_scene_uid : String, player_spawner_index : int = 0):
	#unload current level if a level already exists
	if current_room != null:
		current_room.queue_free()
		current_room = null
		await get_tree().process_frame
	
	init_player()
	
	var new_room_packed : PackedScene = ResourceLoader.load(room_scene_uid, "PackedScene")
	if new_room_packed == null:
		push_error("Could not load room as a packed scene: " + room_scene_uid)
		return
	
	var new_room = new_room_packed.instantiate() as Room
	if !new_room:
		push_error("Could not instantiate room: " + room_scene_uid)
		return
	
	if not new_room is Room:
		push_error("Loaded scene is not of type Room")
		return
	
	current_room = new_room as Room
	level_root.add_child(current_room)
	
	set_player_spawn_position(player_spawner_index)
	
	if current_room.camera:
		current_room.camera.following_object = player
		current_room.camera.reset_position()


func init_player():
	var player_scene : PackedScene = ResourceLoader.load(PLAYER_SCENE_UID) as PackedScene
	if player_scene == null:
		push_error("Could not load player scene: " + PLAYER_SCENE_UID)
		return
	
	player = player_scene.instantiate() as Player
	if player == null:
		push_error("Loaded player scene does not extend player or does not exist: " + PLAYER_SCENE_UID)
		return


func set_player_spawn_position(player_spawner_index : int = 0):
	var player_spawner = current_room.player_spawn_points.get_child(player_spawner_index) as PlayerSpawner
	if player_spawner == null:
		push_error("Player spawner node not set properly in room: " + str(player_spawner_index))
		return
	
	player.global_position = player_spawner.global_position
	player.direction_x = player_spawner.direction
	current_room.add_child(player)
	current_room.move_child(player, 0)
	current_room.player = player
