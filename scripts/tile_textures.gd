extends Node

# 像素地表纹理生成器
# 生成16x16像素风格的地表贴图

const TILE_SIZE := 16

static func create_grass_tile() -> ImageTexture:
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0x4a, 0x7d, 0x3a, 1.0))
	
	# 添加草纹理细节
	var grass_darks = [
		Vector2i(2, 3), Vector2i(5, 1), Vector2i(9, 4), Vector2i(12, 2), Vector2i(14, 6),
		Vector2i(1, 8), Vector2i(7, 7), Vector2i(11, 9), Vector2i(4, 12), Vector2i(13, 11),
		Vector2i(3, 14), Vector2i(8, 13), Vector2i(10, 1), Vector2i(6, 5)
	]
	for pos in grass_darks:
		img.set_pixel(pos.x, pos.y, Color(0x3d, 0x6b, 0x2e, 1.0))
	
	# 亮色草叶
	var grass_lights = [
		Vector2i(3, 2), Vector2i(8, 3), Vector2i(13, 5), Vector2i(2, 7),
		Vector2i(9, 8), Vector2i(5, 11), Vector2i(12, 12), Vector2i(7, 14)
	]
	for pos in grass_lights:
		img.set_pixel(pos.x, pos.y, Color(0x5f, 0x9a, 0x47, 1.0))
	
	return ImageTexture.create_from_image(img)


static func create_dirt_tile() -> ImageTexture:
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0x8b, 0x6d, 0x4a, 1.0))
	
	# 添加泥土纹理
	var dirt_darks = [
		Vector2i(1, 2), Vector2i(4, 1), Vector2i(8, 3), Vector2i(12, 1), Vector2i(14, 4),
		Vector2i(2, 6), Vector2i(6, 5), Vector2i(10, 7), Vector2i(3, 9), Vector2i(9, 8),
		Vector2i(13, 10), Vector2i(5, 12), Vector2i(11, 11), Vector2i(7, 14)
	]
	for pos in dirt_darks:
		img.set_pixel(pos.x, pos.y, Color(0x6b, 0x4f, 0x32, 1.0))
	
	# 亮色斑点
	var dirt_lights = [
		Vector2i(2, 4), Vector2i(7, 2), Vector2i(11, 5), Vector2i(4, 8),
		Vector2i(8, 10), Vector2i(13, 13), Vector2i(1, 12)
	]
	for pos in dirt_lights:
		img.set_pixel(pos.x, pos.y, Color(0xa6, 0x85, 0x5c, 1.0))
	
	return ImageTexture.create_from_image(img)


static func create_stone_tile() -> ImageTexture:
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0x6b, 0x6b, 0x6b, 1.0))
	
	# 石砖缝隙
	for x in range(0, TILE_SIZE, 8):
		for y in range(0, TILE_SIZE):
			img.set_pixel(x, y, Color(0x4a, 0x4a, 0x4a, 1.0))
	for y in range(0, TILE_SIZE, 8):
		for x in range(0, TILE_SIZE):
			img.set_pixel(x, y, Color(0x4a, 0x4a, 0x4a, 1.0))
	
	# 亮色石面
	var stone_lights = [
		Vector2i(1, 1), Vector2i(5, 2), Vector2i(9, 1), Vector2i(13, 2),
		Vector2i(2, 5), Vector2i(10, 6), Vector2i(6, 9), Vector2i(14, 10),
		Vector2i(1, 13), Vector2i(7, 14)
	]
	for pos in stone_lights:
		img.set_pixel(pos.x, pos.y, Color(0x8a, 0x8a, 0x8a, 1.0))
	
	return ImageTexture.create_from_image(img)


static func create_water_tile() -> ImageTexture:
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0x3a, 0x6d, 0x9a, 1.0))
	
	# 水波纹
	var water_lights = [
		Vector2i(2, 2), Vector2i(6, 1), Vector2i(10, 3), Vector2i(14, 2),
		Vector2i(1, 6), Vector2i(5, 7), Vector2i(9, 6), Vector2i(13, 7),
		Vector2i(3, 10), Vector2i(7, 11), Vector2i(11, 10), Vector2i(14, 12),
		Vector2i(2, 14), Vector2i(8, 14), Vector2i(12, 13)
	]
	for pos in water_lights:
		img.set_pixel(pos.x, pos.y, Color(0x5a, 0x9d, 0xba, 1.0))
	
	return ImageTexture.create_from_image(img)


static func create_wood_tile() -> ImageTexture:
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0x8b, 0x6d, 0x4a, 1.0))
	
	# 木纹
	for y in range(TILE_SIZE):
		img.set_pixel(3, y, Color(0x7a, 0x5c, 0x3a, 1.0))
		img.set_pixel(8, y, Color(0x7a, 0x5c, 0x3a, 1.0))
		img.set_pixel(12, y, Color(0x7a, 0x5c, 0x3a, 1.0))
	
	# 钉子
	var nails = [Vector2i(3, 2), Vector2i(8, 7), Vector2i(12, 12)]
	for pos in nails:
		img.set_pixel(pos.x, pos.y, Color(0x5a, 0x5a, 0x5a, 1.0))
	
	return ImageTexture.create_from_image(img)


# 预缓存所有纹理
var grass_tex: ImageTexture
var dirt_tex: ImageTexture
var stone_tex: ImageTexture
var water_tex: ImageTexture
var wood_tex: ImageTexture

func _ready():
	grass_tex = create_grass_tile()
	dirt_tex = create_dirt_tile()
	stone_tex = create_stone_tile()
	water_tex = create_water_tile()
	wood_tex = create_wood_tile()
