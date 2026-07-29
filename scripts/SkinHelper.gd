class_name SkinHelper
extends RefCounted

## Decodes a "data:image/jpeg;base64,...." string (as produced by the
## landing page's canvas.toDataURL) into a usable texture.
static func decode_skin_texture(data_url: String) -> ImageTexture:
	if not data_url.begins_with("data:image"):
		return null
	var comma_idx := data_url.find(",")
	if comma_idx == -1:
		return null
	var base64_part := data_url.substr(comma_idx + 1)
	var bytes := Marshalls.base64_to_raw(base64_part)
	if bytes.is_empty():
		return null
	var img := Image.new()
	var err := img.load_jpg_from_buffer(bytes)
	if err != OK:
		err = img.load_png_from_buffer(bytes)
	if err != OK:
		return null
	return ImageTexture.create_from_image(img)
