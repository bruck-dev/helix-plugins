
ix.meta = ix.meta or {}

local STATION = ix.meta.radioStation or {}
STATION.__index = STATION
STATION.name = "undefined"
STATION.description = "undefined"
STATION.uniqueID = "undefined"
STATION.frequency = 0

STATION.audio = {
    trackList = {},         -- string paths for tracks or radio stream. if a stream, make a single string to the stream link. does not support variable bit rate mp3s
    delay = 0,              -- if not live, this is the delay in seconds between each track being played from the tracklist. can be a number or a table of {["min"] = x, ["max"] = y} or {x, y, z}
    isStream = false,       -- whether or not this is STREAMED URL audio, meaning it does not have a start/stop time
}        

STATION.broadcasts = {
    messageList = {},       -- list of strings used as broadcast messages
    delay = 300,            -- will be sent over the frequency ever "interval" seconds, which can be a table of {["min"] = x, ["max"] = y} or {x, y, z}
    name = nil,             -- optional string used in place of the station's name for broadcasts (e.g, a fake DJ name)
    synced = false,         -- whether or not the broadcasts should ignore the interval argument and instead be sent when an audio track ends. only works for non-streams, and the indices are linked together
}

-- returns the station's name. by default, only used if STATION.broadcasts is valid and the 'name' parameter does not exist
function STATION:GetName()
	return self.name
end

-- unused, but can be used for UI elements
function STATION:GetDescription()
    return self.description
end

-- returns the frequency, formatted for comparison
function STATION:GetFrequency()
    return string.format("%.1f", self.frequency)
end

-- checks if the track list is valid before playing on radios
function STATION:CanPlayAudio()
    return self.audio.trackList and (isstring(self.audio.trackList) or next(self.audio.trackList) != nil)
end

-- checks if the broadcasts list is valid
function STATION:CanBroadcast()
    return self.broadcasts and next(self.broadcasts) != nil and (isstring(self.broadcasts.messageList) or next(self.broadcasts.messageList) != nil) and (self.broadcasts.delay != nil or self.broadcasts.synced)
end

-- reserved
function STATION:Register()
end

if SERVER then
    -- returns associated station instance
    function STATION:GetInstance()
        return ix.radio.stations.instances[self.uniqueID]
    end

    -- calculates the next track + index
    function STATION:GetNextTrack()
        local instance = self:GetInstance()
        local index = (instance.audio and instance.audio.index or 0) + 1
    
        local trackList = self.audio.trackList or {}
        if index > #trackList then
            return trackList[1], 1
        else
            return trackList[index], index
        end
    end

    -- returns the instance's currently playing track, if it exists
    function STATION:GetPlayingTrack()
        local instance = self:GetInstance()
        return instance and instance.audio and instance.audio.track
    end

    -- called when the station ends the given track/index
    function STATION:OnTrackEnd(track, index)
        return
    end
    
    -- calculates the next broadcast + index
    function STATION:GetNextBroadcast()
        local instance = self:GetInstance()
        local index = (instance.broadcasts and instance.broadcasts.index or 0) + 1
    
        local messageList = self.broadcasts.messageList or {}
        if isstring(messageList) then
            return messageList, 1
        else
            if index > #messageList then
                return messageList[1], 1
            else
                return messageList[index], index
            end
        end
    end
    
    -- sends a broadcast; either the next one in the list, or the specified index
    function STATION:SendBroadcast(index)
        local instance = self:GetInstance()
        if !self.broadcasts or !instance or !instance.broadcasts then return false end

        local message
        if index then
            message = (self.broadcasts.messageList or {})[index]
        else
            message, index = self:GetNextBroadcast()
        end

        if !message or !index then return end

        instance.broadcasts.index = index
        ix.chat.Send(nil, "radio_broadcast", message, nil, nil, {frequency = self:GetFrequency(), garble = false, power = 1, name = self.broadcasts.name or self:GetName()})

        return true
    end

    -- returns all station-enabled radios tuned to the station
    function STATION:GetListeners()
        local radios = {}
        local freq = self:GetFrequency()
        for _, entity in ipairs(ents.FindByClass("ix_radio_*")) do
            if entity.EnableStations and entity:GetFrequency() == freq then
                table.insert(radios, entity)
            end
        end
        return radios
    end

    -- picks a random value (or returns the constant) from the given value; used for delays
    local function pickRandom(options)
        local delay = options
        if istable(delay) then
            if (delay["min"] and delay["max"]) then
                delay = math.random(delay["min"], delay["max"])
            else
                delay = delay[math.random(1, #delay)]
            end
        end
    
        return delay
    end

    -- sets up all necessary server-side timers for audio and broadcasts
    function STATION:InitializeTimers()
        local station = self
        local id = station.uniqueID
        local instance = self:GetInstance()

        if station:CanPlayAudio() then
            ix.radio.stations.instances[id].audio = instance.audio or {}
            if !station.audio.isStream then
                local trackList = station.audio.trackList or {}
                local delay = station.audio.delay or 0
                local trackIndex = instance.audio.index or math.random(1, #trackList)
                local track = trackList[trackIndex]
                local trackDuration = SoundDuration(track)
                local broadcast = self.broadcasts and next(self.broadcasts.messageList) != nil and self.broadcasts.synced

                instance.audio.startTime = CurTime()
                instance.audio.index = trackIndex
                instance.audio.track = track
                instance.audio.trackList = trackList

                local function setupEndTimer(duration, trackEnding, indexEnding)
                    timer.Simple(duration, function()
                        station:OnTrackEnd(trackEnding, indexEnding)
                        if broadcast then
                            station:SendBroadcast(indexEnding)
                        end

                        -- only clear the parameters that indicate a track is ACTIVELY playing, index is used to calculate the next one
                        instance.audio.startTime = nil
                        instance.audio.track = nil
                    end)
                end

                -- creates two timers: one that fires when the first track ends, and another that ends after the track ends + the delay amount to play the next song
                -- timer will automatically change length depending on the new track length, and recall the track end timer
                setupEndTimer(trackDuration, track, trackIndex)
                timer.Create("ixRadioStationTrack_" .. id, trackDuration + pickRandom(delay), -1, function()
                    track, trackIndex = station:GetNextTrack()
                    trackDuration = SoundDuration(track)

                    -- run OnTrackEnd when the file actually ends, and ignore any added delay
                    setupEndTimer(trackDuration, track, trackIndex)

                    instance.audio.startTime = CurTime()
                    instance.audio.index = trackIndex
                    instance.audio.track = track

                    timer.Adjust("ixRadioStationTrack_" .. id, trackDuration + pickRandom(delay))
                end)
            else
                instance.audio.track = (istable(station.audio.trackList) and station.audio.trackList[1]) or station.audio.trackList
            end
        end

        if station:CanBroadcast() then
            ix.radio.stations.instances[id].broadcasts = instance.broadcasts or {}

            local messageList = station.broadcasts.messageList or {}
            instance.broadcasts.messageList = messageList

            if !station.broadcasts.synced then
                local delay = station.broadcasts.delay or 300
                timer.Create("ixRadioStationBroadcast_" .. id, pickRandom(delay), -1, function()
                    station:SendBroadcast()
                    timer.Adjust("ixRadioStationBroadcast_" .. id, pickRandom(delay))
                end)
            end
        end
    end
end

ix.meta.radioStation = STATION
