local love = love
local graphics = love.graphics

graphics.setDefaultFilter("nearest", "nearest")

local assets = {}
for _, i in ipairs(love.filesystem.getDirectoryItems("assets")) do
	assets[i:sub(1, -5)] = graphics.newSpriteBatch(graphics.newImage("assets/" .. i))
	print(i:sub(1, -5))
end

local tiles = {}

local player = {
	x = 0,
	y = 0,
	inventory = {},
	dir = 0,
	frame = 0,
}


function love.draw()
	local w, h = graphics.getDimensions()
	graphics.scale(4)
	graphics.translate(-player.x + w / 8, -player.y + h / 8)

	assets.ground:clear()
	for i = math.floor((player.x - w / 8) / 16), math.floor((player.x + w / 8) / 16) do
		for j = math.floor((player.y - h / 8) / 16), math.floor((player.y + h / 8) / 16) do
			assets.ground:add(i * 16, j * 16)
		end
	end
	graphics.draw(assets.ground, 0, 0)

	assets.player:clear()
	assets.player:add(graphics.newQuad(player.dir * 8, player.frame * 16, 8, 16, 8 * 4, 16 * 4))
	graphics.draw(assets.player, player.x - 4, player.y - 12)
end

function love.update()
	local x, y = 0, 0
	if love.keyboard.isDown("d") then x = 1 end
	if love.keyboard.isDown("a") then x = x - 1 end
	if love.keyboard.isDown("s") then y = 1 end
	if love.keyboard.isDown("w") then y = y - 1 end
	if y == 1 then
		player.dir = 0
	elseif y == -1 then
		player.dir = 2
	elseif x == 1 then
		player.dir = 1
	elseif x == -1 then
		player.dir = 3
	end
	player.x = player.x + x
	player.y = player.y + y
end
