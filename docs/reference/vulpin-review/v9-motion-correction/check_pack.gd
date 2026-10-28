extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args()
	assert(args.size()==1)
	var file: String=args[0]
	assert(ProjectSettings.load_resource_pack(file))
	var frames: SpriteFrames=load("res://vulpin.res")
	if frames==null or frames.get_animation_names().size()!=36:
		push_error("Pack lacks complete animation resources");quit(1);return
	var pages: Dictionary={};var slots:=0;var rgba:=0
	for name in frames.get_animation_names():
		for i in frames.get_frame_count(name):
			var tex: AtlasTexture=frames.get_frame_texture(name,i)
			assert(tex!=null and tex.atlas!=null)
			var atlas: Texture2D=tex.atlas
			if not pages.has(atlas.resource_path):
				var img:=atlas.get_image();assert(img!=null and not img.is_empty())
				pages[atlas.resource_path]=[img.get_width(),img.get_height()];rgba+=img.get_data_size()
			slots+=1
	var result: Dictionary={"pack":file.get_file(),"clips":36,"frameSlots":slots,"pages":pages.size(),"decodedBytes":rgba,"loadedFromPackOnly":true}
	FileAccess.open(file.get_basename()+"-loaded.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print(JSON.stringify(result));quit(0)
