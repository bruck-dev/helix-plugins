
local PLUGIN = PLUGIN

ix.mwb = {}
ix.mwb.attachments = {}
ix.mwb.grenades = {}
ix.mwb.freeAttachments = {}

if SERVER then
    -- set up a weapon's attachments on equip, based on it's default value or data
    function ix.mwb.InitWeapon(client, weapon, item)
        if !IsValid(client) or !IsValid(weapon) or !item then return end

        if IsValid(weapon) then
            for slot, att in SortedPairs(item:GetAttachments()) do
                local index = ix.mwb.GetAttachmentIndex(weapon, att, slot) or 1
                if index then
                    weapon:Attach(slot, index, true)

                    -- make sure the client knows its there, too
                    timer.Simple(0.1, function()
                        if IsValid(weapon) then
                            net.Start("ixMWBNetworkAttachment")
                                net.WriteEntity(weapon)
                                net.WriteUInt(slot, 8)
                                net.WriteUInt(index, 8)
                            net.Send(client)
                        end
                    end)
                end
            end

            timer.Simple(0.1, function()
                if item.isGrenade then
                    weapon:SetClip1(1)
                else
                    weapon:SetClip1(item:GetData("ammo", 0))
                end
            end)
        end
    end
end

-- generates attachment items automatically
function ix.mwb.GenerateAttachments()
    if ix.mwb.attachmentsGenerated then return end

    for attID, attTable in pairs(MW_ATTS) do
        if !ix.mwb.IsFreeAttachment(attID) then
            if !ix.mwb.attachments[attID] then
                local ITEM = ix.item.Register(attID, "base_mwb_attachments", false, nil, true)
                ITEM.name = attTable.Name
                ITEM.att = attID
                ITEM.description = attTable.Description or "An attachment, used to modify weapons."
                ITEM.isGenerated = true

                ITEM.model = attTable.Model or "models/props_junk/cardboard_box004a.mdl"

                ix.mwb.attachments[attID] = attID
            end
        end
    end

    ix.mwb.attachmentsGenerated = true
end

-- generates weapon items automatically
function ix.mwb.GenerateWeapons()
    if ix.mwb.weaponsGenerated then return end

    for _, v in ipairs(weapons.GetList()) do
        if v.PrintName and weapons.IsBasedOn(v.ClassName, "mg_base") and !string.find(v.ClassName, "base") then
            local ITEM = ix.item.Register(v.ClassName, "base_mwb_weapons", false, nil, true)
            ITEM.name = v.PrintName
            ITEM.description = v.Description or nil
            ITEM.class = v.ClassName
            ITEM.model = v.WorldModel
            ITEM.isGenerated = true

            local class
            if v.SubCategory then
                class = v.SubCategory:lower():gsub("%s+", "") -- remove spaces and lowercase the whole thing
            end

            if v.Primary.Ammo == "grenade" or (class and string.find(class, "grenade") and !string.find(class, "launch")) then
                ITEM.weaponCategory = "Throwable"
                ITEM.width = 1
                ITEM.height = 1
                ITEM.isGrenade = true

                ix.mwb.grenades[v.ClassName] = true
            elseif (class and string.find(class, "melee")) then
                ITEM.weaponCategory = "Melee"
                ITEM.width = 1
                ITEM.height = 2
            elseif (class and (string.find(class, "pistol") or string.find(class, "revolver"))) then
                ITEM.weaponCategory = "Secondary"
                ITEM.width = 2
                ITEM.height = 2
            else
                ITEM.weaponCategory = "Primary"
                ITEM.width = 3
                ITEM.height = 2

                -- this is largely cosmetic but i think it helps
                if class then
                    if string.find(class, "shotgun") then
                        ITEM.width = 3
                        ITEM.height = 2
                    elseif (string.find(class, "sniper") or string.find(class, "marksman")) then
                        ITEM.width = 4
                        ITEM.height = 2
                    elseif (string.find(class, "smg") or string.find(class, "submachine")) then
                        ITEM.width = 3
                        ITEM.height = 2
                    elseif (string.find(class, "lmg") or string.find(class, "machinegun") or string.find(class, "hmg")) then
                        ITEM.width = 4
                        ITEM.height = 2
                    end
                end
            end
        end
    end

    ix.mwb.weaponsGenerated = true
end

-- returns the item id for the passed attachment id
function ix.mwb.GetItemForAttachment(att)
    return ix.mwb.attachments[att]
end

function ix.mwb.IsFreeAttachment(att)
    return ix.mwb.freeAttachments[att]
end

function ix.mwb.MakeFreeAttachment(att)
    ix.mwb.freeAttachments[att] = true
end

function ix.mwb.GetAttachmentIndex(weapon, att, slot)
    if slot then
        for index, id in ipairs(weapon.Customization[slot]) do
            if id == att then
                return index
            end
        end
    else
        for slot, opts in ipairs(weapon.Customization) do
            for index, id in ipairs(opts) do
                if id == att then
                    return index
                end
            end
        end
    end
end