extends Node

func load_image_from_buffer(buffer: PackedByteArray):
	var image = Image.new()
	var error = image.load_png_from_buffer(buffer)
	if error != OK:
		print(str("Could not load image with error: ",error))
		return
	var texture = ImageTexture.new()
	texture.set_image(image)
	texture.set_size_override(Vector2(1100, 580))
	return texture
