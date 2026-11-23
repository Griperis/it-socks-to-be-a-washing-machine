## The save files as files in a folder (`user://` in the game; a test's own folder): Steam Auto-Cloud
## syncs the ones matching its pattern, with no code (Q2564). A write never truncates a file in
## place (Godot's FileAccess writes in place in an exported game): the text goes to `<name>.tmp`,
## stored, flushed and checked; the old file becomes `<name>.bak` when asked (else it is removed); the
## temp file then takes its place. A rename over a file is two steps on Windows, so a crash between
## any two steps leaves the backup or the temp file, and the read falls back to the backup.
class_name LocalFileStore
extends SaveStore

## The folder the names are relative to.
var root := "user://"


func _init(folder := "user://") -> void:
	root = folder


func read(name: String) -> Dictionary:
	return _read_file(_path(name), name)


func read_backup(name: String) -> Dictionary:
	return _read_file(_path(name) + BACKUP, name + BACKUP)


func write(name: String, text: String, keep_old: bool) -> Dictionary:
	if not valid(name):
		return _no("'%s' is not a save file name" % name)
	var path := _abs(name)
	var err := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if err != OK:
		return _no("cannot make the folder of %s (%s)" % [name, error_string(err)])
	var tmp := path + TEMP
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return _no("cannot write %s (%s)" % [name + TEMP, error_string(FileAccess.get_open_error())])
	var stored := f.store_string(text)
	f.flush()
	var write_err := f.get_error()
	f.close()
	if not stored or write_err != OK:
		DirAccess.remove_absolute(tmp)
		return _no("cannot write %s (%s)" % [name + TEMP, error_string(write_err if write_err != OK else ERR_FILE_CANT_WRITE)])
	var moved_old := false
	if FileAccess.file_exists(path):
		if keep_old:
			err = DirAccess.rename_absolute(path, path + BACKUP)
			moved_old = err == OK
		else:
			err = DirAccess.remove_absolute(path)
		if err != OK:
			DirAccess.remove_absolute(tmp)
			return _no("cannot move %s aside (%s)" % [name, error_string(err)])
	err = DirAccess.rename_absolute(tmp, path)
	if err != OK:
		if moved_old:
			DirAccess.copy_absolute(path + BACKUP, path)  # the old file back where it was
		return _no("cannot put %s in place (%s)" % [name, error_string(err)])
	return {"ok": true, "reason": ""}


func has(name: String) -> bool:
	return valid(name) and (FileAccess.file_exists(_path(name)) or FileAccess.file_exists(_path(name) + BACKUP))


func list(folder: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := _abs(folder.trim_suffix("/"))
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for f in DirAccess.get_files_at(dir):
		var name := folder.trim_suffix("/").path_join(f)
		if valid(name):
			out.append(name)
	out.sort()
	return out


func delete(name: String) -> void:
	if not valid(name):
		return
	for suffix: String in ["", BACKUP, TEMP]:
		if FileAccess.file_exists(_path(name) + suffix):
			DirAccess.remove_absolute(_abs(name) + suffix)


func keep_damaged(name: String) -> void:
	if valid(name) and FileAccess.file_exists(_path(name)):
		DirAccess.rename_absolute(_abs(name), _abs(name) + DAMAGED)


func all_names() -> PackedStringArray:
	var out := PackedStringArray()
	_walk(_abs(""), "", out)
	out.sort()
	return out


func _walk(dir: String, rel: String, out: PackedStringArray) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		out.append(rel.path_join(f) if rel != "" else f)
	for d in DirAccess.get_directories_at(dir):
		_walk(dir.path_join(d), rel.path_join(d) if rel != "" else d, out)


func _read_file(path: String, shown: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _no("no file %s" % shown)
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return _no("cannot read %s (%s)" % [shown, error_string(FileAccess.get_open_error())])
	var text := f.get_as_text()
	f.close()
	return {"ok": true, "text": text, "reason": ""}


func _path(name: String) -> String:
	return root.path_join(name)


func _abs(name: String) -> String:
	return ProjectSettings.globalize_path(_path(name)) if name != "" else ProjectSettings.globalize_path(root)
