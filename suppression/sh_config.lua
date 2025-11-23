
local PLUGIN = PLUGIN

ix.config.Add("enableSuppression", true, "Whether or not players will have suppression effects applied from hit or near miss bullets.", function(oldValue, newValue)
    if SERVER then
        if !newValue then
            net.Start("ixSuppressionReset")
            net.Broadcast()
        end
    end
end, {category = PLUGIN.name}
)

ix.config.Add("enableSuppressionInVehicles", true, "Whether or not players will be suppressed while inside of vehicles.", nil, {
    category = PLUGIN.name
})

ix.config.Add("enableSuppressionHeartbeat", true, "Whether or not the heartbeat sound effect will be played for players as suppression increases.", nil, {
    category = PLUGIN.name
})

ix.config.Add("suppressionRadius", 96, "The maximum radius for which a player will be suppressed by near misses or impacts.", nil, {
	data = {min = 1, max = 256, decimals = 1},
	category = PLUGIN.name
})

ix.config.Add("suppressionFadeDelay", 5, "The time, in seconds, that delays suppression effect fade after the last suppressive event (explosion, near miss, etc).", nil, {
	data = {min = 0, max = 10, decimals = 1},
	category = PLUGIN.name
})