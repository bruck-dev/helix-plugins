
local PLUGIN = PLUGIN

ix.config.Add("enableCustomization(Tfa)", true, "Whether or not attachments can be added to TFA weapons.", function(oldValue, newValue)
    if SERVER then
        GetConVar("sv_tfa_attachments_enabled"):SetBool(newValue)
    end
end,{category = "TFA"}
)
ix.config.Add("freeAttachments(Tfa)", false, "Whether or not the TFA attachments are free to use, and do not require inventory items.", nil, {category = "TFA"})
ix.config.Add("useWeaponBenches(Tfa)", true, "Whether or not players must use an TFA Support Weapon Bench to customize their weapons.", nil, {category = "TFA"})

ix.config.Add("enableBulletPenetration(Tfa)", true, "Whether or not TFA bullets can pierce world brushes and other objects.", function(oldValue, newValue)
    if SERVER then
        GetConVar("sv_tfa_bullet_penetration"):SetBool(newValue)
    end
end,{category = "TFA"}
)

ix.config.Add("enableRicochets(Tfa)", false, "Whether or not TFA bullets can ricochet off of hard surfaces and potentially hit entities in the area.", function(oldValue, newValue)
    if SERVER then
        GetConVar("sv_tfa_bullet_ricochet"):SetBool(newValue)
    end
end,{category = "TFA"}
)

ix.config.Add("enableDoorDestruction(Tfa)", false, "Whether or not TFA bullets can break down doors.", function(oldValue, newValue)
    if SERVER then
        GetConVar("sv_tfa_bullet_doordestruction"):SetBool(newValue)
    end
end,{category = "TFA"}
)

ix.config.Add("enableWeaponHud(Tfa)", false, "Whether or not the TFA HUD should be drawn near weapons.", nil, {category = "TFA"})
ix.config.Add("enableCrosshair(Tfa)", false, "Whether or not the TFA Crosshair should be used.", nil, {category = "TFA"})

ix.config.Add("generateAttachmentItems(Tfa)", false, "Whether or not TFA attachments will have items created automatically. This can take a while with a lot of packs.", function(oldValue, newValue)
    if newValue and !ix.tfa.attachmentsGenerated then
        ix.tfa.GenerateAttachments()
        RunConsoleCommand("spawnmenu_reload") -- in case any item spawnmenu tabs are installed
    end
end,{category = "TFA"}
)

ix.config.Add("generateWeaponItems(Tfa)", false, "Whether or not TFA weapons will have items created automatically. This can take a while with a lot of packs.", function(oldValue, newValue)
    if newValue and !ix.tfa.weaponsGenerated then
        ix.tfa.GenerateWeapons()
        RunConsoleCommand("spawnmenu_reload")
    end
end,{category = "TFA"}
)

if CLIENT then
    ix.option.Add("tfaShowWeaponBenchTooltip", ix.type.bool, false, {
        category = "TFA",
    })
end