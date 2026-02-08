
local PLUGIN = PLUGIN

PLUGIN.name = "Resource Nodes"
PLUGIN.author = "bruck"
PLUGIN.description = "Adds entities to produce crafting resources over time."
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)

CAMI.RegisterPrivilege({
    Name = "Helix - Manage Resource Nodes",
    MinAccess = "admin"
})

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