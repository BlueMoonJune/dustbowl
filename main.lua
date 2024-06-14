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

local CROP_COUNT = 2
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

graphics.setFont(graphics.newFont(50))
local font = love.graphics.getFont()

local credits = [[
Dustbowl: a game by June Turner and Lily Chrisman

Programming:
June Turner
Lily Chrisman

Artwork:
Lily Chrisman
June Turner

Composition:
June Turner

Presentation:
Lily Chrisman
]]

player = {
	x = 0,
	y = 0,
	inventory = {
		{ name = "gloves",          count = nil, text = graphics.newText(font) },
		{ name = "hoe",             count = nil, text = graphics.newText(font) },
		{ name = "watering_can",    count = 100, text = graphics.newText(font) },

		{ name = "corn_seeds",      count = 12,  text = graphics.newText(font) },
		{ name = "harvested_corn",  count = 10,  text = graphics.newText(font) },

		{ name = "wheat_seeds",     count = 7,   text = graphics.newText(font) },
		{ name = "harvested_wheat", count = 15,  text = graphics.newText(font) },

		{ name = "whistle",         count = 500, text = graphics.newText(font) },
	},
	currentItem = 1,
	dir = 0,
	frame = 0,
	frametimer = 0,
	health = 100,
	sheltered = false
}
boyTimer = 0
local boyCropCount = 0
itemIds = {}
for i, itemInfo in ipairs(player.inventory) do
	itemIds[itemInfo.name] = i
	itemInfo.use = select(2, xpcall(require, function()
		return { use = function() end }
	end, "items." .. itemInfo.name)).use
end

local tracks
local dustStormTimer = 10
local dustStormCount = 0

money = 200
local cropPrice = 1

local parts = {
	{
		frame = 0,
		index = 1,
		notes = require("midicsv").getEventTimes("sounds/percussion.csv", function(_, _, type, _, note)
			return type == "Note_on_c" and note == "56"
		end)
	},
	{
		frame = 0,
		index = 1,
		notes = require("midicsv").getEventTimes("sounds/harmonica.csv", function(_, _, type)
			return type == "Note_on_c"
		end)
	},
	{
		frame = 0,
		index = 1,
		notes = require("midicsv").getEventTimes("sounds/banjo.csv", function(_, _, type)
			return type == "Note_on_c"
		end)
	},
	{
		frame = 0,
		index = 1,
		notes = require("midicsv").getEventTimes("sounds/percussion.csv", function(_, _, type, _, note)
			return type == "Note_on_c" and note == "54"
		end)
	},
}

function drawCrops(minx, miny, maxx, maxy)
	for y = miny, maxy do
		for x = minx, maxx do
			local crop = crops[x .. "," .. y]
			if crop then
				batches.crops:add(quad(crop.growth * 16, crop.id * 48, 16, 48, 16 * MAX_GROWTH, 48 * CROP_COUNT), x * 16,
					y * 16 - 36)
			end
		end
	end
end

local bandFrame = 0
local houseCounter = 0
local pastASec = false
function drawHouse()
	houseCounter = houseCounter + 1
	if houseCounter == 1 and player.y >= -96 or houseCounter == 2 and player.y < -96 then
		graphics.draw(assets.house, -64, -160)
	end
	if houseCounter == 2 then
		houseCounter = 0
	end
	batches.band:clear()
	local songPos = tracks.normal:tell()
	if songPos > 1 then
		pastASec = true
	elseif pastASec then
		pastASec = false
		for _, part in ipairs(parts) do
			part.index = 1
		end
	end
	for i, part in ipairs(parts) do
		if (part.notes[part.index] or 10000) < songPos then
			if i == 2 or i == 3 then
				if part.notes[part.index] ~= part.notes[part.index - 1] then
					part.frame = (part.frame + 1) % 2
				end
			end
			part.index = part.index + 1
		end
		if i == 1 or i == 4 then
			local hit = part.index > 1 and part.notes[part.index - 1] > songPos - 0.1
			part.frame = hit and 1 or 0
		end
		batches.band:add(quad(16 * i - 16, 24 * part.frame, 16, 24, 64, 48), -68 + 15 * i, -110)
	end
	graphics.draw(batches.band)
end

function love.load()
	tracks = {
		wind = love.audio.newSource("sounds/wimdy.ogg", "static"),
		normal = love.audio.newSource("sounds/calmbeforetheduststorm.ogg", "static"),
		storm = love.audio.newSource("sounds/dustbowlcore.ogg", "static"),
	}

	tracks.wind:setLooping(true)
	tracks.normal:setLooping(true)
	love.audio.play(tracks.wind)
	love.audio.play(tracks.normal)

	for i = 1, 20 do
		local x = math.random(-8, 8)
		local y = math.random(-2, 4)
		crops[x .. "," .. y] = {
			growth = math.random(0, 6),
			id = math.random(0, CROP_COUNT - 1)
		}
		farmLands[x .. "," .. y] = {
			hydration = math.random(0, 4)
		}
	end
end

function love.draw()
	-- dying cowboy color

	local filterIntensity = 1
	if dustStormTimer < -60 - 10 * dustStormCount + 10 then
		filterIntensity = 1 + (dustStormTimer + 60 + 10 * dustStormCount) / 10
	elseif dustStormTimer < 0 then
		filterIntensity = 2
	elseif dustStormTimer < 10 then
		filterIntensity = 2 - dustStormTimer / 10
	end

	print(filterIntensity)
	tracks.wind:setVolume(filterIntensity / 2)
	tracks.wind:setPitch(filterIntensity)
	tracks.normal:setVolume(2 - filterIntensity)
	--tracks.storm:setVolume(math.min(1, math.max(0, math.min(-dustStormTimer / 5, dustStormTimer / 5 + 12))))

	local f = filterIntensity ^ 2
	graphics.setColor(1 * (player.health / 100), (1 - 0.05 * f) * (player.health / 100) ^ 2,
		(1 - 0.13 * f) * (player.health / 100) ^ 2)
	local w, h = graphics.getDimensions()
	graphics.scale(4)
	graphics.translate(-player.x + w / 8, -player.y + h / 8)

	local screenMinTileX = math.floor((player.x - w / 8) / 16)
	local screenMaxTileX = math.floor((player.x + w / 8) / 16)
	local screenMaxTileY = math.floor((player.y + h / 8) / 16)
	local screenMinTileY = math.floor((player.y - h / 8) / 16)

	batches.ground:clear()
	for i = screenMinTileX, screenMaxTileX do
		for j = screenMinTileY, screenMaxTileY do
			batches.ground:add(i * 16, j * 16)
		end
	end

	graphics.draw(batches.ground, 0, 0)

	batches.crops:clear()
	local playerTileY = math.floor(player.y / 16 + 0.25)
	drawCrops(screenMinTileX, screenMinTileY, screenMaxTileX, playerTileY)
	batches.soil:clear()
	for posStr, soil in pairs(farmLands) do
		local x = tonumber(posStr:match("[^,]+"))
		local y = tonumber(posStr:sub(posStr:find(",") + 1))
		local px = x * 16
		local py = y * 16
		local c = soil.hydration / 5 * 1.5
		batches.soil:setColor(c * (0.8 - 1) + 1, c * (0.4 - 0.7) + 0.7, c * (0.2 - 0.5) + 0.5)
		batches.soil:add(quad(0, 0, 24, 24, 24, 24), px - 4, py - 4)
	end
	graphics.draw(batches.soil)

	graphics.draw(batches.crops)

	drawHouse()

	if not player.sheltered then
		batches.player:clear()
		batches.player:add(quad(player.dir * 16, player.frame * 24, 16, 24, 16 * 4, 24 * 4), player.x - 8, player.y - 16)
		graphics.draw(batches.player)
	end

	batches.boy:clear()
	batches.boy:add(quad((boyTimer > 2) and 16 or 48, math.floor(boyTimer * 10) % 4 * 24, 16, 24, 16 * 4, 24 * 4),
		player.x - math.abs(boyTimer - 2) * w / 8 - 24, player.y - 16)
	graphics.draw(batches.boy)

	drawHouse()

	batches.crops:clear()
	drawCrops(screenMinTileX, playerTileY, screenMaxTileX, screenMaxTileY + 2)

	graphics.draw(batches.crops)

	graphics.origin()
	local boxSize = 50
	local baseOffset = 10
	local offset = baseOffset
	for i, itemInfo in ipairs(player.inventory) do
		local backColor
		local borderColor
		if i == player.currentItem then
			backColor = { r = 1, g = 1, b = 1 }
			borderColor = { r = 0.4, g = 0.4, b = 0.4 }
		else
			backColor = { r = 0.8, g = 0.7, b = 0.5 }
			borderColor = { r = 0.3, g = 0.2, b = 0 }
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
		graphics.print("$" .. tostring(money), 0, 60)
	end
end

function collide(px, py, x, y, c)
	local l, r, t, b = c.l, c.r, c.t, c.b
	l = l - 4
	r = r + 4
	if px < r and px > l then
		if py >= b and py + y < b then
			py = b
			y = 0
		end
		if py <= t and py + y > t then
			py = t
			y = 0
		end
	elseif py < b and py > t then
		if px >= r and px + x < r then
			px = r
			x = 0
		end
		if px <= l and px + x > l then
			px = l
			x = 0
		end
	end
	return px, py, x, y
end

local colliders = {
	{ l = -64, r = 64, t = -160, b = -96 },
	{ l = -58, r = 18, t = -96,  b = -69 },
	{ l = 16,  r = 58, t = -100, b = -88 },
	{ l = 52,  r = 58, t = -96,  b = -75 },
}

function love.update(dt)
	if player.sheltered then
		player.health = math.min(100, player.health + 1 * dt)
		dt = dt * 4
	end
	boyTimer = boyTimer - dt / 2

	if boyTimer < 2 and boyTimer > 1 then
		boyCropCount = boyCropCount + player.inventory[itemIds.harvested_corn].count +
		player.inventory[itemIds.harvested_wheat].count
		player.inventory[itemIds.harvested_wheat].count = 0
		player.inventory[itemIds.harvested_corn].count = 0
	end

	if boyTimer < 0 then
		money = money + boyCropCount * cropPrice
		boyCropCount = 0
	end

	for pos, crop in pairs(crops) do
		if math.random() / dt < 0.01 * (farmLands[pos] or { hydration = 0 }).hydration then
			crop.growth = math.min(crop.growth + 1, MAX_GROWTH - 2)
		end
	end
	local isDown = love.keyboard.isDown
	if not player.sheltered then
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

		if y == -1 and player.y == -88 and player.x > 31 and player.x < 39 then
			player.sheltered = true
		end

		x = x * 50 * dt * (player.health / 100) ^ 2
		y = y * 50 * dt * (player.health / 100) ^ 2

		for _, col in ipairs(colliders) do
			player.x, player.y, x, y = collide(player.x, player.y, x, y, col)
		end

		player.x = player.x + x
		player.y = player.y + y

		-- select item
		for i = 1, #player.inventory do
			if isDown(tostring(i)) then
				player.currentItem = i
			end
		end

		-- use item
		if isDown("space") then
			local currentItem = player.inventory[player.currentItem]
			local pos = math.floor(player.x / 16) .. "," .. math.floor(player.y / 16)
			print(pos)

			currentItem:use(pos)
		end
	elseif isDown("down") or isDown("s") then
		player.sheltered = false
	end

	dustStormTimer = dustStormTimer - dt
	if dustStormTimer < 0 then
		if dustStormTimer < -60 - 10 * dustStormCount then
			dustStormTimer = 300 - math.random(0, 30 * dustStormCount)
			dustStormCount = dustStormCount + 1
			money = money - dustStormCount * 25
			cropPrice = math.floor(cropPrice * 80) / 100
			if money < 0 then
				error("\nYOU RAN OUT OF MONEY AND STARVED      GAME OVER\n" .. credits)
			end
		end
		if not player.sheltered then
			player.health = player.health - 5 * dt
			if player.health <= 0 then
				error("\nYOU INHALED TOO MUCH DUST      GAME OVER\n" .. credits)
			end
		end
		for pos, farmland in pairs(farmLands) do
			if math.random() / dt < 0.03 then
				if farmland.hydration <= 0 then
					farmLands[pos] = nil
				else
					farmland.hydration = farmland.hydration - 1
				end
			end
		end
		for pos, crop in pairs(crops) do
			if math.random() / dt < 0.01 then
				crop.growth = 7
			end
		end
	end
end
