
local PLUGIN = PLUGIN

ix.arc9 = {}
ix.arc9.attachments = {}
ix.arc9.grenades = {}

if SERVER then
    -- set up a weapon's attachments on equip, based on it's default value or data
    function ix.arc9.InitWeapon(client, weapon, item)
        if !IsValid(client) or !IsValid(weapon) or !item then return end

        ix.arc9.SendPreset(client, weapon, item:GetPreset(), true)
    end

    -- replacement for ARC9.SendPreset()
    function ix.arc9.SendPreset(client, weapon, preset, setAmmo)
        if !IsValid(client) or !client:IsPlayer() or !IsValid(weapon) then
            return
        end

        if !isstring(preset) then -- no preset found, so we just need to set the ammo
            if weapon.ixItem.isGrenade then
                weapon:SetClip1(1)
            else
                weapon:SetClip1(weapon.ixItem:GetData("ammo", 0))
            end

            return
        end

        if !ix.config.Get("freeAttachments", false) or !GetConVar("arc9_free_atts"):GetBool() then
            local atts = ARC9.GetAttsFromPreset("[ix]"..preset) -- expects a preset name to be trimmed, so just give it a fake one
            if !atts then return end

            ix.arc9.GiveAttsFromList(client, atts)
        end

        if IsValid(weapon) then
            -- clear all original attachments so they dont get added as items/AttInv entries when we apply the preset
            weapon.Attachments = baseclass.Get(weapon:GetClass()).Attachments
            for slot, slottbl in ipairs(weapon.Attachments) do
                slottbl.Installed = nil
                slottbl.SubAttachments = nil
            end

            weapon:SetNoPresets(true)

            -- on proper servers, we need to wait until the weapon is valid on the client. this is also how its done in the base, surprisingly. i kinda hate it
            timer.Simple(0.1, function()
                net.Start("ixARC9SendPreset")
                    net.WriteEntity(weapon)
                    net.WriteString(preset)
                net.Send(client)

                weapon:PostModify()

                if setAmmo then
                    if weapon.ixItem.isGrenade then
                        weapon:SetClip1(1)
                    else
                        weapon:SetClip1(weapon.ixItem:GetData("ammo", 0))
                    end
                end
            end)
        end
    end

    -- replacement for ARC9.GiveAttsFromList() that will never give the player items, only add to their AttInv
    function ix.arc9.GiveAttsFromList(client, tbl)
        local take = false

        for i, k in pairs(tbl) do
            ARC9:PlayerGiveAtt(client, k, 1, true)
            take = true
        end

        if take then ARC9:PlayerSendAttInv(client) end
    end
end

-- generates attachment items automatically
function ix.arc9.GenerateAttachments()
    if ix.arc9.attachmentsGenerated then return end

    for attID, attTable in pairs(ARC9.Attachments) do
        if !attTable.Free and !attTable.AdminOnly and !ARC9.Blacklist[attID] then
            if !attTable.Free and !attTable.AdminOnly and !ARC9.Blacklist[attID] and !(PLUGIN.freeAttachments and PLUGIN.freeAttachments[attID]) then
                local ITEM = ix.item.Register(attID, "base_arc9_attachments", false, nil, true)
                ITEM.name = attTable.PrintName
                ITEM.description = attTable.Description or "An attachment, used to modify weapons."
                ITEM.isGenerated = true

                if attTable.DropMagazineModel then
                    ITEM.model = attTable.DropMagazineModel
                else
                    ITEM.model = "models/items/arc9/att_cardboard_box.mdl"
                end
                
                if attTable.InvAtt then
                    ITEM.att = attTable.InvAtt
                else
                    ITEM.att = attID
                end

                ix.arc9.attachments[ITEM.att] = attID
            end
        end
    end

    ix.arc9.attachmentsGenerated = true
end

-- generates weapon items automatically
function ix.arc9.GenerateWeapons()
    if ix.arc9.weaponsGenerated then return end

    for _, v in ipairs(weapons.GetList()) do
        if weapons.IsBasedOn(v.ClassName, "arc9_base") then
            local ITEM = ix.item.Register(v.ClassName, "base_arc9_weapons", false, nil, true)
            ITEM.name = v.PrintName
            ITEM.description = v.Description or nil
            ITEM.class = v.ClassName
            ITEM.isGenerated = true

            local class
            if v.Class then
                class = v.Class:lower():gsub("%s+", "")
            end

            -- i tried my best to update these for consistency, but most of ARC9's definitions are arbitrary. this WILL produce bad results somewhere.
            if v.Throwable or (class and string.find(class, "grenade") and !string.find(class, "launch")) then
                ITEM.weaponCategory = "Throwable"
                ITEM.width = 1
                ITEM.height = 1
                ITEM.isGrenade = true
                ITEM.model = v.WorldModel or "models/weapons/w_eq_fraggrenade.mdl"

                ix.arc9.grenades[v.ClassName] = true
            elseif (v.NotAWeapon) then
                ITEM.width = 1
                ITEM.height = 1
                ITEM.model = v.WorldModel or "models/weapons/w_defuser.mdl"
            elseif v.PrimaryBash or v.HoldType == "melee" or v.HoldType == "melee2" or v.HoldType == "knife" or v.HoldType == "fist" or (class and string.find(class, "melee")) then
                ITEM.weaponCategory = "Melee"
                ITEM.width = 1
                ITEM.height = 2
                ITEM.model = v.WorldModel or "models/weapons/w_knife_ct.mdl"
            elseif v.HoldType == "pistol" or v.HoldType == "revolver" or (class and (string.find(class, "pistol") or string.find(class, "revolver"))) then
                ITEM.weaponCategory = "Secondary"
                ITEM.width = 2
                ITEM.height = 2
                if class and string.find(class, "revolver") then
                    ITEM.model = v.WorldModel or "models/weapons/w_357.mdl"
                else
                    ITEM.model = v.WorldModel or "models/weapons/w_pist_elite_single.mdl"
                end
            else
                ITEM.weaponCategory = "Primary"
                ITEM.model = v.WorldModel or "models/weapons/w_rif_m4a1.mdl" -- most weapons use an invisible css world model with bonemerged attachments, so this probably wont look right
                ITEM.width = 3
                ITEM.height = 2

                -- this is largely cosmetic but i think it helps
                if class then
                    if string.find(class, "shotgun") then
                        ITEM.model = v.WorldModel or "models/weapons/w_shot_m3super90.mdl"
                        ITEM.width = 3
                        ITEM.height = 2
                    elseif string.find(class, "sniper") or string.find(class, "marksman") then
                        ITEM.model = v.WorldModel or "models/weapons/w_snip_scout.mdl"
                        ITEM.width = 4
                        ITEM.height = 2
                    elseif string.find(class, "smg") or string.find(class, "submachine") then
                        ITEM.model = v.WorldModel or "models/weapons/w_smg_ump45.mdl"
                        ITEM.width = 3
                        ITEM.height = 2
                    elseif string.find(class, "lmg") or string.find(class, "machinegun") or string.find(class, "hmg") then
                        ITEM.model = v.WorldModel or "models/weapons/w_mach_m249para.mdl"
                        ITEM.width = 4
                        ITEM.height = 2
                    end
                end
            end
        end
    end

    ix.arc9.weaponsGenerated = true
end

-- returns the item id for the passed attachment id
function ix.arc9.GetItemForAttachment(att)
    return ix.arc9.attachments[att]
end