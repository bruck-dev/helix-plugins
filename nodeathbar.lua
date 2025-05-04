
PLUGIN.name = "No Death Progress Bar"
PLUGIN.description = "Disables the death progress bar from appearing."
PLUGIN.author = "bruck"

if (SERVER) then
    function PLUGIN:DoPlayerDeath(client, attacker, damageinfo)
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

        return true
    end
end