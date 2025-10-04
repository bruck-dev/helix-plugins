
local CHAR = ix.meta.character

function CHAR:GetHitArmor(hitgroup)
    if !hitgroup then return nil end
    
    for k, _ in self:GetInventory():Iter() do
        if k.isArmor and k:GetData("equip", false) and k.hitgroups[hitgroup] then
            return k
        end
    end

    return nil
end