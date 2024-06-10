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

graphics.setFont (graphics.newFont (50))
local font = love.graphics.getFont ()

local player = {
	x = 0,
	y = 0,
	inventory = {
		["gloves"] = {count = 1, text = graphics.newText(font)},
		["corn_seeds"] = {count = 99, text = graphics.newText(font)},
		["wheat_seeds"] = {count = 0, text = graphics.newText(font)},
		["watering_can"] = {count = 1, text = graphics.newText(font)}, -- 0..=1
		["whistle"] = {count = 1, text = graphics.newText(font)},
	},
	dir = 0,
	frame = 0,
	frametimer = 0
}


function love.draw()
	graphics.setColor(1, 0.95, 0.87)
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

	graphics.origin()
	local boxSize = 50
	local baseOffset = 10
	local offset = baseOffset
	for item, itemInfo in pairs(player.inventory) do
		-- backing
		graphics.setColor(0.8, 0.7, 0.5)
		graphics.rectangle("fill", offset, baseOffset, boxSize, boxSize)

		graphics.draw(assets[item], offset, baseOffset, 0, 2.5, 2.5)


		-- border
		graphics.setColor(0.3, 0.2, 0.0)
		graphics.rectangle("line", offset, baseOffset, boxSize, boxSize)

		graphics.setColor(0, 0, 0)
		local itemCountText = tostring(itemInfo.count)
		local fontHeight = font:getHeight() * 0.4
		local fontWidth = font:getWidth(itemCountText) * 0.4
		itemInfo.text:clear()
		itemInfo.text:add(itemCountText, 0, 0, 0, 0.4, 0.4, 0, 0, 0, 0)
		graphics.draw(itemInfo.text, offset + boxSize - fontWidth - 2, baseOffset + fontHeight + 5)

		offset = offset + boxSize
	end
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
