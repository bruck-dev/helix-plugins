
PLUGIN.name = "No Punch Damage"
PLUGIN.description = "Disables all damage dealt on punch."
PLUGIN.author = "bruck"

function PLUGIN:GetPlayerPunchDamage(client, damage, context)
    return 0
end