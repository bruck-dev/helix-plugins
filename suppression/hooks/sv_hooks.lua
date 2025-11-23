
local PLUGIN = PLUGIN

util.AddNetworkString("ixSuppressionBullet")
util.AddNetworkString("ixSuppressionExplosion")
util.AddNetworkString("ixSuppressionReset")

local function writeVector(vector)
    net.WriteFloat(vector.x)
    net.WriteFloat(vector.y)
    net.WriteFloat(vector.z)
end

-- if suppression is on, pass the necessary origin info to the client so it can decide if it needs to modify suppression numbers or not
function PLUGIN:EntityFireBullets(entity, data)
    if !entity or !data then
        return
    end

    if !ix.config.Get("enableSuppression", true) then
        return
    end

    local damage = data.Damage or 0
    if damage == 0 then
        damage = game.GetAmmoPlayerDamage(game.GetAmmoID(data.AmmoType))
    end

    net.Start("ixSuppressionBullet")
        net.WriteEntity(entity)         -- entity firing
        writeVector(data.Src)           -- position of the firing entity (roughly)
        writeVector(data.Dir)           -- aim position where the bullets come from
        net.WriteFloat(data.Distance)   -- maximum distance this bullet can travel
    net.Broadcast()
end

-- ditto, but just the amount as this fires when we know the player was hurt
function PLUGIN:OnDamagedByExplosion(client, dmgInfo)
    local damage = dmgInfo:GetDamage()
    if damage > 0 then
        net.Start("ixSuppressionExplosion")
            net.WriteFloat(damage / 20)
        net.Send(client)
    end
end

-- clear suppression when the player respawns
function PLUGIN:PlayerSpawn(client, transition)
    net.Start("ixSuppressionReset")
    net.Send(client)
end