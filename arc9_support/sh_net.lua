
local PLUGIN = PLUGIN

if SERVER then
    util.AddNetworkString("ixARC9UpdatePreset")
    util.AddNetworkString("ixARC9SendPreset")

    net.Receive("ixARC9UpdatePreset", function(length, client)
        local id = net.ReadUInt(32)
        local character = client:GetCharacter()

        if (character and character:GetID() == id) then
            local weapon = ents.GetByIndex(net.ReadUInt(32))
            local preset = net.ReadString()
            
            if weapon.ixItem then
                weapon.ixItem:SetData("preset", preset)
            end
        end
    end)
else
    -- custom implementation of arc9_sendpreset in case it ever changes in an update
    net.Receive("ixARC9SendPreset", function(len)
        local weapon = net.ReadEntity()
        local preset = net.ReadString()
        
        if IsValid(weapon) and weapon.ARC9 then
            weapon:LoadPresetFromTable(weapon:ImportPresetCode(preset), true)
        end
    end)
end