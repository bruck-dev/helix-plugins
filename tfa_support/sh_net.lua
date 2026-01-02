
local PLUGIN = PLUGIN

if SERVER then
    util.AddNetworkString("ixTFASetCustomize")

    net.Receive("ixTFASetCustomize", function(length, client)
        local id = net.ReadUInt(32)
        local character = client:GetCharacter()

        if (character and character:GetID() == id) then
            local weapon = ents.GetByIndex(net.ReadUInt(32))
            local state = net.ReadBool()
            weapon:SetCustomizing(state)
        end
    end)
end