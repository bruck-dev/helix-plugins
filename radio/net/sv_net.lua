
local PLUGIN = PLUGIN

util.AddNetworkString("ixRadioStationJoin")
util.AddNetworkString("ixRadioStationLeave")
util.AddNetworkString("ixRadioFrequencyJoin")
util.AddNetworkString("ixRadioFrequencyLeave")
util.AddNetworkString("ixRadioFrequencySync")

net.Receive("ixRadioFrequencySync", function(length, client)
    local id = net.ReadUInt(32)
    local radio = net.ReadEntity()
    local freq = net.ReadString()
    local canHear = net.ReadBool()
    local char = client:GetCharacter()

    if char and char:GetID() == id then
        client.frequencies = client.frequencies or {}
        if canHear then
            client.frequencies[freq] = radio
        else
            client.frequencies[freq] = nil
        end
        PrintTable(client.frequencies)
    end
end)