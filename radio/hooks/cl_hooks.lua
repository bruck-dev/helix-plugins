
local PLUGIN = PLUGIN

net.Receive("ixRadioStationJoin", function()
    local client = LocalPlayer()
    local radio = net.ReadEntity()
    local path = net.ReadString()
    local isUrl = net.ReadBool()
    local startTime = net.ReadFloat()

    if !IsValid(radio) or (radio.clientAudioChannel and radio.clientAudioChannel:IsValid()) then return end

    local dist = ix.config.Get("radioListenRange", 92)
    local maxDist = dist * 3

    if startTime == -1 then -- if -1, this is a live track
        if isUrl then
            sound.PlayURL(path, "3d noplay", function(channel, err)
                if !IsValid(channel) then return end

                channel:Set3DEnabled(true)
                channel:SetPos(radio:GetPos())
                channel:Set3DFadeDistance(dist, maxDist)
                channel:Play()

                radio.clientAudioChannel = channel
            end)
        else
            path = "sound/" .. path
            sound.PlayFile(path, "3d noplay", function(channel, err)
                if !IsValid(channel) then return end

                channel:Set3DEnabled(true)
                channel:SetPos(radio:GetPos())
                channel:Set3DEnabled(true)
                channel:Set3DFadeDistance(dist, maxDist)
                channel:Play()

                radio.clientAudioChannel = channel
            end)
        end
    else
        if isUrl then
            sound.PlayURL(path, "3d noblock noplay", function(channel, err)
                if !IsValid(channel) then return end

                channel:Set3DEnabled(true)
                channel:SetTime(startTime)
                channel:SetPos(radio:GetPos())
                channel:Set3DFadeDistance(dist, maxDist)
                channel:Play()

                radio.clientAudioChannel = channel
            end)
        else
            path = "sound/" .. path
            sound.PlayFile(path, "3d noblock noplay", function(channel, err)
                if !IsValid(channel) then return end

                channel:Set3DEnabled(true)
                channel:SetTime(startTime)
                channel:SetPos(radio:GetPos())
                channel:Set3DFadeDistance(dist, maxDist)
                channel:Play()

                radio.clientAudioChannel = channel
            end)
        end
    end

    -- adds the radio to the client's list of listened radios. this is mostly for external utility to check if the player is listening to something or not
    local activeRadioChannels = client.activeRadioChannels or {}
    activeRadioChannels[radio:EntIndex()] = true
    client.activeRadioChannels = activeRadioChannels

    if client.AmbientMusicStop then
        client:AmbientMusicStop(true)
    end
end)

net.Receive("ixRadioStationLeave", function()
    local client = LocalPlayer()
    local radio = net.ReadEntity()

    if !IsValid(radio) or !radio.clientAudioChannel or !radio.clientAudioChannel:IsValid() then return end

    radio.clientAudioChannel:Stop()
    radio.clientAudioChannel = nil

    -- removes the radio from the client's active listening tracker
    local activeRadioChannels = client.activeRadioChannels or {}
    activeRadioChannels[radio:EntIndex()] = nil
    client.activeRadioChannels = activeRadioChannels
end)

-- wipes all frequency tracking from stationary radio ents when the player loads a new character
function PLUGIN:CharacterLoaded(character)
	for _, radio in ipairs(ents.FindByClass("ix_radio_*")) do
        radio.canCurrentlyHear = nil
    end
end

-- integration with my ambient music plugin to block ambient tracks when listening to the radio
function PLUGIN:CanPlayAmbientMusic(client)
    if client.activeRadioChannels and next(client.activeRadioChannels) != nil then
        return false
    end
end