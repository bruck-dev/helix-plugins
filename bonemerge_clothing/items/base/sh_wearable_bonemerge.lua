
ITEM.base = "base_pacoutfit"

ITEM.name = "Wearable Base"
ITEM.description = "Modified version of the PAC outfit base."
ITEM.category = "Clothing"
ITEM.model = "models/fty/items/darkblueshirt.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "torso"            -- arbitrary value that determines what other clothing items this one is incompatible with. can be a list of slots or a single string slot
ITEM.pacData = {}

ITEM.attribBoosts = {}                  -- optional attribute boosts. of the form {["attribute_id"] = value}

ITEM.equipSound = nil                   -- both can either be a single string path or a list of sound paths
ITEM.unequipSound = nil

-- checks if the passed item has a conflicting outfitCategory slot
function ITEM:CheckForOverlappingSlots(current)
    if !current.outfitCategory then return false end

    local slots1 = {}
    if isstring(self.outfitCategory) then
        slots1[self.outfitCategory] = true
    elseif istable(self.outfitCategory) then
        for _, slot in ipairs(self.outfitCategory) do
            slots1[slot] = true
        end
    end

    if isstring(current.outfitCategory) then
        if slots1[current.outfitCategory] then
            return true
        end
    elseif istable(current.outfitCategory) then
        for _, slot in ipairs(current.outfitCategory) do
            if slots1[slot] then
                return true
            end
        end
    end

    return false
end

function ITEM:EmptyOutfitSlots()
    for k, _ in self.player:GetCharacter():GetInventory():Iter() do
        if k:GetData("equip", false) and k.outfitCategory and (k.id != self.id) then
            if self:CheckForOverlappingSlots(k) then
                if k.RemovePart then
                    k:RemovePart(self.player)
                elseif k.RemoveOutfit then
                    k:RemoveOutfit(self.player)
                end
                break
            end
        end
    end
end

function ITEM:pacAdjust(pacData, client)
    -- for manual overrides of pac data on a per-model basis
    if self.pacDataModels and self.pacDataModels[client:GetModel()] then
        return self.pacDataModels[client:GetModel()]
    end
    
    if self.pacDataFemale and string.find(client:GetModel(), "female") then
        return self.pacDataFemale
    else
        return self.pacData
    end
end

ITEM.functions.Equip = {
    name = "Wear",
    tip = "equipTip",
    icon = "icon16/tick.png",
    OnRun = function(item)
        local client = item.player
        local char = client:GetCharacter()

        item:EmptyOutfitSlots()

        if item.equipSound then
            local snd = item.equipSound
            if istable(snd) then
                snd = snd[math.random(1, #snd)]
            end
            client:GetCharacter():PlaySound(snd)
        end

        item:SetData("equip", true)
        client:AddPart(item.uniqueID, item)

        if item.attribBoosts then
            for k, v in pairs(item.attribBoosts) do
                char:AddBoost(item.uniqueID, k, v)
            end
        end

        item:OnEquipped()
        return false
    end,
    OnCanRun = function(item)
        local client = item.player

        return !IsValid(item.entity) and IsValid(client) and item:GetData("equip") != true and
            hook.Run("CanPlayerEquipItem", client, item) != false
    end
}

ITEM.functions.EquipUn = { -- sorry, for name order.
    name = "Remove",
    tip = "unequipTip",
    icon = "icon16/cross.png",
    OnRun = function(item)
        local client = item.player
        item:RemovePart(client)

        if item.unequipSound then
            local snd = item.unequipSound
            if istable(snd) then
                snd = snd[math.random(1, #snd)]
            end
            client:GetCharacter():PlaySound(snd)
        end

        return false
    end,
    OnCanRun = function(item)
        local client = item.player

        return !IsValid(item.entity) and IsValid(client) and item:GetData("equip") == true and
            hook.Run("CanPlayerUnequipItem", client, item) != false
    end
}