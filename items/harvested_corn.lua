local cooldown = 30

return {
	use = function(self, pos)
		if cooldown > 0 then
			cooldown = cooldown - 1
			return
		end
		cooldown = 30
		if self.count > 0 then
			player.health = player.health + 5
			self.count = self.count - 1
		end
	end
}

