extends KinematicBody2D

export (NodePath) var joystick_one_path;
export (NodePath) var joystick_two_path;

var joystick_one;
var joystick_two;

const MOVE_SPEED: int = 300;
const JOYSTICK_DEADZONE = 0.4;

const speed: int = 300

var hp: int = 100 setget set_hp
#var bullets: int = 6
var velocity: Vector2 = Vector2(0, 0)
var can_shoot: bool = true
var is_reloading: bool = false
#var _reloading_: bool =  false

var player_bullet = load("res://Player_bullet.tscn")
var username_text = load("res://Username_text.tscn")

var username setget username_set
var username_text_instance = null

puppet var puppet_hp = 100 setget puppet_hp_set
puppet var puppet_position = Vector2(0, 0) setget puppet_position_set
puppet var puppet_velocity = Vector2()
puppet var puppet_rotation = 0
puppet var puppet_username = "" setget puppet_username_set

var handgun = {
	magazine = 6,
	in_gun = 6,
	bullets = 6,
	reload_time = 3.5,
	damage = 10,
	time_to_shoot = 0.50,
	region = Rect2(512, 1500, 256, 250),
	ability = null
}

var revolver = {
	magazine = 6,
	in_gun = 6,
	bullets = 6,
	reload_time = 4.5,
	damage = 20,
	time_to_shoot = 1,
	region = Rect2(512, 2247, 256, 250),
	ability = null
}

var uzi = {
	magazine = 30,
	in_gun = 30,
	bullets = 30,
	reload_time = 5, 
	damage = 5,
	time_to_shoot = 0.10,
	region = Rect2(768, 1500, 256, 250),
	ability = null
}

var rifle = {
	magazine = 15,
	in_gun = 15,
	bullets = 15,
	reload_time = 4,
	damage = 15,
	time_to_shoot = 0.50,
	region = Rect2(1280, 1500, 256, 250),
	ability = null
}

var sniper = {
	magazine = 1,
	in_gun = 1,
	bullets = 5,
	reload_time = 5,
	damage = 50,
	time_to_shoot = 1.5,
	region = Rect2(768, 2247, 256, 250),
	ability = "zoom",
	zoom_vector = Vector2(1.5, 1.5)
}

var guns: Array = [handgun, uzi, rifle, revolver, sniper]
var current_gun: int = 0
var total_guns: int = 4
var equiped_gun

onready var tween: Tween = $Tween
onready var sprite: Sprite = $Sprite
onready var bullet_label: Label = $CanvasLayer/Bullets/Label
onready var reload_timer: Timer = $Reload_timer
onready var shoot_point: Position2D = $Shoot_point
onready var hit_timer: Timer = $Hit_timer
onready var reloading: Timer = $Reloading
onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var camera: Camera2D = $Camera2D

func _ready() -> void:

# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")

	username_text_instance = Global.instance_node_at_location(username_text, Persistent_nodes, global_position)
	username_text_instance.player_following = self

	equiped_gun = guns[current_gun]
	update_shoot_mode(false)
	Global.alive_players.append(self)
	joystick_one = get_node(joystick_one_path);
	joystick_two = get_node(joystick_two_path);
	
	# Use the updated signal to update the rotation when the joystick changes
	joystick_two.connect("Joystick_Updated", self, "rotation_updated");

	yield(get_tree(), "idle_frame")
	if get_tree().has_network_peer():
		if is_network_master():
			camera.make_current()

func _process(delta: float) -> void:

	if username_text_instance != null:
		username_text_instance.name = "username" + name

	if get_tree().has_network_peer():
		if is_network_master():

			if Global.Os == "Android":
				# Move based on the joystick, only if the joystick is farther than the dead zone.
				if (joystick_one.joystick_vector.length() > JOYSTICK_DEADZONE/2):
	# warning-ignore:return_value_discarded
					move_and_collide(-joystick_one.joystick_vector * MOVE_SPEED * delta);

			elif Global.Os == "OSX":
				var x_input: int = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
				var y_input: int = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
				velocity = Vector2(x_input, y_input).normalized()

	# warning-ignore:return_value_discarded
				move_and_slide(velocity * speed)

				look_at(get_global_mouse_position())

			bullet_label.text = "Bullets: " + str(equiped_gun.bullets)

			if Input.is_action_pressed("click") and can_shoot and not is_reloading and equiped_gun.in_gun > 0:
				rpc("instance_bullet", get_tree().get_network_unique_id())
				equiped_gun.in_gun -= 1
				is_reloading = true
				reload_timer.start(equiped_gun.time_to_shoot)

			if Input.is_action_just_pressed("change_guns") and can_shoot and not is_reloading:
				if current_gun >= total_guns:
					current_gun = -1

				current_gun += 1
				equiped_gun = guns[current_gun]
				rpc("change_guns", equiped_gun.region)

				if equiped_gun.ability == "zoom":
					zoom(equiped_gun.zoom_vector)
				else:
					zoom(Vector2(1, 1))

				print(str(equiped_gun))

			if Input.is_action_just_pressed("reload"):
				if equiped_gun.in_gun < equiped_gun.magazine:
					if equiped_gun.bullets >= equiped_gun.magazine:
						var bullets_needed: int = equiped_gun.magazine - equiped_gun.in_gun
						equiped_gun.in_gun += bullets_needed
						equiped_gun.bullets -= bullets_needed
						can_shoot = false
						reloading.start(equiped_gun.reload_time)
						anim_player.play("Reloading")
					elif equiped_gun.bullets != 0:
						equiped_gun.in_gun += equiped_gun.bullets
						equiped_gun.bullets = 0
						can_shoot = false
						reloading.start(equiped_gun.reload_time)
						anim_player.play("Reloading")

		else:
			rotation = lerp_angle(rotation, puppet_rotation, delta * 8)

			if not tween.is_active():
	# warning-ignore:return_value_discarded
				move_and_slide(puppet_velocity * speed)

	if hp <= 0:
		if username_text_instance != null:
			username_text_instance.visible = false

		if get_tree().has_network_peer():
			if get_tree().is_network_server():
				rpc("destroy")

func lerp_angle(from, to, weight):
	return from + short_angle_dist(from, to) * weight

func short_angle_dist(from, to):
	var max_angle = PI * 2
	var difference = fmod(to - from, max_angle)
	return fmod(2 * difference, max_angle) - difference

func puppet_position_set(new_value) -> void:
	puppet_position = new_value

# warning-ignore:return_value_discarded
	tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
# warning-ignore:return_value_discarded
	tween.start()

func set_hp(new_value) -> void:
	hp = new_value

	if get_tree().has_network_peer():
		if is_network_master():
			rset("puppet_hp", hp)

func puppet_hp_set(new_value) -> void:
	puppet_hp = new_value

	if get_tree().has_network_peer():
		if not is_network_master():
			hp = puppet_hp

func username_set(new_value) -> void:
	username = new_value

	if get_tree().has_network_peer():
		if is_network_master() and username_text_instance != null:
			username_text_instance.text = username
			rset("puppet_username", username)

func puppet_username_set(new_value) -> void:
	puppet_username = new_value

	if get_tree().has_network_peer():
		if not is_network_master() and username_text_instance != null:
			username_text_instance.text = puppet_username

func _network_peer_connected(id) -> void:
	rset_id(id, "puppet_username", username)

func _on_Network_tick_rate_timeout() -> void:
	if get_tree().has_network_peer():
		if is_network_master():
			rset_unreliable("puppet_position", global_position)
			rset_unreliable("puppet_velocity", velocity)
			rset_unreliable("puppet_rotation", rotation)

sync func instance_bullet(id) -> void:
	var player_bullet_instance = Global.instance_node_at_location(player_bullet, Persistent_nodes, shoot_point.global_position)
	player_bullet_instance.name = "Bullet" + name + str(Network.networked_object_name_index)
	player_bullet_instance.damage = equiped_gun.damage
	player_bullet_instance.set_network_master(id)
	player_bullet_instance.player_rotation = rotation
	player_bullet_instance.player_owner = id
	Network.networked_object_name_index += 1

sync func update_position(pos) -> void:
	global_position = pos
	puppet_position = pos

func update_shoot_mode(shoot_mode: bool) -> void:
	if not shoot_mode:
		sprite.set_region_rect(Rect2(0, 1500, 256, 250))
	else:
		sprite.set_region_rect(Rect2(512, 1500, 256, 250))

	can_shoot = shoot_mode

func _on_Reload_timer_timeout() -> void:
	is_reloading = false

func _on_Hit_timer_timeout() -> void:
	modulate = Color(1, 1, 1, 1)

func _on_Hitbox_area_entered(area) -> void:
	if get_tree().has_network_peer():
		if get_tree().is_network_server():
			if area.is_in_group("Player_damager") and area.get_parent().player_owner != int(name):
				rpc("hit_by_damager", area.get_parent().damage)

			area.get_parent().rpc("destroy")

sync func hit_by_damager(damage) -> void:
	hp -= damage
	modulate = Color(5, 5, 5, 1)
	hit_timer.start()

sync func enable() -> void:
	hp = 100
	can_shoot = false
	update_shoot_mode(false)
	username_text_instance.visible = true
	visible = true
	restore_guns()
	$CollisionShape2D.disabled = false
	$Hitbox/CollisionShape2D.disabled = false
	
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = self
	
	if not Global.alive_players.has(self):
		Global.alive_players.append(self)

sync func destroy() -> void:

	username_text_instance.visible = false
	visible = false
	can_shoot = false
	$CollisionShape2D.disabled = true
	$Hitbox/CollisionShape2D.disabled = true
	Global.alive_players.erase(self)

	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = null

func _exit_tree() -> void:
	Global.alive_players.erase(self)
	if get_tree().has_network_peer():
		if is_network_master():
			Global.player_master = null

func rotation_updated():
	# Convert the joystick vector to rotation using angle_to_point, only if the joystick is farther
	# than the dead zone.
	if get_tree().has_network_peer():
		if is_network_master():
			if (joystick_two.joystick_vector.length() > JOYSTICK_DEADZONE):
				global_rotation = global_position.angle_to_point(global_position + joystick_two.joystick_vector);

func _on_Reloading_timeout():
	anim_player.play("Stop_reload")
	print(str(equiped_gun.bullets))
	can_shoot = true

func zoom(zoom: Vector2):
	if get_tree().has_network_peer():
		if is_network_master():
			camera.zoom = zoom

sync func change_guns(rect):
	sprite.set_region_rect(rect)

func restore_guns():
	handgun = {
		magazine = 6,
		in_gun = 6,
		bullets = 6,
		reload_time = 3.5,
		damage = 10,
		time_to_shoot = 0.50,
		region = Rect2(512, 1500, 256, 250),
		ability = null
	}

	revolver = {
		magazine = 6,
		in_gun = 6,
		bullets = 6,
		reload_time = 4.5,
		damage = 20,
		time_to_shoot = 1,
		region = Rect2(512, 2247, 256, 250),
		ability = null
	}

	uzi = {
		magazine = 30,
		in_gun = 30,
		bullets = 30,
		reload_time = 5, 
		damage = 5,
		time_to_shoot = 0.10,
		region = Rect2(768, 1500, 256, 250),
		ability = null
	}

	rifle = {
		magazine = 15,
		in_gun = 15,
		bullets = 15,
		reload_time = 4,
		damage = 15,
		time_to_shoot = 0.50,
		region = Rect2(1280, 1500, 256, 250),
		ability = null
	}

	sniper = {
		magazine = 1,
		in_gun = 1,
		bullets = 5,
		reload_time = 5,
		damage = 50,
		time_to_shoot = 1.5,
		region = Rect2(768, 2247, 256, 250),
		ability = "zoom",
		zoom_vector = Vector2(1.5, 1.5)
	}

	equiped_gun = handgun
	guns = [handgun]
	current_gun = 0
	total_guns = 0
