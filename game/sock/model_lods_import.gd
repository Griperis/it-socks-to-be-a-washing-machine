## The import script of the Sock models (assets/sock/*.glb, their .import `import_script/path`):
## folds each model's hand-made LODs into its close-up's mesh (ModelLods), so the imported scene
## carries one mesh with its levels and no LOD nodes.
@tool
extends EditorScenePostImport


func _post_import(scene: Node) -> Object:
	ModelLods.fold(scene)
	return scene
