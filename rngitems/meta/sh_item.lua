
local ITEM = ix.meta.item

function ITEM:GetModel()
    return self:GetData("model", self.model)
end