
-- these meta functions are meant to be an API to start using liquids for things other than consumption
-- i used them in my modified version of ixcraft to use them as ingredients, and it worked (with a giant headache), so it's definitely possible to do some interesting things with these
local CHAR = ix.meta.character

-- returns all liquid containers a character has, empty or otherwise
function CHAR:GetLiquidContainers()
    local liqConts = {}

    for _, v in pairs(self:GetInventory():GetItems()) do
        if v.capacity and v.GetLiquid and v.GetVolume then
            table.insert(liqConts, v)
        end
    end

    return liqConts
end

-- returns the total volume a character has for a given liquid, and the containers the volume is spread across
function CHAR:GetHeldVolume(liquid)
    local liqConts = {}

    if !ix.liquids.Get(liquid) then
        return 0, liqConts
    end

    local vol = 0
    for _, v in pairs(self:GetInventory():GetItems()) do
        if v.capacity and v.GetLiquid and v.GetVolume then
            if v:GetLiquid() == liquid then
                vol = vol + v:GetVolume()
                table.insert(liqConts, v)
            end
        end
    end

    return vol, liqConts
end