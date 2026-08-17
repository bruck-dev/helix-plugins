
local CHAR = ix.meta.character

function CHAR:GetHitArmor(hitgroup)
    if !hitgroup then return nil end
    
    for k, _ in self:GetInventory():Iter() do
        if k.isArmor and k:GetData("equip", false) and k.hitgroups[hitgroup] then
            return k
        end
    end

    if ix.charPanel then
        for _, v in ipairs(self:GetCharPanel():GetItems()) do
            if v.isArmor and v.hitgroups[hitgroup] then
                return v
            end
        end
    end

    return nil
end