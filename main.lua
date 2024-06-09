local love = love
local graphics = love.graphics
local quad = graphics.newQuad

graphics.setDefaultFilter("nearest", "nearest")

local batches = {}
local assets = {}
for _, i in ipairs(love.filesystem.getDirectoryItems("assets")) do
	local name = i:sub(1, -5)
	assets[name] = graphics.newImage("assets/" .. i)
	batches[name] = graphics.newSpriteBatch(assets[name])
	print(name)
end

local CROP_COUNT = 1
local MAX_GROWTH = 8
local cropIDs = {
	corn = 0,
	wheat = 1,
}

local crops = {
	["2,1"] = {
		growth = 7,
		id = 0
	},
	["3,1"] = {
		growth = 7,
		id = 0
	},
	["2,2"] = {
		growth = 7,
		id = 0
	},
	["3,2"] = {
		growth = 7,
		id = 0
	}
}

local player = {
	x = 0,
	y = 0,
	inventory = {},
	dir = 0,
	frame = 0,
	frametimer = 0
}


function love.draw()
	local w, h = graphics.getDimensions()
	graphics.scale(4)
	graphics.translate(-player.x + w / 8, -player.y + h / 8)

	batches.ground:clear()
	for i = math.floor((player.x - w / 8) / 16), math.floor((player.x + w / 8) / 16) do
		for j = math.floor((player.y - h / 8) / 16), math.floor((player.y + h / 8) / 16) do
			batches.ground:add(i * 16, j * 16)
		end
	end

	graphics.draw(batches.ground, 0, 0)

	batches.crops:clear()
	for posStr, crop in pairs(crops) do
		local x = tonumber(posStr:match("[^,]+"))
		local y = tonumber(posStr:sub(posStr:find(",") + 1))
		local px = x * 16
		local py = y * 16
		batches.soil:add(px - 4, py - 4)
		if py + 4 <= player.y then
			batches.crops:add(quad(crop.growth * 16, crop.id * 32, 16, 32, 16 * MAX_GROWTH, 32 * CROP_COUNT), px, py - 16)
		end
	end
	graphics.draw(batches.soil)

	graphics.draw(batches.crops)

	batches.player:clear()
	batches.player:add(quad(player.dir * 16, player.frame * 24, 16, 24, 16 * 4, 24 * 4))
	graphics.draw(batches.player, player.x - 8, player.y - 16)

	batches.crops:clear()
	for posStr, crop in pairs(crops) do
		local x = tonumber(posStr:match("[^,]+"))
		local y = tonumber(posStr:sub(posStr:find(",") + 1))
		local px = x * 16
		local py = y * 16
		print(py, player.y)
		if py + 4 > player.y then
			batches.crops:add(quad(crop.growth * 16, crop.id * 32, 16, 32, 16 * MAX_GROWTH, 32 * CROP_COUNT), px, py - 16)
		end
	end

	graphics.draw(batches.crops)
end

function love.update(dt)
	if player.frametimer <= 0 then
		player.frametimer = 0.2
		player.frame = (player.frame + 1) % 4
	end
	player.frametimer = player.frametimer - dt
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
	else
		player.frame = 0
		player.frametimer = 0
	end
	player.x = player.x + x * 50 * dt
	player.y = player.y + y * 50 * dt
end
