
local PLUGIN = PLUGIN

do
    util.AddNetworkString("ixLiqSourceEdit")
    util.AddNetworkString("ixLiqSourceEditFinish")
    util.AddNetworkString("ixLiqSourceEditor")

    function PLUGIN:PlayerSpawnedProp(client, model, entity)

        if entity and ix.config.Get("allowSourceSpawning", true) then
            model = tostring(model):lower()
            local data = ix.liquids.sources[model]

            if (data) then
                if (hook.Run("CanPlayerSpawnContainer", client, model, entity) == false) then return end

                local container = ents.Create("ix_liquidsource")
                container:SetPos(entity:GetPos())
                container:SetAngles(entity:GetAngles())
                container:SetModel(model)
                container:SetStoredModel(model)

                container:SetDisplayName(data.name or "Liquid Source")
                container:SetIsInfinite(data.infinite or false)
                container:SetShouldShowTooltip(data.showTooltip or true)
                container:SetMaxVolume(data.maxVolume or 1000)
                container:SetCurVolume(data.startingVolume or 1000)

                if data.liquid then
                    if ix.liquids.Get(data.liquid:lower()) then
                        container:SetLiquid(data.liquid:lower())
                    else
                        local liquidTable = ix.liquids.FindByName(data.liquid)
                        if liquidTable and liquidTable.uniqueID then
                            container:SetLiquid(liquidTable.uniqueID)
                        end
                    end
                end

                container:Spawn()
                entity:Remove()
            end
        end
    end

    function PLUGIN:SaveData()
        local data = {}

        for _, entity in ipairs(ents.FindByClass("ix_liquidsource")) do
            local bodygroups = {}

            for _, v in ipairs(entity:GetBodyGroups() or {}) do
                bodygroups[v.id] = entity:GetBodygroup(v.id)
            end

            data[#data + 1] = {
                name = entity:GetDisplayName(),
                pos = entity:GetPos(),
                angles = entity:GetAngles(),
                model = entity:GetModel(),
                skin = entity:GetSkin(),
                bodygroups = bodygroups,
                liquid = entity:GetLiquid(),
                maxVol = entity:GetMaxVolume(),
                curVol = entity:GetCurVolume(),
                isInfinite = entity:GetIsInfinite(),
                showTooltip = entity:GetShouldShowTooltip(),
            }
        end
        self:SetData(data)
    end

    function PLUGIN:LoadData()
        for _, v in ipairs(self:GetData() or {}) do
            local entity = ents.Create("ix_liquidsource")
            entity:SetPos(v.pos)
            entity:SetAngles(v.angles)
            entity:Spawn()

            entity:SetModel(v.model)
            entity:SetStoredModel(v.model)
            entity:SetSkin(v.skin or 0)
            entity:SetSolid(SOLID_VPHYSICS)
            entity:PhysicsInit(SOLID_VPHYSICS)

            local physObj = entity:GetPhysicsObject()

            if (IsValid(physObj)) then
                physObj:EnableMotion(false)
                physObj:Sleep()
            end

            entity:SetDisplayName(v.name)
            entity:SetColor(v.color)
            entity:SetLiquid(v.liquid)
            entity:SetMaxVolume(v.maxVol)
            entity:SetCurVolume(v.curVol)
            entity:SetIsInfinite(v.isInfinite)
            entity:SetShouldShowTooltip(v.showTooltip)
        end
    end

    local function UpdateEditReceivers(receivers, key, value)
        net.Start("ixLiqSourceEdit")
            net.WriteString(key)
            net.WriteType(value)
        net.Send(receivers)
    end

    net.Receive("ixLiqSourceEdit", function(length, client)
        if (!CAMI.PlayerHasAccess(client, "Helix - Manage Liquid Sources", nil)) then
            return
        end

        local entity = client.ixLiqSource

        if (!IsValid(entity)) then
            return
        end

        local key = net.ReadString()
        local data = net.ReadType()
        local feedback = true

        if (key == "name") then
            entity:SetDisplayName(data)
        elseif (key == "model") then
            entity:SetModel(data)
            entity:SetStoredModel(data)
            entity:SetSolid(SOLID_VPHYSICS)
            entity:PhysicsInit(SOLID_VPHYSICS)
            entity:SetAnim()
        elseif (key == "liquid") then
            entity:SetLiquid(data)
        elseif (key == "maxvolume") then
            entity:SetMaxVolume(data)
        elseif (key == "curvolume") then
            entity:SetCurVolume(data)
        elseif (key == "infinite") then
            entity:SetIsInfinite(data)
        elseif (key == "tooltip") then
            entity:SetShouldShowTooltip(data)
        end

        PLUGIN:SaveData()

        if (feedback) then
            local receivers = {}

            for _, v in ipairs(entity.receivers) do
                if (CAMI.PlayerHasAccess(v, "Helix - Manage Liquid Sources", nil)) then
                    receivers[#receivers + 1] = v
                end
            end

            net.Start("ixLiqSourceEditFinish")
                net.WriteString(key)
                net.WriteType(data)
            net.Send(receivers)
        end
    end)
end
