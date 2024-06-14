local cooldown = 120
local sfx = love.audio.newSource("sounds/whistle.ogg", "static")

return {
	use = function(self, _)
		if cooldown > 0 then
			cooldown = cooldown - 1
			return
		end
		if boyTimer < 0 then
			love.audio.play(sfx)
			cooldown = 120
			boyTimer = 4
			money = money - 5
		end
	end
}
