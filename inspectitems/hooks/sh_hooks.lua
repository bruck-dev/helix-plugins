
local PLUGIN = PLUGIN

function PLUGIN:InitializedPlugins()
    for id, item in pairs(ix.item.list) do
        if !item.functions.ZZInspect then
            item.functions.ZZInspect = { -- for naming order, so that it's normally last in the list; yikes, though
                name = "Inspect",
                icon = "icon16/magnifier.png",
                OnRun = function(item)
                    item:Inspect(item.player)
                    return false
                end,
                OnCanRun = function(item)
                    return item:CanInspect(item.player)
                end
            }
        end
    end
end

function PLUGIN:CanTransferItem(item, oldInv, newInv)
    if item.InspectingPlayer and IsValid(item.InspectingPlayer) then
        return false
    end
end

CAMI.RegisterPrivilege({
    Name = "Helix - Manage Inspectables",
    MinAccess = "admin"
})

properties.Add("inspectable_set_model", {
    MenuLabel = "Set Model",
    Order = 990,
    MenuIcon = "icon16/brick_edit.png",

    Filter = function(self, entity, client)
        if (!IsValid(entity)) then return false end
        if (entity:GetClass() != "ix_inspectable") then return false end
        if (!gamemode.Call( "CanProperty", client, "inspectable_set_model", entity)) then return false end

        return CAMI.PlayerHasAccess(client, "Helix - Manage Inspectables", nil)
    end,

    Action = function(self, ent)
        Derma_StringRequest(
            "Set Model",
            "Enter a valid model path for the Inspectable.",
            ent:GetModel(),
            function(model)
                net.Start("InspectEnt_SetModel")
                    net.WriteEntity(ent)
                    net.WriteString(model)
                net.SendToServer()
            end
        )
    end
})

properties.Add("inspectable_set_name", {
    MenuLabel = "Set Name",
    Order = 990,
    MenuIcon = "icon16/tag_blue_edit.png",

    Filter = function(self, entity, client)
        if (!IsValid(entity)) then return false end
        if (entity:GetClass() != "ix_inspectable") then return false end
        if (!gamemode.Call( "CanProperty", client, "inspectable_set_name", entity)) then return false end

        return CAMI.PlayerHasAccess(client, "Helix - Manage Inspectables", nil)
    end,

    Action = function(self, ent)
        Derma_StringRequest(
            "Set Name",
            "Enter a displayed name for the inspection panel.",
            ent:GetDisplayName(),
            function(model)
                net.Start("InspectEnt_SetName")
                    net.WriteEntity(ent)
                    net.WriteString(model)
                net.SendToServer()
            end
        )
    end
})