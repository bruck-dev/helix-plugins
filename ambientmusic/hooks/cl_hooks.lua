
local PLUGIN = PLUGIN

net.Receive("ixAmbientMusic", function(length)
    local state = net.ReadBool()

    if state then
        LocalPlayer():AmbientMusicStart()
    else
        LocalPlayer():AmbientMusicStop()
    end
end)

function PLUGIN:CharacterLoaded(char)
    local client = LocalPlayer()

    client:AmbientMusicStop()
    client:AmbientMusicStart()
end

-- if any hook calls return false, the music will not play for that timer roll.
function PLUGIN:CanPlayAmbientMusic(client)
end