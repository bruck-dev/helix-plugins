
local CHAR = ix.meta.character

-- Checks if the player has a cigarette item in their mouth and returns it if they do.
function CHAR:HasSmokableEquipped()
    for _, v in ipairs(self:GetInventory():GetItemsByBase("base_smokable", false)) do
        if v:GetData("equip", false) then
            return true, v
        end
    end

    return false, nil
end

-- Checks if the player is actively smoking and returns the item if they are.
function CHAR:IsSmoking()
    for _, v in ipairs(self:GetInventory():GetItemsByBase("base_smokable", false)) do
        if v:GetData("equip", false) and v:IsLit() then
            return true, v
        end
    end

    return false, nil
end

-- Checks if the player has a valid lighter item.
function CHAR:HasLighter()
    for _, v in pairs(self:GetInventory():GetItems(false)) do -- iter doesnt check bags so you are stuck with the slow way
        if v.canLightSmokable then
            return true, v
        end
    end
    
    return false, nil
end