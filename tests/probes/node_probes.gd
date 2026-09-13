extends RefCounted


static func child(root: Node, node_name: String, node_type: String = "") -> Node:
	if root == null:
		return null
	if node_type.is_empty():
		return root.find_child(node_name, true, false)
	var matches := root.find_children(node_name, node_type, true, false)
	return null if matches.is_empty() else matches[0]


static func playing_clip(root: Node) -> String:
	var clips := playing_clips(root)
	return clips[0] if clips.size() == 1 else ""


static func playing_clips(root: Node) -> Array[String]:
	var clips: Array[String] = []
	if root == null:
		return clips
	for player in root.find_children("*", "AnimationPlayer", true, false):
		if (player as AnimationPlayer).is_playing():
			clips.append(String((player as AnimationPlayer).current_animation).to_lower())
	return clips


static func model_has_playing_animation(root: Node) -> bool:
	return not playing_clip(root).is_empty()


static func first_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	return root.find_child("AnimationPlayer", true, false) as AnimationPlayer


static func first_skeleton(root: Node) -> Skeleton3D:
	if root == null:
		return null
	var skeletons := root.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return null
	return skeletons[0] as Skeleton3D


static func attachment(root: Node, attachment_name: String) -> BoneAttachment3D:
	if root == null:
		return null
	var attachments := root.find_children(attachment_name, "BoneAttachment3D", true, false)
	if attachments.size() != 1:
		return null
	return attachments[0] as BoneAttachment3D


static func attachment_report(root: Node, attachment_name: String, payload_name: String) -> Dictionary:
	var attachment_node := attachment(root, attachment_name)
	return {
		"count": 0 if root == null else root.find_children(attachment_name, "BoneAttachment3D", true, false).size(),
		"attachment": attachment_node,
		"bone": &"" if attachment_node == null else attachment_node.bone_name,
		"parent_is_skeleton": attachment_node != null and attachment_node.get_parent() is Skeleton3D,
		"payload": null if attachment_node == null else attachment_node.find_child(payload_name, true, false),
	}


static func recursive_aabb(root: Node, parent_transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	if root == null:
		return AABB()
	var result := AABB()
	var found := false
	var transform := parent_transform
	if root is Node3D:
		transform = parent_transform * (root as Node3D).transform
	if root is MeshInstance3D and (root as MeshInstance3D).mesh != null:
		result = transform * (root as MeshInstance3D).get_aabb()
		found = true
	for child in root.get_children():
		var child_bounds := recursive_aabb(child, transform)
		if child_bounds.size != Vector3.ZERO:
			result = result.merge(child_bounds) if found else child_bounds
			found = true
	return result
