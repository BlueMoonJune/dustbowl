return {
    use = function (self, pos)
        if self.count > 0 then
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