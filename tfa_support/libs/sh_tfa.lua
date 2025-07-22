
local PLUGIN = PLUGIN

ix.tfa = {}
ix.tfa.attachments = {}
ix.tfa.grenades = {}
ix.tfa.freeAttachments = {}

if SERVER then
    -- set up a weapon's attachments on equip, based on it's default value or data
    function ix.tfa.InitWeapon(client, weapon, item)
        if !IsValid(client) or !IsValid(weapon) or !item then return end

        local atts = item:GetAttachments()
        for k, _ in pairs(atts) do
            weapon:Attach(k, true)
        end

        if item.isGrenade then
            weapon:SetClip1(1)
        else
            weapon:SetClip1(item:GetData("ammo", 0))
        end
    end
end

-- generates attachment items automatically
function ix.tfa.GenerateAttachments()
    if ix.tfa.attachmentsGenerated then return end

    for attID, attTable in pairs(TFA.Attachments.Atts) do
        if !ix.tfa.IsFreeAttachment(attID) then
            if !ix.tfa.attachments[attID] then
                local ITEM = ix.item.Register(attID, "base_tfa_attachments", false, nil, true)
                ITEM.name = attTable.Name
                ITEM.description = "An attachment, used to modify weapons."
                ITEM.att = attID
                ITEM.isGenerated = true

                ix.tfa.attachments[ITEM.att] = attID
            end
        end
    end

    ix.tfa.attachmentsGenerated = true
end

-- generates weapon items automatically
function ix.tfa.GenerateWeapons()
    if ix.tfa.weaponsGenerated then return end

    for _, v in ipairs(weapons.GetList()) do
        if v.PrintName and (v.Base and string.find(v.Base, "tfa_") and !string.find(v.ClassName, "base")) then
            local ITEM = ix.item.Register(v.ClassName, "base_tfa_weapons", false, nil, true)
            ITEM.name = v.PrintName
            ITEM.description = v.Description or nil
            ITEM.model = v.WorldModel
            ITEM.class = v.ClassName
            ITEM.isGenerated = true

            local class
            if v.Type then
                class = v.Type:lower():gsub("%s+", "") -- remove spaces and lowercase the whole thing
            end

            if v.IsGrenade or (class and string.find(class, "grenade") and !string.find(class, "launch")) or (class and string.find(class, "throw")) then
                ITEM.weaponCategory = "Throwable"
                ITEM.width = 1
                ITEM.height = 1
                ITEM.isGrenade = true
                ix.tfa.grenades[v.ClassName] = true
            elseif (string.find(v.Base, "melee")) or (class and string.find(class, "melee")) then
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
                if class and string.find(class, "shotgun") then
                    ITEM.width = 3
                    ITEM.height = 2
                elseif class and (string.find(class, "sniper") or string.find(class, "marksman")) then
                    ITEM.width = 4
                    ITEM.height = 2
                elseif class and (string.find(class, "smg") or string.find(class, "sub")) then
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

    ix.tfa.weaponsGenerated = true
end

-- returns the item id for the passed attachment id
function ix.tfa.GetItemForAttachment(att)
    return ix.tfa.attachments[att]
end

function ix.tfa.IsFreeAttachment(att)
    return ix.tfa.freeAttachments[att]
end

function ix.tfa.MakeFreeAttachment(att)
    ix.tfa.freeAttachments[att] = true
end