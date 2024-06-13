return {
	getEventTimes = function(file, predicate)
		local ret = {}
		local contents = love.filesystem.read(file)
		local stepCount = 19200
		for line in contents:gmatch("[^\n]*") do
			local values = {}
			for v in line:gmatch(" *([^,]+)") do
				table.insert(values, v)
			end
			local _, time, type = unpack(values)
			if type == "Header" then
				stepCount = tonumber(values[6])
			end
			if predicate(unpack(values)) then
				table.insert(ret, tonumber(time) / stepCount)
			end
		end
		return ret
	end
}
