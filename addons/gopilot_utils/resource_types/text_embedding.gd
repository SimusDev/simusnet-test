extends Resource
class_name TextEmbedding

## Content of the embedded text
@export var text:String = ""
## Embedding data of the embedded text[br]
## Used for retrieving similar text segments
@export var data:PackedFloat32Array = []

## Temporal variable used for comparing distances between embeddings[br]
## Do not access this, unless you are writing your own embedding-comparison
var distance:float = -100.0
