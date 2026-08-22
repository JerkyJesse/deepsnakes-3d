extends Node3D

@export var biome_id: String = "forest"

func _ready() -> void:
	BiomeBuilder.build(self, BiomeCatalog.get_biome(biome_id))
