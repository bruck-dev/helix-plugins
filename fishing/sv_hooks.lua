
if ix.area then
    local PLUGIN = PLUGIN

    function PLUGIN:FishingAreaThink()
        if !ix.config.Get("useBiomeZones", false) then return end

        local bobbers = ents.FindByClass("j_fishing_hook")
        if table.IsEmpty(bobbers) then return end

        for _, bobber in ipairs(bobbers) do
            if !IsValid(bobber) then
                continue
            end

            local overlappingBoxes = {}
            local position = bobber:GetPos() + bobber:OBBCenter()

            for id, info in pairs(ix.area.stored) do
                if (position:WithinAABox(info.startPosition, info.endPosition)) then
                    overlappingBoxes[#overlappingBoxes + 1] = info["type"]
                end
            end

            -- zones can overlap, and if they do, you can catch fish from both overlapping zones as expected
            if (#overlappingBoxes > 0) then
                for _, v in ipairs(overlappingBoxes) do
                    if !bobber:HasArea(v) then
                        table.insert(bobber.ixAreas, v)
                    end
                end
                bobber.ixInArea = true
            else
                bobber.ixInArea = false
            end

        end
    end

end