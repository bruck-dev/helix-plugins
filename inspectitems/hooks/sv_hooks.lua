
local PLUGIN = PLUGIN

-- prevent pickup of inspected items and entities
do
    function PLUGIN:CanPlayerTakeItem(client, item)
        if isentity(item) and IsValid(item) and item:GetNWBool("IsInspected", false) and item.InspectingPlayer != client then
            return false
        end
    end

    function PLUGIN:PlayerCanPickupItem(ply, ent)
        if ent.InspectingPlayer and IsValid(ent.InspectingPlayer) and ent.InspectingPlayer != ply then
            return false
        end
    end
end

-- hooks to reset player/item state when a player should be invalidated or the item/ent is removed
do
    function PLUGIN:EntityRemoved(ent, fullUpdate)
        if ent:GetNWBool("IsInspected", false) then
            ix.inspect.ReleaseEntity(ent.InspectingPlayer, ent)
        end
    end
    function PLUGIN:PlayerDeath(ply)
        if ply.IsInspecting then
            if ply.InspectedEnt then
                ix.inspect.ReleaseEntity(ply, ply.InspectedEnt)
            elseif ply.InspectedItem then
                ix.inspect.ReleaseItem(ply, ply.InspectedItem)
            end
        end
    end
    function PLUGIN:PlayerSilentDeath(ply)
        if ply.IsInspecting then
            if ply.InspectedEnt then
                ix.inspect.ReleaseEntity(ply, ply.InspectedEnt)
            elseif ply.InspectedItem then
                ix.inspect.ReleaseItem(ply, ply.InspectedItem)
            end
        end
    end
    function PLUGIN:PlayerDisconnected(ply)
        if ply.IsInspecting then
            if ply.InspectedEnt then
                ix.inspect.ReleaseEntity(ply, ply.InspectedEnt)
            elseif ply.InspectedItem then
                ix.inspect.ReleaseItem(ply, ply.InspectedItem)
            end
        end
    end
    function PLUGIN:PlayerLoadedCharacter(ply, char, prevChar)
        if ply.IsInspecting then
            if ply.InspectedEnt then
                ix.inspect.ReleaseEntity(ply, ply.InspectedEnt)
            elseif ply.InspectedItem then
                ix.inspect.ReleaseItem(ply, ply.InspectedItem)
            end
        end
    end
    function PLUGIN:InventoryItemRemoved(oldInv, item)
        if item.InspectingPlayer then
            ix.inspect.ReleaseItem(item.InspectingPlayer, item)
        end
    end
end

-- prevent physgun movement of inspected entities
do
    function PLUGIN:GravGunPickupAllowed(ply, ent)
        if IsValid(ent) and ent:GetNWBool("IsInspected", false) then return false end
    end
    function PLUGIN:PhysgunPickup(ply, ent)
        if IsValid(ent) and ent:GetNWBool("IsInspected", false) then return false end
    end
end

-- plugin data
do
    function PLUGIN:SaveData()
        local data = {}

        for _, entity in ipairs(ents.FindByClass("ix_inspectable")) do
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
                displayName = entity:GetDisplayName() or "Inspectable",
            }
        end

        self:SetData(data)
    end

    function PLUGIN:LoadData()
        for _, v in ipairs(self:GetData() or {}) do
            local entity = ents.Create("ix_inspectable")
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

            entity:SetDisplayName(v.displayName or "Inspectable")
        end
    end
end