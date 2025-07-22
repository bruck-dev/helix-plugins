
local PLUGIN = PLUGIN

-- ATTACHMENTS
do
    function PLUGIN:TFA_PreCanAttach(weapon, attID)
        if ix.config.Get("useWeaponBenches(Tfa)", true) and !hook.Run("NearWeaponBench", weapon:GetOwner()) then
            return false
        end
    end

    function PLUGIN:TFA_CanAttach(weapon, attID)
        local client = weapon:GetOwner()
        local item = client:GetCharacter():TFA_HasAttachment(attID)
        
        if !item then
            return false
        end
        
        if !isbool(item) and !item:HasTool(client) then
            local tool = ix.item.Get(item.tool)
            if tool then
                client:Notify("You do not have the " .. tool:GetName() .. " tool needed to add this attachment!")
                return false
            else
                client:Notify("You do not have the " .. item.tool .. " tool needed to add this attachment!")
                return false
            end
        end
    end

    function PLUGIN:TFA_Attachment_Attached(weapon, attID, attTable, category, index, forced)
        local item = weapon.ixItem
        if item then
            item:AddAttachment(attID)
        end

        local char = weapon:GetOwner() and weapon:GetOwner():GetCharacter()
        if !forced and char then
            char:TFA_TakeAttachment(attID)
        end
    end

    function PLUGIN:TFA_PreCanDetach(weapon, attID)
        if ix.config.Get("useWeaponBenches(Tfa)", true) and !hook.Run("NearWeaponBench", weapon:GetOwner()) then
            return false
        end
    end

    function PLUGIN:TFA_CanDetach(weapon, attID)
        local client = weapon:GetOwner()
        local itemID = ix.tfa.GetItemForAttachment(attID)
        
        if itemID then
            local item = ix.item.Get(itemID)
            
            if item and !item:HasTool(client) then
                local tool = ix.item.Get(item.tool)
                if tool then
                    client:Notify("You do not have the " .. tool:GetName() .. " tool needed to remove this attachment!")
                    return false
                else
                    client:Notify("You do not have the " .. item.tool .. " tool needed to remove this attachment!")
                    return false
                end
            end
        end
    end

    function PLUGIN:TFA_Attachment_Detached(weapon, attID, attTable, category, index, forced)
        local item = weapon.ixItem
        if item then
            item:RemoveAttachment(attID)
        end

        local char = weapon:GetOwner() and weapon:GetOwner():GetCharacter()
        if !forced and char then
            char:TFA_GiveAttachment(attID)
        end
    end
end

function PLUGIN:TFA_OnRemove(weapon)
    if ix.tfa.grenades[weapon:GetClass()] then
        local client = weapon.removeOwner or weapon:GetOwner()
        if IsValid(client) and weapon.IsGrenade or (client:GetAmmoCount(weapon:GetPrimaryAmmoType()) < 1 and weapon:Clip1() < 1 and weapon.ixItem and weapon.ixItem.Unequip) then
            weapon.ixItem:Unequip(client, false, true)
        end
    end
end

-- PLUGIN UTILITY
do
    function PLUGIN:SaveData()
        local data = {}

        for _, entity in ipairs(ents.FindByClass("ix_tfa_weapon_bench")) do
            local bodygroups = {}

            for _, v in ipairs(entity:GetBodyGroups() or {}) do
                bodygroups[v.id] = entity:GetBodygroup(v.id)
            end

            data[#data + 1] = {
                pos = entity:GetPos(),
                angles = entity:GetAngles(),
                model = entity:GetModel(),
                skin = entity:GetSkin(),
                bodygroups = bodygroups,
            }
        end

        self:SetData(data)
    end

    function PLUGIN:LoadData()
        for _, v in ipairs(self:GetData() or {}) do
            local entity = ents.Create("ix_tfa_weapon_bench")
            entity:SetPos(v.pos)
            entity:SetAngles(v.angles)
            entity:Spawn()

            entity:SetModel(v.model)
            entity:SetSkin(v.skin or 0)

            for id, bodygroup in pairs(v.bodygroups or {}) do
                entity:SetBodygroup(id, bodygroup)
            end

            entity:SetSolid(SOLID_VPHYSICS)
            entity:PhysicsInit(SOLID_VPHYSICS)

            local physObj = entity:GetPhysicsObject()
            if (IsValid(physObj)) then
                physObj:EnableMotion(false)
                physObj:Sleep()
            end
        end
    end

    -- hacky fix to prevent PostPlayerLoadout from being called an extra time incorrectly, prevents att duping from preset application
    function PLUGIN:PostPlayerLoadout(client)
        local character = client:GetCharacter()

        if character and character:GetInventory() and client.loadoutPredictedTFA then
            for k, _ in character:GetInventory():Iter() do
                if k.isTFAWeapon and k:GetData("equip", false) then
                    k:Call("OnPostLoadout", client)
                end
            end
            client.loadoutPredictedTFA = nil
        end

        client.loadoutPredictedTFA = true
    end
end