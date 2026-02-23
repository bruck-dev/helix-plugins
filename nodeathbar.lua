
PLUGIN.name = "No Death Progress Bar"
PLUGIN.description = "Disables the death progress bar for respawning players."
PLUGIN.author = "bruck"

if (SERVER) then
    -- this is technically bad practice but otherwise im forced to return a value and that might break other plugins
    function GAMEMODE:DoPlayerDeath(client, attacker, damageinfo)
        client:AddDeaths(1)

        if (hook.Run("ShouldSpawnClientRagdoll", client) != false) then
            client:CreateRagdoll()
        end

        if (IsValid(attacker) and attacker:IsPlayer()) then
            if (client == attacker) then
                attacker:AddFrags(-1)
            else
                attacker:AddFrags(1)
            end
        end

        net.Start("ixPlayerDeath")
        net.Send(client)

        --client:SetAction("@respawning", ix.config.Get("spawnTime", 5))
        client:SetDSP(31)
    end
end