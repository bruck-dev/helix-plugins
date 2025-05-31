
local PLUGIN = PLUGIN

-- loads all liquids found in plugin folders
function PLUGIN:InitializedPlugins()
    for _, path in ipairs(self.paths or {}) do
        ix.liquids.LoadFromDir(path .. "/liquids")
    end
end

CAMI.RegisterPrivilege({
    Name = "Helix - Manage Liquid Sources",
    MinAccess = "admin"
})

properties.Add("liquid_source_edit", {
    MenuLabel = "Edit Liquid Source",
    Order = 990,
    MenuIcon = "icon16/user_edit.png",

    Filter = function(self, entity, client)
        if (!IsValid(entity)) then return false end
        if (entity:GetClass() != "ix_liquidsource") then return false end
        if (!gamemode.Call( "CanProperty", client, "liquid_source_edit", entity)) then return false end

        return CAMI.PlayerHasAccess(client, "Helix - Manage Liquid Sources", nil)
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

        entity.receivers[#entity.receivers + 1] = client

        client.ixLiqSource = entity

        net.Start("ixLiqSourceEditor")
            net.WriteEntity(entity)
        net.Send(client)
    end
})