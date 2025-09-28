PLUGIN.name = "Immersive Radio"
PLUGIN.description = "Adds support for a multitude of radio features, including mobile/handheld items, stationary radios, and music stations."
PLUGIN.author = "bruck"
PLUGIN.specialThanks = "nebulous.cloud, fauxzor, Adolphus"
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

ix.util.Include("sh_commands.lua")
ix.util.Include("sh_config.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)
ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)