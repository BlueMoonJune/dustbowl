local cooldown = 120

return {
	use = function(self, _)
		if cooldown > 0 then
			cooldown = cooldown - 1
			return
		end
		if boyTimer < 0 then
			cooldown = 120
			boyTimer = 4
			money = money - 5
		end
	end
}
