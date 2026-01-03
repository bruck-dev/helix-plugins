
local PLUGIN = PLUGIN

ix.config.Add("generateAttachmentItems(MWB)", false, "Whether or not MWB attachments will have items created automatically. This can take a while with a lot of packs.", function(oldValue, newValue)
    if newValue and !ix.mwb.attachmentsGenerated then
        ix.mwb.GenerateAttachments()
        RunConsoleCommand("spawnmenu_reload") -- in case any item spawnmenu tabs are installed
    end
end,{category = "MW Base"}
)

ix.config.Add("generateWeaponItems(MWB)", false, "Whether or not MWB weapons will have items created automatically. This can take a while with a lot of packs.", function(oldValue, newValue)
    if newValue and !ix.mwb.weaponsGenerated then
        ix.mwb.GenerateWeapons()
        RunConsoleCommand("spawnmenu_reload")
    end
end, {category = "MW Base"}
)

ix.config.Add("freeAttachments(MWB)", false, "Whether or not the MWB attachments are free to use, and do not require inventory items.", nil, {category = "MW Base"})

ix.config.Add("useWeaponBenches(MWB)", true, "Whether or not players must use an MWB Support Weapon Bench to customize their weapons.", nil, {category = "MW Base"})

if CLIENT then
    ix.option.Add("mwbShowWeaponBenchTooltip", ix.type.bool, false, {
        category = "MW Base",
    })
end