
local PLUGIN = PLUGIN

function PLUGIN:InventoryItemAdded(oldInv, newInv, item)
    if item.rngModels and item:GetData("model", nil) == nil then
        item:SetData("model", item.rngModels[math.random(1, #item.rngModels)])
    end
end

function PLUGIN:OnItemSpawned(entity)
    local itemTable = entity:GetItemTable()
    if itemTable and itemTable.rngModels then
        local item = entity.ixItemID and ix.item.instances[entity.ixItemID]
        if item and item:GetData("model", nil) == nil then
            item:SetData("model", item.rngModels[math.random(1, #item.rngModels)])
            entity:SetModel(item:GetModel())
        end
    end
end