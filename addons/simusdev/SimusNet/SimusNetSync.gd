extends Resource
class_name SimusNetSync

@export var node: NodePath
@export var properties: Array[String] = []
@export var mode: SimusNetVarConfig.MODE = SimusNetVarConfig.MODE.AUTHORITY
@export var channel: String = SimusNetChannels.DEFAULT
@export var tickrate: float = 0.0
@export var reliable: bool = true
@export var serialization: bool = true
