
local PLUGIN = PLUGIN
local PLAYER = FindMetaTable("Player")

if CLIENT then
    -- starts the ambient music and associated timer. once ran, will keep going until stopped by an external source
    function PLAYER:AmbientMusicStart()
        if !ix.config.Get("allowAmbientMusic", true) or !ix.option.Get("ambientMusicEnable", true) then return end  -- disable
        if timer.Exists("ixAmbientMusic") then return end                                                           -- already on
        if !PLUGIN.ambientTracks or #PLUGIN.ambientTracks < 1 then return end                                       -- no tracks

        local index = 0
        local tracks = table.Copy(PLUGIN.ambientTracks) -- have to copy here so that shuffle doesnt also act on ambientTracks; think the normal declaration just makes tracks a pointer?
        table.Shuffle(tracks)

        timer.Create("ixAmbientMusic", math.random(ix.option.Get("ambientMusicIntMin", 120), ix.option.Get("ambientMusicIntMax", 300)), 0, function()
            if timer.Exists("ixAmbientMusic") then
                if hook.Run("ShouldBlockAmbientMusic", LocalPlayer()) != true then
                    index = index + 1
                    if index > #tracks then
                        index = 1
                        table.Shuffle(tracks)
                    end

                    local track = tracks[index]

                    sound.PlayFile("sound/" .. track, "noplay", function(channel, err)
                        if !IsValid(channel) then return end
                        LocalPlayer().ambientMusicChannel = channel
                        channel:SetVolume(ix.option.Get("ambientMusicVolume", 100) / 100)
                        channel:Play()
                    end)

                    timer.Adjust("ixAmbientMusic", SoundDuration(track) + math.random(ix.option.Get("ambientMusicIntMin", 120), ix.option.Get("ambientMusicIntMax", 300)), nil, nil)
                else -- if unable to play a new track, skip this one and set the timer to check later. technically not required but shortens the retry time by not including the last track length
                    timer.Adjust("ixAmbientMusic", math.random(ix.option.Get("ambientMusicIntMin", 120), ix.option.Get("ambientMusicIntMax", 300)), nil, nil)
                end
            end
        end)

    end

    -- stops the currently playing ambient track and removes the timer until re-enabled (unless keepTimer is true)
    function PLAYER:AmbientMusicStop(keepTimer)
        if self.ambientMusicChannel then
            self.ambientMusicChannel:Stop()
            self.ambientMusicChannel = nil
        end

        if timer.Exists("ixAmbientMusic") and !keepTimer then
            timer.Remove("ixAmbientMusic")
        end
    end

    -- adjusts the volume of the currently playing ambient track based on the specified value, as a percent
    function PLAYER:AmbientMusicVolume(vol)
        if self.ambientMusicChannel then
            self.ambientMusicChannel:SetVolume(vol / 100)
        end
    end
end