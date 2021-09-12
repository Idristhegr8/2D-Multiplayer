extends TileMap

export var width: int = 39
export var height: int = 31

var openSimplexNoise: OpenSimplexNoise = OpenSimplexNoise.new()

func _ready() -> void:
	randomize()
	openSimplexNoise.octaves = 5
	openSimplexNoise.seed = randi()
	generate_map()

func generate_map() -> void:
	for x in width:
		for y in height:
			var rand = openSimplexNoise.get_noise_2d(x,y)
			set_cell(x, y, rand)
