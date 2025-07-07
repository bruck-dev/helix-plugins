
local CHAR = ix.meta.character

function CHAR:GetWornItems()
    local worn = {}

    for _, v in ipairs(self:GetInventory():GetItemsByBase("base_wearable_bonemerge", true)) do
        if v:GetData("equip", false) then
            table.insert(worn, v)
        end
    end

    return worn
end