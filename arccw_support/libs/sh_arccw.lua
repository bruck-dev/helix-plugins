
local PLUGIN = PLUGIN

ix.arccw = {}
ix.arccw.attachments = {}
ix.arccw.grenades = {}
ix.arccw.freeAttachments = {}

if SERVER then
    -- set up a weapon's attachments on equip, based on it's default value or data
    function ix.arccw.InitWeapon(client, weapon, item)
        if !IsValid(client) or !IsValid(weapon) or !item then return end

        for slot, _ in ipairs(weapon.Attachments) do
            weapon.Attachments[slot].Installed = nil
        end

        if IsValid(weapon) then
            for k, v in pairs(weapon.Attachments) do
                weapon:Detach(k, true, true, true)
            end

            weapon.Attachments.BaseClass = nil
            for slot, att in SortedPairs(item:GetAttachments()) do
                local atttbl = ArcCW.AttachmentTable[att]
                if !atttbl then continue end

                weapon:Attach(slot, att, true, true, true)
            end

            weapon:AdjustAtts()
            weapon:RefreshBGs()

            weapon:NetworkWeapon()
            weapon:SetupModel(false)
            weapon:SetupModel(true)

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
function ix.arccw.GenerateAttachments()
    if ix.arccw.attachmentsGenerated then return end

    for attID, attTable in pairs(ArcCW.AttachmentTable) do
        if !ix.arccw.IsFreeAttachment(attID) and !attTable.AdminOnly and !ArcCW.AttachmentBlacklistTable[attID] then
            if !ix.arccw.attachments[attID] and !(attTable.InvAtt and ix.arccw.attachments[attTable.InvAtt]) then
                local ITEM = ix.item.Register(attID, "base_arccw_attachments", false, nil, true)
                ITEM.name = attTable.PrintName
                ITEM.description = attTable.Description or "An attachment, used to modify weapons."
                ITEM.isGenerated = true

                ITEM.model = attTable.Model or "models/props_junk/cardboard_box004a.mdl"
                
                if attTable.InvAtt then
                    ITEM.att = attTable.InvAtt
                else
                    ITEM.att = attID
                end

                ix.arccw.attachments[ITEM.att] = attID
            end
        end
    end

    ix.arccw.attachmentsGenerated = true
end

-- generates weapon items automatically
function ix.arccw.GenerateWeapons()
    if ix.arccw.weaponsGenerated then return end

    for _, v in ipairs(weapons.GetList()) do
        if v.PrintName and weapons.IsBasedOn(v.ClassName, "arccw_base") then
            local ITEM = ix.item.Register(v.ClassName, "base_arccw_weapons", false, nil, true)
            ITEM.name = v.PrintName
            ITEM.description = v.Trivia_Desc or "Undefined description. Recommend creating your own item."
            ITEM.class = v.ClassName
            ITEM.model = v.WorldModel
            ITEM.isGenerated = true

            local class
            if v.Trivia_Class then
                class = v.Trivia_Class:lower():gsub("%s+", "") -- remove spaces and lowercase the whole thing
            end

            if v.Throwing or v.Primary.Ammo == "grenade" or (class and string.find(class, "grenade") and !string.find(class, "launch")) then
                ITEM.weaponCategory = "Throwable"
                ITEM.width = 1
                ITEM.height = 1
                ITEM.isGrenade = true

                ix.arccw.grenades[v.ClassName] = true
            elseif (v.NotAWeapon) then
                ITEM.width = 1
                ITEM.height = 1
            elseif v.PrimaryBash or (class and string.find(class, "melee")) then
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
                if v.IsShotgun or (class and string.find(class, "shotgun")) then
                    ITEM.width = 3
                    ITEM.height = 2
                elseif class and (string.find(class, "sniper") or string.find(class, "marksman")) then
                    ITEM.width = 4
                    ITEM.height = 2
                elseif class and (string.find(class, "smg") or string.find(class, "submachine")) then
                    ITEM.width = 3
                    ITEM.height = 2
                elseif class and (string.find(class, "lmg") or string.find(class, "machinegun") or string.find(class, "hmg")) then
                    ITEM.width = 4
                    ITEM.height = 2
                else
                    ITEM.width = 3
                    ITEM.height = 2
                end
            end
        end
    end

    ix.arccw.weaponsGenerated = true
end

-- returns the item id for the passed attachment id
function ix.arccw.GetItemForAttachment(att)
    return ix.arccw.attachments[att]
end

function ix.arccw.IsFreeAttachment(att)
    local atttbl = ArcCW.AttachmentTable[att]
    return ix.arccw.freeAttachments[att] or (atttbl and atttbl.Free)
end

function ix.arccw.MakeFreeAttachment(att)
    ix.arccw.freeAttachments[att] = true
end