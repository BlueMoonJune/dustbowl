local cooldown = 30

return {
	use = function(self, pos)
		if cooldown > 0 then
			cooldown = cooldown - 1
			return
		end
		cooldown = 30
		if pos == "16,-1" then
			self.count = math.min(self.count + 5, 100)
		elseif self.count > 0 then
			local soil = farmLands[pos]
			if soil then
				if soil.hydration < 4 then
					soil.hydration = soil.hydration + 1
					self.count = self.count - 1
				end
			end
		end
	end
}

