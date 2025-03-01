
local PLUGIN = PLUGIN

PLUGIN.name = "Padlocks"
PLUGIN.description = "Adds a system of placeable and breakable padlocks."
PLUGIN.author = "bruck"
PLUGIN.license = [[
Copyright 2025 bruck
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
]]


-- list of weapon classes that cannot be used to break padlocks
PLUGIN.PadlockWeaponsBlacklist = {
    ["ix_hands"] = true,
}

if SERVER then
    function PLUGIN:EntityTakeDamage(entity, dmgInfo)
        if entity:GetClass() == "ix_padlock" then
            if !dmgInfo:GetAttacker() then return end

            if self:CanBreakLock(dmgInfo) then
                local wep = dmgInfo:GetWeapon()
                if !wep or wep == NULL or (wep and self.PadlockWeaponsBlacklist[wep:GetClass()]) then
                    return
                else
                    entity.bShouldBreak = true
                    entity:Remove()
                end
            end
        end
    end

    function PLUGIN:CanBreakLock(dmgInfo)
        local validDamageTypes = {
            DMG_BULLET,             -- bullets (obviously)
            DMG_SLASH,              -- stunsticks, knives
            DMG_BLAST,              -- grenades, rockets, bombs
            DMG_CLUB,               -- crowbar
            DMG_ENERGYBEAM,         -- lasers
            DMG_NEVERGIB,           -- crossbow bolts
            DMG_ACID,               -- antlion worker spit
            DMG_PHYSGUN,            -- gravity gun shots
            DMG_PLASMA,             -- not sure where this is used but it would probably melt the lock
            DMG_AIRBOAT,            -- airboat gun
            DMG_DIRECT,             -- applied via code
            DMG_BUCKSHOT,           -- shotgun pellets
            DMG_SNIPER,             -- sniper penetrated ammo (combine sniper)
        }
        for _, v in ipairs(validDamageTypes) do
            if dmgInfo:IsDamageType(v) then
                return true
            end
        end
        
    end

    function PLUGIN:SaveData()
        local data = {}

        for _, entity in ipairs(ents.FindByClass("ix_padlock")) do
            data[#data + 1] = {
                name = entity:GetDisplayName(),
                pos = entity:GetPos(),
                angles = entity:GetAngles(),
                model = entity:GetModel(),
                locked = entity:GetLocked(),
                pid = entity:GetPersistentID(),
                doorInfo = {
                    entity.door:MapCreationID(),
                    entity.door:WorldToLocal(entity:GetPos()),
                    entity.door:WorldToLocalAngles(entity:GetAngles()),
                },
            }
        end
        self:SetData(data)
    end

    function PLUGIN:LoadData()
        for _, v in ipairs(self:GetData() or {}) do
            local door = ents.GetMapCreatedEntity(v.doorInfo[1])

            if (IsValid(door) and door:IsDoor()) then
                local entity = ents.Create("ix_padlock")
                entity:SetPos(v.pos)
                entity:SetAngles(v.angles)
                entity:Spawn()

                entity:SetDoor(door, door:LocalToWorld(v.doorInfo[2]), door:LocalToWorldAngles(v.doorInfo[3]))
                entity:SetLocked(v.locked)
    
                entity:SetDisplayName(v.name)
                entity:SetModel(v.model)
                entity:SetPersistentID(v.pid)

                entity:SetSolid(SOLID_VPHYSICS)
                entity:PhysicsInit(SOLID_VPHYSICS)
            end

        end
    end

end