
PLUGIN.name = "ARC9 Support"
PLUGIN.description = "Adds support for ARC9 attachments and weapons in an immersive way."
PLUGIN.author = "bruck"
PLUGIN.specialThanks = "Adik, Hayter, FoxxoTrystan; a lot of my work wouldn't have been possible without the ability to reference theirs :); Darsu, for helping me debug some base-specific issues."
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


if !(ARC9) then return end

ix.util.Include("sh_config.lua")
ix.util.Include("sh_net.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)

function PLUGIN:OnLoaded()
    if SERVER then
        -- config options
        GetConVar("arc9_hud_force_disable"):SetBool(ix.config.Get("disableWeaponHud(ARC9)", true))
        GetConVar("arc9_free_atts"):SetBool(ix.config.Get("freeAttachments(ARC9)", false))
        GetConVar("arc9_mod_penetration"):SetBool(ix.config.Get("enableBulletPenetration(ARC9)", true))
        GetConVar("arc9_ricochet"):SetBool(ix.config.Get("enableRicochets(ARC9)", true))
        GetConVar("arc9_bullet_physics"):SetBool(ix.config.Get("enablePhysicalBullets(ARC9)", true))

        -- this disables ammo duping, do not change
        GetConVar("arc9_mult_defaultammo"):SetInt(0)

        GetConVar("arc9_atts_nocustomize"):SetInt(0)

        -- optional convars. feel free to delete or change as you please
        GetConVar("arc9_autosave"):SetInt(0)
        GetConVar("arc9_center_bipod"):SetInt(0)
        GetConVar("arc9_center_jam"):SetInt(0)
        GetConVar("arc9_center_reload_enable"):SetInt(0)
        GetConVar("arc9_center_firemode"):SetInt(0)
        GetConVar("arc9_center_overheat"):SetInt(0)

        -- april fools debugging was fun
        GetConVar("arc9_cruelty_reload"):SetInt(0)
    end
end