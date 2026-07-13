local PLUGIN = PLUGIN

PLUGIN.name = "IX Loot: Redux"
PLUGIN.descriptions = "Adds easily configurable and lightweight loot containers."
PLUGIN.author = "bruck, forked from work by Riggs"

ix.util.Include("sh_config.lua")

CAMI.RegisterPrivilege({
    Name = "Helix - Manage Loot Containers",
    MinAccess = "admin"
})

properties.Add("loot_setclass", {
    MenuLabel = "Set Loot Class",
    MenuIcon = "icon16/wrench.png",
    Order = 5,

    Filter = function(self, ent, client)
        if !(IsValid(ent) and ent:GetClass() == "ix_loot_container") then return false end

        return CAMI.PlayerHasAccess(client, "Helix - Manage Loot Containers", nil)
    end,

    Action = function(self, ent)
    end,

    LootClassSet = function(self, ent, class)
        self:MsgStart()
            net.WriteEntity(ent)
            net.WriteString(class)
        self:MsgEnd()
    end,

    MenuOpen = function(self, option, ent, trace)
        local subMenu = option:AddSubMenu()

        for k, v in SortedPairs(ix.loot.containers) do
            subMenu:AddOption(v.name.." ("..k..")", function()
                self:LootClassSet(ent, k)
            end)
        end
    end,

    Receive = function(self, len, client)
        local ent = net.ReadEntity()

        if !IsValid(ent) then return end
        if !self:Filter(ent, client) then return end

        local class = net.ReadString()
        local loot = ix.loot.containers[class]

        -- safety check, just to make sure if it really exists in both realms.
        if !(class or loot) then
            client:Notify("You did not specify a valid container class!")
            return
        end

        ent:SetContainerClass(tostring(class))
        ent:SetModel(loot.model)
        ent:SetSkin(loot.skin or 0)
        ent:PhysicsInit(SOLID_VPHYSICS) 
        ent:SetSolid(SOLID_VPHYSICS)
        ent:SetUseType(SIMPLE_USE)
        ent:DropToFloor()

        PLUGIN:SaveData()
    end
})

if SERVER then
    function PLUGIN:SaveData()
        local data = {}
    
        for _, entity in pairs(ents.FindByClass("ix_loot_container")) do
            local bodygroups = {}
            for _, v in ipairs(entity:GetBodyGroups() or {}) do
                bodygroups[v.id] = entity:GetBodygroup(v.id)
            end

            data[#data + 1] = {
                pos = entity:GetPos(),
                ang = entity:GetAngles(),
                contClass = entity:GetContainerClass(),
                model = entity:GetModel(),
                skin = entity:GetSkin() or 0,
                color = entity:GetColor(),
                bodygroups = bodygroups,
                lootedBy = entity.lootedBy or nil,
                timesUsed = entity.timesUsed or nil,
            }
        end

        self:SetData(data)
    end

    function PLUGIN:LoadData()
        for _, v in ipairs(self:GetData() or {}) do

            local entity = ents.Create("ix_loot_container")
            entity:SetPos(v.pos)
            entity:SetAngles(v.ang)
            entity:SetContainerClass(v.contClass)

            if v.lootedBy then
                entity.lootedBy = v.lootedBy
            end

            if v.timesUsed then
                entity.timesUsed = v.timesUsed
            end

            entity:Spawn()
            
            entity:SetModel(v.model)
            entity:SetSkin(v.skin or 0)
            entity:SetColor(v.color or Color(255, 255, 255, 255))

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
end
