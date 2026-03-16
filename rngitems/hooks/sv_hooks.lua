
local PLUGIN = PLUGIN

function PLUGIN:InventoryItemAdded(oldInv, newInv, item)
    if item.rngModels and item:GetData("model", nil) == nil then
        item:SetData("model", item.rngModels[math.random(1, #item.rngModels)])
    end

    if item.rngSkins and item:GetData("skin", nil) == nil then
        local skin = math.random(0, util.GetModelInfo(item:GetModel()).SkinCount - 1)
        item:SetData("skin", skin)
    end
end

function PLUGIN:OnItemSpawned(entity)
    local itemTable = entity:GetItemTable()
    if itemTable and (itemTable.rngModels or itemTable.rngSkins) then
        local item = entity.ixItemID and ix.item.instances[entity.ixItemID]
        if item then
            if item.rngModels and item:GetData("model", nil) == nil then
                item:SetData("model", item.rngModels[math.random(1, #item.rngModels)])
                entity:SetModel(item:GetModel())
            end

            if item.rngSkins and item:GetData("skin", nil) == nil then
                local skin = math.random(0, util.GetModelInfo(item:GetModel()).SkinCount - 1)
                item:SetData("skin", skin)
                entity:SetSkin(skin)
            end
        end
    end
end