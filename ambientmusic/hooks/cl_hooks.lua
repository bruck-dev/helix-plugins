
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

-- use this to determine whether or not music should play when the start function is called
function PLUGIN:ShouldBlockAmbientMusic(client)
end