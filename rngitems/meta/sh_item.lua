
local ITEM = ix.meta.item

ITEM.rngModels = nil            -- the list of models that the plugin will randomly select from
ITEM.rngSkins = nil             -- bool that determines if the item should use randomized skins, based on the item's model (this is done after the RNG model is decided)

-- EXAMPLE
--[[
ITEM.rngModels = {
    "models/griim/foodpack/sodacan_cocacola.mdl",
    "models/griim/foodpack/sodacan_pepsi.mdl",
    "models/sodacan_solo/sodacan_solo.mdl",
    "models/sodacan_pasito/sodacan_pasito.mdl",
    "models/sodacan_cream/sodacan_cream.mdl",
}
ITEM.rngSkins = true
]]--

function ITEM:GetModel()
    return self:GetData("model", self.model)
end

function ITEM:GetSkin()
    return self:GetData("skin", self.skin or 0)
end