
PLUGIN.name = "TFA Support"
PLUGIN.description = "Adds support for TFA attachments and weapons in an immersive way."
PLUGIN.author = "bruck"
PLUGIN.specialThanks = "Taxin2012, who's work I briefly referenced while deciding the best way to set everything up."
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


if !(TFA) then return end

ix.util.Include("sh_config.lua")
ix.util.Include("sh_net.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)

function PLUGIN:OnLoaded()
    if SERVER then
        -- config options
        GetConVar("sv_tfa_attachments_enabled"):SetBool(ix.config.Get("enableCustomization(Tfa)", true))
        GetConVar("sv_tfa_bullet_penetration"):SetBool(ix.config.Get("enableBulletPenetration(Tfa)", true))
        GetConVar("sv_tfa_bullet_ricochet"):SetBool(ix.config.Get("enableRicochets(Tfa)", false))
        GetConVar("sv_tfa_bullet_doordestruction"):SetBool(ix.config.Get("enableDoorDestruction(Tfa)", false))
    else
        -- technically not required but disables the annoying BEEP when initializing a weapon
        GetConVar("cl_tfa_attachments_persist_enabled"):SetBool(false)
    end
end