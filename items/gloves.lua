return {
	use = function(self, pos)
		local crop = crops[pos]
		if crop and crop.growth then
			if crop.growth == 7 then
				crop.growth = 0
			end
			local cropName = cropNames[crop.id]
			local playerItem = player.inventory[itemIds["harvested_" .. cropName]]
			playerItem.count = playerItem.count + math.floor(math.random(crop.growth, crop.growth * 1.5))
			local seedItem = player.inventory[itemIds[cropName .. "_seeds"]]
			seedItem.count = seedItem.count + math.floor(math.random(crop.growth, crop.growth + 1))

			crops[pos] = nil
		end
	end
}

