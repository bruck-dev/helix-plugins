
local PLUGIN = PLUGIN

util.AddNetworkString("ixRadioStationJoin")
util.AddNetworkString("ixRadioStationLeave")

function PLUGIN:SaveData()
    local data = {}

    for _, entity in ipairs(ents.FindByClass("ix_radio_*")) do
        local class = entity:GetClass()
        local bodygroups = {}

        for _, v in ipairs(entity:GetBodyGroups() or {}) do
            bodygroups[v.id] = entity:GetBodygroup(v.id)
        end

        data[#data + 1] = {
            class = class,
            pos = entity:GetPos(),
            angles = entity:GetAngles(),
            model = entity:GetModel(),
            skin = entity:GetSkin(),
            bodygroups = bodygroups,

            freq = entity:GetFrequency(),
            enabled = entity:GetEnabled(),
        }
    end

    self:SetData(data)
end

function PLUGIN:LoadData()
    for _, v in ipairs(self:GetData() or {}) do
        local entity = ents.Create(v.class)
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

        if v.freq then
            entity:UpdateFrequency(v.freq)
        end

        if v.enabled then
            entity:SetEnabled(v.enabled)
        end
    end
end

function PLUGIN:CanAutoFormatMessage(client, chatType, message)
	return string.find(chatType, "radio")
end