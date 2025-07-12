
PLUGIN.name = "ArcCW Support"
PLUGIN.description = "Adds support for ArcCW attachments and weapons in an immersive way."
PLUGIN.author = "bruck"
PLUGIN.specialThanks = "Hayter - a lot of my work wouldn't have been possible without the ability to reference his :)"
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


if !(ArcCW) then return end

ix.util.Include("sh_config.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)

function PLUGIN:OnLoaded()
    if SERVER then
        -- config options
        GetConVar("arccw_attinv_free"):SetBool(ix.config.Get("freeAttachments(ArcCW)", false))
        GetConVar("arccw_enable_penetration"):SetBool(ix.config.Get("enableBulletPenetration(ArcCW)", true))
        GetConVar("arccw_enable_ricochet"):SetBool(ix.config.Get("enableRicochets(ArcCW)", true))
        GetConVar("arccw_enable_dropping"):SetBool(ix.config.Get("enableBulletDrop(ArcCW)", true))

        GetConVar("arccw_enable_customization"):SetBool(true)
    else
        GetConVar("arccw_autosave"):SetBool(false)
    end
end