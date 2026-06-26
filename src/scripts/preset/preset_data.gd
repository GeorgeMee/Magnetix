class_name PresetData
extends Resource

@export var preset_name : String = ""
@export var width : float = 640.0
@export var trajectory : Array[TrajectoryPoint] = []
@export var magnet_blocks : Array[MagnetBlock] = []
@export var walls : Array[ObstacleBlock] = []
@export var hazards : Array[ObstacleBlock] = []
@export var coins : Array[CoinBlock] = []
