
local PLUGIN = PLUGIN

do
    net.Receive("ixLiqSourceEditor", function()
        local entity = net.ReadEntity()

        if (!IsValid(entity) or !CAMI.PlayerHasAccess(LocalPlayer(), "Helix - Manage Liquid Sources", nil)) then
            return
        end

        ix.gui.liqEditor = vgui.Create("ixLiqSourceEditor")
        ix.gui.liqEditor:Setup(entity)
    end)

    net.Receive("ixLiqSourceEdit", function()
        local panel = ix.gui.liqEditor

        if (!IsValid(panel)) then
            return
        end

        local entity = panel.entity

        if (!IsValid(entity)) then
            return
        end

        local key = net.ReadString()
        local data = net.ReadType()
    end)

    net.Receive("ixLiqSourceEditFinish", function()
        local editor = ix.gui.liqEditor

        if (!IsValid(editor)) then
            return
        end

        local entity = editor.entity

        if (!IsValid(entity)) then
            return
        end

        local key = net.ReadString()
        local data = net.ReadType()

        if (key == "name") then
            editor.name:SetText(data)
        elseif (key == "model") then
            local storedModel = entity:GetStoredModel()
            if storedModel then
                editor.model:SetText(entity:GetStoredModel())
            else
                editor.model:SetText(entity:GetModel())
            end
        elseif (key == "liquid") then
            local liquid = entity:GetLiquid()
            if liquid then
                liquid = ix.liquids.Get(liquid)
                editor.liquid:ChooseOption(liquid.name)
            end
        elseif (key == "maxvolume") then
            editor.max:SetValue(data)
        elseif (key == "curvolume") then
            editor.cur:SetValue(data)
        elseif (key == "infinite") then
            editor.inf:SetValue(data)
        elseif (key == "tooltip") then
            editor.tool:SetValue(data)
        end

        surface.PlaySound("buttons/button14.wav")
    end)
end