
local PLUGIN = PLUGIN

function PLUGIN:SaveData()
    local data = {}

    for _, entity in ipairs(ents.FindByClass("ix_arccw_weapon_bench")) do
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
        local entity = ents.Create("ix_arccw_weapon_bench")
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
    local char = client:GetCharacter()

    if char and char:GetInventory() and client.loadoutPredictedArcCW and char.loadoutPredictedArcCW then
        for k, _ in char:GetInventory():Iter() do
            if k.isArcCWWeapon and k:GetData("equip", false) then
                k:Call("OnPostLoadout", client)
            end
        end
        client.loadoutPredictedArcCW = nil
        char.loadoutPredictedArcCW = nil
    end
end
function PLUGIN:PlayerLoadedCharacter(client, char, prevChar)
    client.loadoutPredictedArcCW = true
    char.loadoutPredictedArcCW = true

    client.ArcCW_AttInv = {}
end