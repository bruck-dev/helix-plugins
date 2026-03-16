
local PLUGIN = PLUGIN

PLUGIN.name = "NPC Relations"
PLUGIN.author = "bruck"
PLUGIN.description = "Allows NPCs to have preset player relationships from their faction or other methods."
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]

if SERVER then
    -- Gets the player's NPC relations from their faction. This has a lower priority than the hook returned value.
    -- This should be a table in the form of: {npc_class_name = D_ENUM_VALUE} (ex for hostile citizens: {npc_citizen = D_HT})
    local function GetFactionRelations(client)
        if client:GetCharacter() then
            local faction = ix.faction.indices[client:Team()]
            if faction.npcRelations then
                return faction.npcRelations
            end
        end
    end

    -- Used to set the relationship of an entity based on the data in the faction tables.
    function PLUGIN:OnEntityCreated(entity)
        if IsValid(entity) and entity:IsNPC() then
            local class = entity:GetClass()

            -- fake class for rebel turrets
            if class == "npc_turret_floor" then
                if !entity.m_bInitialized then
                    timer.Simple(0, function()
                        self:OnEntityCreated(entity)
                    end)

                    entity.m_bInitialized = true
                    return
                elseif bit.band(entity:GetSpawnFlags(), 512) != 0 then
                    class = "npc_turret_floor_resistance"
                end
            elseif class == "npc_rollermine" then
                if !entity.m_bInitialized then
                    timer.Simple(0, function()
                        self:OnEntityCreated(entity)
                    end)

                    entity.m_bInitialized = true
                    return
                elseif bit.band(entity:GetSpawnFlags(), 262144) != 0 then
                    class = "npc_rollermine_hacked"
                end
            elseif class == "npc_citizen" then
                local keys = entity:GetKeyValues()
                if !entity.m_bInitialized then
                    timer.Simple(0, function()
                        self:OnEntityCreated(entity)
                    end)

                    entity.m_bInitialized = true
                    return
                elseif keys.squadname and keys.squadname == "overwatch" then
                    class = "npc_citizen_rebel_enemy"
                end
            end

            for _, client in ipairs(player.GetAll()) do
                if client:GetCharacter() then
                    local relations = hook.Run("GetNPCRelations", client) or GetFactionRelations(client) or {}

                    if istable(relations) and relations[class] then
                        entity:AddEntityRelationship(client, relations[class], 0)
                    end
                end
            end
        end
    end

    -- Sets the relationship between entities once a new player spawns.
    function PLUGIN:PlayerSpawn(client)
        hook.Run("UpdateNPCRelations", client)
    end

    -- Updates faction relationships when a character switches factions.
    function PLUGIN:CharacterVarChanged(char, key, old, new)
        if key != "faction" then return end
        if old == nil or old == 0 then return end
    
        hook.Run("UpdateNPCRelations", char:GetPlayer())
    end

    function PLUGIN:UpdateNPCRelations(client)
        if client:GetCharacter() then
            local relations = hook.Run("GetNPCRelations", client) or GetFactionRelations(client) or {}

            for _, v in ipairs(ents.FindByClass("npc_*")) do
                if v:IsNPC() then
                    local class = v:GetClass()
                    local flags = v:GetSpawnFlags()
                    local keys = v:GetKeyValues()

                    -- sets up alternate classes based on their flags and the spawnmenu name affiliated with them (e.g, resistance turret vs. normal turret)
                    if class == "npc_turret_floor" and bit.band(flags, 512) != 0 then
                        class = "npc_turret_floor_resistance"
                    elseif class == "npc_rollermine" and bit.band(flags, 262144) != 0 then
                        class = "npc_rollermine_hacked"
                    elseif class == "npc_citizen" and (keys.squadname and keys.squadname == "overwatch") then
                        class = "npc_citizen_rebel_enemy"
                    end

                    if istable(relations) and relations[class] then
                        v:AddEntityRelationship(client, relations[class], 0)
                    end
                end
            end
        end
    end
end