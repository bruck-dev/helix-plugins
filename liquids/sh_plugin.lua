
PLUGIN.name = "Liquids Library"
PLUGIN.description = "Adds support for tracking liquids inside of containers, and sources to fill them."
PLUGIN.author = "bruck"

-- blah blah blah in short you are free to edit and reupload this as long as you dont charge for changes you make and so long as i am properly credited for my work as a primary author :)
-- id also like to credit adolphus and TERRANOVA for the original form of the idea. while this is a total, ground-up rewrite, i would not have been able to do it without taking inspiration from his work
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)
ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.Include("sh_sources.lua")
ix.util.Include("sh_config.lua")