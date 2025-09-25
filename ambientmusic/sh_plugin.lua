
local PLUGIN = PLUGIN

PLUGIN.name = "Ambient Music"
PLUGIN.description = "Adds a system to play and configure ambient music on the client side."
PLUGIN.author = "bruck"
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)
ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.Include("sh_config.lua")

-- do NOT include the 'sound/' prefix in your file names for the track list
PLUGIN.ambientTracks = {
    --"music/your/track/here.mp3",
    --"music/track/number/2.mp3",
    --"music/etc.mp3",
}