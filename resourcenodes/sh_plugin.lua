
local PLUGIN = PLUGIN

PLUGIN.name = "Resource Nodes"
PLUGIN.author = "bruck"
PLUGIN.description = "Adds entities to produce crafting resources over time."
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


ix.util.Include("meta/sh_resourcenode.lua")
ix.util.Include("meta/sh_character.lua")
ix.util.Include("cl_hooks.lua", "client")


CAMI.RegisterPrivilege({
    Name = "Helix - Manage Resource Nodes",
    MinAccess = "admin"
})

function PLUGIN:InitializedPlugins()
    for _, path in ipairs(self.paths or {}) do
        ix.resourcenodes.LoadFromDir(path.."/resourcenodes")
    end
end

properties.Add("check_harvest", {
    MenuLabel = "Check Harvest Time",
    Order = 998,
    MenuIcon = "icon16/clock.png",

    Filter = function(self, entity, client)
        if (!IsValid(entity)) then return false end
        if (entity:GetClass():find("ix_resourcenode") == nil) then return false end
        if (!gamemode.Call( "CanProperty", client, "check_harvest", entity)) then return false end

        return CAMI.PlayerHasAccess(client, "Helix - Manage Resource Nodes", nil)
    end,

    Action = function(self, entity)
        self:MsgStart()
            net.WriteEntity(entity)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        local entity = net.ReadEntity()

        if (!IsValid(entity)) then return end
        if (!self:Filter(entity, client)) then return end

        if !entity:GetCanHarvest() then
            local secRemaining = entity.minSeconds - entity.secondsPassed
            local hours = math.floor(secRemaining / 3600)
            local minutes = math.floor((secRemaining - (hours * 3600)) / 60)
            local seconds = secRemaining - (hours * 3600) - (minutes * 60)

            client:Notify(hours .. " Hrs, " .. minutes .. " Mins, and " .. seconds .. " Secs remaining until harvest.")
        else
            client:Notify("This node can currently be harvested.")
        end
    end
})

properties.Add("fill_harvest", {
    MenuLabel = "Set Harvestable",
    Order = 999,
    MenuIcon = "icon16/cart_put.png",

    Filter = function(self, entity, client)
        if (!IsValid(entity)) then return false end
        if (entity:GetClass():find("ix_resourcenode") == nil) then return false end
        if (!gamemode.Call( "CanProperty", client, "fill_harvest", entity)) then return false end

        return CAMI.PlayerHasAccess(client, "Helix - Manage Resource Nodes", nil)
    end,

    Action = function(self, entity)
        self:MsgStart()
            net.WriteEntity(entity)
        self:MsgEnd()
    end,

    Receive = function(self, length, client)
        local entity = net.ReadEntity()

        if (!IsValid(entity)) then return end
        if (!self:Filter(entity, client)) then return end

        entity:Fill()

        client:Notify("Node Harvest allowed.")
    end
})

if (SERVER) then
    function PLUGIN:SaveData()
        local data = {}

        for _, entity in ipairs(ents.FindByClass("ix_resourcenode_*")) do
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
                node = entity:GetNodeID(),
                canHarvest = entity:GetCanHarvest(),
                minSecs = entity.minSeconds,
                secPassed = entity.secondsPassed,
            }
        end
        self:SetData(data)
    end

    function PLUGIN:LoadData()
        for _, v in ipairs(self:GetData() or {}) do
            local entID = "ix_resourcenode_" .. v.node
            local entity = ents.Create(entID)
            entity:SetPos(v.pos)
            entity:SetAngles(v.angles)
            entity:Spawn()

            entity:SetModel(v.model)
            entity:SetSkin(v.skin or 0)
            entity:SetSolid(SOLID_VPHYSICS)
            entity:PhysicsInit(SOLID_VPHYSICS)

            local physObj = entity:GetPhysicsObject()

            if (IsValid(physObj)) then
                physObj:EnableMotion(false)
                physObj:Sleep()
            end

            entity:SetNodeID(v.node)
            entity:SetCanHarvest(v.canHarvest)
            entity.minSeconds = v.minSecs
            entity.secondsPassed = v.secPassed
        end
    end

end