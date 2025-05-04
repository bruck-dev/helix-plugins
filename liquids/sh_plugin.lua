
PLUGIN.name = "Liquids Library"
PLUGIN.description = "Adds support for tracking liquids inside of containers, and sources to fill them."
PLUGIN.author = "bruck"

-- blah blah blah in short you are free to edit and reupload this as long as you dont charge for changes you make and so long as i am properly credited for my work as a primary author :)
-- id also like to credit adolphus and TERRANOVA for the original form of the idea. while this is a total, ground-up rewrite, i would not have been able to do it without taking inspiration from his work
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


ix.util.Include("sv_plugin.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("sh_config.lua")
ix.util.Include("sh_sources.lua")
ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)

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