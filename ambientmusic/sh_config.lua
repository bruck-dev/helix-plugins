
local PLUGIN = PLUGIN

if SERVER then
    -- whether ambient music is enabled for everyone, 'true' does not force it on the client but false will force it off
    ix.config.Add("allowAmbientMusic", true, "Whether or not ambient music should play for players. If false, ambient music will never play, regardless of player local config settings.", function(oldValue, newValue)
        net.Start("ixAmbientMusic")
            net.WriteBool(newValue)
        net.Broadcast()
    end,
    {
        category = "Ambient Music",
    })
else
    -- whether or not ambient music will play for this client
    ix.option.Add("ambientMusicEnable", ix.type.bool, true, {
        category = "Ambient Music",
        OnChanged = function(oldValue, newValue)
            if newValue then
                LocalPlayer():AmbientMusicStart()
            else
                LocalPlayer():AmbientMusicStop()
            end
        end,
    })

    -- lower/upper bound for the interval between tracks in seconds. T = LEN(lastTrack) + rand(MIN, MAX)
    ix.option.Add("ambientMusicIntMin", ix.type.number, 120, {  -- 0 to 5 min
        category = "Ambient Music",
        min = 0,
        max = 300,    
    })
    ix.option.Add("ambientMusicIntMax", ix.type.number, 300, {  -- 5 to 20 min
        category = "Ambient Music",
        min = 300,
        max = 1200,    
    })
    
    -- volume of the ambient music, expressed as a percentage
    ix.option.Add("ambientMusicVolume", ix.type.number, 100, {
        category = "Ambient Music",
        min = 1,
        max = 300,
        OnChanged = function(oldValue, newValue)
            LocalPlayer():AmbientMusicVolume(newValue)
        end,
    })
end