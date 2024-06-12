local love = love
local graphics = love.graphics
local quad = graphics.newQuad

graphics.setDefaultFilter("linear", "nearest")

local batches = {}
local assets = {}
for _, i in ipairs(love.filesystem.getDirectoryItems("assets")) do
	local name = i:sub(1, -5)
	assets[name] = graphics.newImage("assets/" .. i)
	batches[name] = graphics.newSpriteBatch(assets[name])
end

local CROP_COUNT = 1
local MAX_GROWTH = 8
cropIDs = {
	corn = 0,
	wheat = 1,
}
cropNames = {}
for name, id in pairs(cropIDs) do
	cropNames[id] = name
end

crops = {}
farmLands = {}

graphics.setFont (graphics.newFont (50))
local font = love.graphics.getFont ()



player = {
	x = 0,
	y = 0,
	inventory = {
		{name = "gloves", count = nil, text = graphics.newText(font)},
		{name = "hoe", count = nil, text = graphics.newText(font)},
		{name = "watering_can", count = 100, text = graphics.newText(font)},

		{name = "corn_seeds", count = 12, text = graphics.newText(font)},
		{name = "harvested_corn", count = 10, text = graphics.newText(font)},

		{name = "wheat_seeds", count = 7, text = graphics.newText(font)},
		{name = "harvested_wheat", count = 15, text = graphics.newText(font)},

		{name = "whistle", count = 100, text = graphics.newText(font)},
	},
	currentItem = 1,
	dir = 0,
	frame = 0,
	frametimer = 0,
	health = 100
}
itemIds = {}
for i, itemInfo in ipairs(player.inventory) do
	itemIds[itemInfo.name] = i
	itemInfo.use = select(2, xpcall(require, function ()
		return {use = function () end}
	end, "items."..itemInfo.name)).use
end

local dustStormTimer = 10;

function love.draw()
	graphics.setColor(1 * (player.health / 100), 0.95 * (player.health / 100) ^ 2, 0.87  * (player.health / 100) ^ 2) -- cowboy color
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
	batches.soil:clear()
	for posStr, crop in pairs(crops) do
		local x = tonumber(posStr:match("[^,]+"))
		local y = tonumber(posStr:sub(posStr:find(",") + 1))
		local px = x * 16
		local py = y * 16
		if py + 4 <= player.y then
			batches.crops:add(quad(crop.growth * 16, crop.id * 32, 16, 32, 16 * MAX_GROWTH, 32 * CROP_COUNT), px, py - 16)
		end
	end
	for posStr, soil in pairs(farmLands) do
		local x = tonumber(posStr:match("[^,]+"))
		local y = tonumber(posStr:sub(posStr:find(",") + 1))
		local px = x * 16
		local py = y * 16
		batches.soil:add(quad(soil.hydration * 24, 0, 24, 24, 24 * 5, 24), px - 4, py - 4)
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
		if py + 4 > player.y then
			batches.crops:add(quad(crop.growth * 16, crop.id * 32, 16, 32, 16 * MAX_GROWTH, 32 * CROP_COUNT), px, py - 16)
		end
	end

	graphics.draw(batches.crops)

	graphics.origin()
	local boxSize = 50
	local baseOffset = 10
	local offset = baseOffset
	for i, itemInfo in ipairs(player.inventory) do
		local backColor
		local borderColor
		if i == player.currentItem then
			backColor = {r = 1, g = 1, b = 1}
			borderColor = {r = 0.4, g = 0.4, b = 0.4}
		else
			backColor = {r = 0.8, g = 0.7, b = 0.5}
			borderColor = {r = 0.3, g = 0.2, b = 0}
		end
		-- backing
		graphics.setColor(backColor.r, backColor.g, backColor.b)
		graphics.rectangle("fill", offset, baseOffset, boxSize, boxSize)

		graphics.draw(assets[itemInfo.name], offset, baseOffset, 0, 2.5, 2.5)

		-- border
		graphics.setColor(borderColor.r, borderColor.g, borderColor.b)
		graphics.setLineWidth(4)
		graphics.rectangle("line", offset, baseOffset, boxSize, boxSize)
		graphics.setLineWidth(1)

		graphics.setColor(0, 0, 0)
		local itemCountText
		if itemInfo.count then
			itemCountText = tostring(itemInfo.count)
		else
			itemCountText = ""
		end
		local fontHeight = font:getHeight() * 0.4
		local fontWidth = font:getWidth(itemCountText) * 0.4
		itemInfo.text:clear()
		itemInfo.text:add(itemCountText, 0, 0, 0, 0.4, 0.4, 0, 0, 0, 0)
		graphics.draw(itemInfo.text, offset + boxSize - fontWidth - 2, baseOffset + fontHeight + 5)

		offset = offset + boxSize
	end
end

function love.update(dt)
	for _, crop in pairs(crops) do
		if math.random() / dt < 0.05 then
			crop.growth = math.min(crop.growth + 1, MAX_GROWTH - 1)
		end
	end
	local isDown = love.keyboard.isDown
	if player.frametimer <= 0 then
		player.frametimer = 0.2
		player.frame = (player.frame + 1) % 4
	end
	player.frametimer = player.frametimer - dt * (player.health / 100) ^ 2
	local x, y = 0, 0
	if isDown("d") or isDown("right") then x = 1 end
	if isDown("a") or isDown("left") then x = x - 1 end
	if isDown("s") or isDown("down") then y = 1 end
	if isDown("w") or isDown("up") then y = y - 1 end
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
	player.x = player.x + x * 50 * dt * (player.health / 100) ^ 2
	player.y = player.y + y * 50 * dt * (player.health / 100) ^ 2

	-- select item
	for i = 1, #player.inventory do
		if isDown(tostring(i)) then
			player.currentItem = i
		end
	end

	-- use item
	if isDown("space") then
		local currentItem = player.inventory[player.currentItem]
		local pos = math.floor(player.x/16) .. "," ..math.floor(player.y/16)
		print(pos)

		currentItem:use(pos)
	end

	dustStormTimer = dustStormTimer - dt
	if dustStormTimer < 0 then
		dustStormTimer = 0
		player.health = player.health - 5 * dt
		if player.health <= 0 then
			error("you died lol")
		end
		for pos, farmland in pairs(farmLands) do
			if math.random() / dt < 0.3 then
				if farmland.hydration <= 0 then
					farmLands[pos] = nil
				else
					farmland.hydration = farmland.hydration - 1
				end
			end
		end
		for pos, crop in pairs(crops) do
			if math.random() / dt < 0.1 then
				crop.growth = 7
			end
		end
	end
end
