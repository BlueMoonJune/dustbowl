return {
    use = function (self, pos)
        if self.count > 0 then
            local crop = crops[pos]
            if not crop and farmLands[pos] then
                local cropName = self.name:sub(1, -7)
                crops[pos] = {
                    growth = 0,
                    id = cropIDs[cropName]
                }
                self.count = self.count - 1
            end
        end
    end
}