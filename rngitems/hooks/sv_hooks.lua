
local PLUGIN = PLUGIN

-- the plugin has to be loaded before this fires, so put it VERY FIRST IN YOUR PLUGIN LOAD ORDER, BEFORE ANY ITEMS ARE CREATED
function PLUGIN:OnItemInstanced(item)
    if item.rngModels then
        if item:GetData("model", nil) == nil then
            item:SetData("model", item.rngModels[math.random(1, #item.rngModels)])
        end
    end
end