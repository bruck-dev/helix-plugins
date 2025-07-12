
local PLUGIN = PLUGIN

ix.config.Add("generateAttachmentItems(ArcCW)", false, "Whether or not ArcCW attachments will have items created automatically. This can take a while with a lot of packs.", function(oldValue, newValue)
    if newValue and !ix.arccw.attachmentsGenerated then
        ix.arccw.GenerateAttachments()
        RunConsoleCommand("spawnmenu_reload") -- in case any item spawnmenu tabs are installed
    end
end,{category = "ArcCW"}
)

ix.config.Add("generateWeaponItems(ArcCW)", false, "Whether or not ArcCW weapons will have items created automatically. This can take a while with a lot of packs.", function(oldValue, newValue)
    if newValue and !ix.arccw.weaponsGenerated then
        ix.arccw.GenerateWeapons()
        RunConsoleCommand("spawnmenu_reload")
    end
end,{category = "ArcCW"}
)

ix.config.Add("freeAttachments(ArcCW)", false, "Whether or not the ArcCW attachments are free to use, and do not require inventory items.", function(oldValue, newValue)
    if SERVER then
        GetConVar("arccw_attinv_free"):SetBool(newValue)
    end
end, {category = "ArcCW"}
)

ix.config.Add("enableBulletPenetration(ArcCW)", true, "Whether or not ArcCW bullets can pierce world brushes and other objects.", function(oldValue, newValue)
    if SERVER then
        GetConVar("arccw_enable_penetration"):SetBool(newValue)
    end
end, {category = "ArcCW"}
)

ix.config.Add("enableRicochets(ArcCW)", true, "Whether or not ArcCW bullets can ricochet off of hard surfaces and potentially hit entities in the area.", function(oldValue, newValue)
    if SERVER then
        GetConVar("arccw_enable_ricochet"):SetBool(newValue)
    end
end, {category = "ArcCW"}
)

ix.config.Add("enableBulletDrop(ArcCW)", true, "Whether or not ArcCW bullets are subject to physics, such as travel time and bullet drop.", function(oldValue, newValue)
    if SERVER then
        GetConVar("arccw_enable_dropping"):SetBool(newValue)
    end
end, {category = "ArcCW"}
)

ix.config.Add("useWeaponBenches(ArcCW)", true, "Whether or not players must use an ArcCW Support Weapon Bench to customize their weapons.", nil, {category = "ArcCW"})

if CLIENT then
    ix.option.Add("arccwShowWeaponBenchTooltip", ix.type.bool, false, {
        category = "ArcCW",
    })
end