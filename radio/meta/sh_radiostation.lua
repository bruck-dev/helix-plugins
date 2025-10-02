
ix.meta = ix.meta or {}

local STATION = ix.meta.radioStation or {}
STATION.__index = STATION
STATION.name = "undefined"
STATION.description = "undefined"
STATION.uniqueID = "undefined"
STATION.frequency = 0

STATION.trackList = {}                  -- string paths for tracks or radio stream. can also be a single string if you want it to loop. does not support variable bit rate mp3s
STATION.trackDelay = 0                  -- if not live, this is the delay in seconds between each track being played from the tracklist. can be a number or a table of {["min"] = x, ["max"] = y} or {x, y, z}
                                        -- recommend at least a 1 second delay between tracks if you're playing music or else it can get rather cluttered
STATION.isStream = false                -- whether or not the string path is a radio stream. will NOT cycle to the next track in the list if true; will only play index 1 or the single string

-- unused, but can be used to create UI elements
function STATION:GetName()
    return self.name
end
function STATION:GetDescription()
    return self.description
end

-- returns the frequency, formatted for comparison
function STATION:GetFrequency()
    return string.format("%.1f", self.frequency)
end

-- checks if the track list is valid before playing on radios
function STATION:CanPlay()
    return self.trackList or (istable(self.trackList) and next(self.trackList) != nil)
end

-- returns the time in seconds that will delay the next track change
function STATION:GetDelay()
    local delay = self.trackDelay
    if istable(delay) then
        if (delay["min"] and delay["max"]) then
            delay = math.random(delay["min"], delay["max"])
        else
            delay = delay[math.random(1, #delay)]
        end
    end

    return delay
end

-- utility function to create things like custom delays per station for emergency announcements and such
function STATION:GetNextTrack()
    local index = ix.radio.stations.instances[self.uniqueID].trackIndex + 1

    if index > #self.trackList then
        return self.trackList[1]
    else
        return self.trackList[index]
    end
end

-- reserved
function STATION:Register()
end

-- creates the server timer that changes the track when the previous one ends
if SERVER then
    function STATION:InitializeTimer()
        -- initialize base values
        local id = self.uniqueID
        local trackIndex = ix.radio.stations.instances[id].trackIndex or math.random(1, #self.trackList)
        local startTime = CurTime()
        local track = self.trackList[trackIndex]

        ix.radio.stations.instances[id].startTime = startTime
        ix.radio.stations.instances[id].trackIndex = trackIndex
        ix.radio.stations.instances[id].track = track

        -- then create a repeating timer to change the track, adjusting the repeat time to the new track length every instance
        local station = self
        timer.Create("ixRadioStation_" .. id, SoundDuration(station.trackList[trackIndex]) + station:GetDelay(), -1, function()
            trackIndex = trackIndex + 1
            if trackIndex > #station.trackList then
                trackIndex = 1
            end
            track = station.trackList[trackIndex]
            startTime = CurTime()

            ix.radio.stations.instances[id].trackIndex = trackIndex
            ix.radio.stations.instances[id].startTime = startTime
            ix.radio.stations.instances[id].track = track

            timer.Adjust("ixRadioStation_" .. id, SoundDuration(station.trackList[trackIndex]) + station:GetDelay())

            for _, entity in ipairs(ents.FindByClass("ix_radio_*")) do
                if entity.EnableStations and tonumber(entity:GetFrequency()) == station.frequency then
                    entity:StopPlaying()
                    entity.station = station
                    entity.path = track
                    entity.startTime = startTime
                end
            end
        end)
    end
end

ix.meta.radioStation = STATION
