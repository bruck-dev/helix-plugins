
local CHAR = ix.meta.character

function CHAR:GetHitArmor(hitgroup)
    if !hitgroup then return nil end
    
    for _, v in ipairs(self:GetInventory():GetItemsByBase("base_outfit_armor", true)) do
        if v:GetData("equip", false) and v.hitgroups[hitgroup] then
            return v
        end
    end

    return nil
end