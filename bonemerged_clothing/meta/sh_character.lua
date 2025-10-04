
local CHAR = ix.meta.character

function CHAR:GetWornItems()
    local worn = {}

    for k, _ in self:GetInventory():Iter() do
        if (k.base and string.find(k.base, "wearable")) and k:GetData("equip", false) then
            table.insert(worn, k)
        end
    end

    return worn
end