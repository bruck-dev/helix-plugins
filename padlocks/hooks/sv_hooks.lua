
local PLUGIN = PLUGIN

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

function PLUGIN:PlayerLoadedCharacter(client, char, prevChar)
    client:SetNetVar("usingPadlock", nil)
end

function PLUGIN:EntityTakeDamage(entity, dmgInfo)
    if entity:GetClass() == "ix_padlock" then
        if !dmgInfo:GetAttacker() then return end

        if hook.Run("CanBreakPadlock", dmgInfo) then
            local wep = dmgInfo:GetWeapon()
            if !wep or wep == NULL or (wep and self.padlockWeaponsBlacklist[wep:GetClass()]) then
                return
            else
                entity.bShouldBreak = true
                entity:Remove()
            end
        end
    end
end

function PLUGIN:CanBreakPadlock(dmgInfo)
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