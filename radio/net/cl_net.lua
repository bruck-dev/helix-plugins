
local PLUGIN = PLUGIN

-- i use the entIndex as the literal entity only exists when inside of the PVS; pos wont update outside of PVS, but you wont notice
net.Receive("ixRadioStationJoin", function()
    local client = LocalPlayer()
    local entIndex = net.ReadUInt(16)
    local path = net.ReadString()
    local isUrl = net.ReadBool()
    local pos = net.ReadVector()
    local startTime = net.ReadFloat()

    local channels = client.radioStations or {}

    if !entIndex or (channels[entIndex] and channels[entIndex]:IsValid()) then return end

    local maxDist = ix.config.Get("radioStationListenRange", 384)
    local dist = maxDist / 3

    if startTime < 0 then -- if -1, this is a live track
        if isUrl then
            sound.PlayURL(path, "3d noplay", function(channel, err)
                if !IsValid(channel) then return end
                channel:Set3DEnabled(true)
                channel:SetPos(pos)
                channel:Set3DFadeDistance(dist, maxDist)
                channel:Play()

                channels[entIndex] = channel
            end)
        end
    else
        -- decode is skipped for SetTime; this may not work for all remote URLs
        if isUrl then
            sound.PlayURL(path, "3d noblock noplay", function(channel, err)
                if !IsValid(channel) then return end
                channel:Set3DEnabled(true)
                channel:SetTime(startTime, true)
                channel:SetPos(pos)
                channel:Set3DFadeDistance(dist, maxDist)
                channel:Play()

                channels[entIndex] = channel
            end)
        else
            path = "sound/" .. path
            sound.PlayFile(path, "3d noblock noplay", function(channel, err)
                if !IsValid(channel) then return end
                channel:Set3DEnabled(true)
                channel:SetTime(startTime, true)
                channel:SetPos(pos)
                channel:Set3DFadeDistance(dist, maxDist)
                channel:Play()

                channels[entIndex] = channel
            end)
        end
    end

    client.radioStations = channels
    if client.AmbientMusicStop then
        client:AmbientMusicStop(true)
    end
end)

net.Receive("ixRadioStationLeave", function()
    local client = LocalPlayer()
    local entIndex = net.ReadUInt(16)

    local channels = client.radioStations or {}
    if !channels[entIndex] or !channels[entIndex]:IsValid() then return end

    channels[entIndex]:Stop()
    channels[entIndex] = nil
    client.radioStations = channels
end)

net.Receive("ixRadioFrequencySync", function()
    local client = LocalPlayer()
    local frequencies = net.ReadTable()

    client.frequencies = {}
    for freq, radio in pairs(frequencies or {}) do
        if isentity(radio) then
            client.frequencies[freq] = radio
        else
            client.frequencies[freq] = ix.item.instances[radio]
        end
    end
end)

net.Receive("ixRadioFrequencyJoin", function()
    local client = LocalPlayer()
    local frequency = net.ReadString()
    local radio = net.ReadType()

    frequency = string.format("%.1f", tonumber(frequency))
    if !isentity(radio) then radio = ix.item.instances[radio] end

    client.frequencies = client.frequencies or {}
    client.frequencies[frequency] = radio
end)

net.Receive("ixRadioFrequencyLeave", function()
    local client = LocalPlayer()
    local frequency = net.ReadString()
    frequency = string.format("%.1f", tonumber(frequency))

    client.frequencies = client.frequencies or {}
    client.frequencies[frequency] = nil
end)