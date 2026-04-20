
local PLUGIN = PLUGIN

PLUGIN.name = "Inspect Items"
PLUGIN.description = "Integrates Kona's 3D Item Inspector into Helix as a universal item function, and adds some custom features."
PLUGIN.author = "Kona, bruck"
PLUGIN.workshopAddon = "Give Kona some love: https://steamcommunity.com/sharedfiles/filedetails/?id=3697839641"
PLUGIN.license = "You probably shouldn't charge any money for edits to this, as almost of the original code is Kona's. No formal license since, as this is an unofficial fork."

ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)
ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.Include("sh_config.lua")