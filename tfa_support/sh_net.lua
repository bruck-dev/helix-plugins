
local PLUGIN = PLUGIN

if SERVER then
    util.AddNetworkString("ixTFAStopCustomize")

    net.Receive("ixTFAStopCustomize", function(length, client)
        local id = net.ReadUInt(32)
        local character = client:GetCharacter()

        if (character and character:GetID() == id) then
            local weapon = ents.GetByIndex(net.ReadUInt(32))
            weapon:SetCustomizing(false)
        end
    end)
end