
local PLUGIN = PLUGIN

-- personally i think autogeneration is inefficient and can create spotty results under the best of conditions
ix.config.Add("generateAttachmentItems(ARC9)", false, "Whether or not ARC9 attachments will have items created automatically. This can take a while with a lot of packs.", function(oldValue, newValue)
    if newValue and !ix.arc9.attachmentsGenerated then
        ix.arc9.GenerateAttachments()
        RunConsoleCommand("spawnmenu_reload") -- in case any item spawnmenu tabs are installed
    end
end,{category = "ARC9"}
)

ix.config.Add("generateWeaponItems(ARC9)", false, "Whether or not ARC9 weapons will have items created automatically. This can take a while with a lot of packs.", function(oldValue, newValue)
    if newValue and !ix.arc9.weaponsGenerated then
        ix.arc9.GenerateWeapons()
        RunConsoleCommand("spawnmenu_reload")
    end
end,{category = "ARC9"}
)

ix.config.Add("freeAttachments(ARC9)", false, "Whether or not the ARC9 attachments are free to use, and do not require inventory items.", function(oldValue, newValue)
    if SERVER then
        GetConVar("arc9_free_atts"):SetBool(newValue)
    end
end, {category = "ARC9"}
)

ix.config.Add("disableWeaponHud(ARC9)", true, "Whether or not the ARC9 ammo and weapon HUD should show for players with ARC9 weapons.", function(oldValue, newValue)
        if SERVER then
            GetConVar("arc9_hud_force_disable"):SetBool(newValue)
        end
    end, {category = "ARC9"}
)

ix.config.Add("useWeaponBenches(ARC9)", true, "Whether or not players must use an ARC9 Support Weapon Bench to customize their weapons.", nil, {category = "ARC9"})

ix.config.Add("enableBulletPenetration(ARC9)", true, "Whether or not ARC9 bullets can pierce world brushes and other objects.", function(oldValue, newValue)
    if SERVER then
        GetConVar("arc9_mod_penetration"):SetBool(newValue)
    end
end, {category = "ARC9"}
)

ix.config.Add("enableRicochets(ARC9)", true, "Whether or not ARC9 bullets can ricochet off of hard surfaces and potentially hit entities in the area.", function(oldValue, newValue)
    if SERVER then
        GetConVar("arc9_ricochet"):SetBool(newValue)
    end
end, {category = "ARC9"}
)

ix.config.Add("enablePhysicalBullets(ARC9)", true, "Whether or not ARC9 bullets are subject to physics, such as travel time and bullet drop.", function(oldValue, newValue)
    if SERVER then
        GetConVar("arc9_bullet_physics"):SetBool(newValue)
    end
end, {category = "ARC9"}
)

ix.config.Add("alwaysRaised(ARC9)", false, "Whether or not ARC9 weapons can be raised and lowered. ARC9 isn't design to use holstering, so if TPIK is on you may want to have this enabled.", function(oldValue, newValue)
    ix.arc9.SetAlwaysRaised()

    -- automatically raises any held ARC9 weapons if set to true
    if SERVER then
        if newValue then
            for _, v in player.Iterator() do
                local wep = v:GetActiveWeapon()
                
                if weapons.IsBasedOn(wep:GetClass(), "arc9_base") and !v:IsWepRaised() then
                    v:SetWepRaised(true, wep)
                end
            end
        end
    end

end, {category = "ARC9"}
)

if CLIENT then
    ix.option.Add("arc9ShowWeaponBenchTooltip", ix.type.bool, false, {
        category = "ARC9",
    })
end