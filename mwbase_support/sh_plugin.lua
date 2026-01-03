
PLUGIN.name = "MW Base Support"
PLUGIN.description = "Adds support for MWB attachments and weapons in an immersive way."
PLUGIN.author = "bruck"
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


if !(mw_utils) then return end

ix.util.Include("sh_config.lua")
ix.util.Include("sh_net.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)