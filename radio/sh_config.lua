
local PLUGIN = PLUGIN

ix.config.Add("chatRadioColor", Color(119, 214, 87, 255), "The color for IC chat over the radio.", nil, {
    category = PLUGIN.name
})
ix.config.Add("enableRadio", true, "Whether or not players are able to use radio items to communicate.", nil, {
    category = PLUGIN.name
})
ix.config.Add("radioChatListenRange", 96, "The maximum radius for which a player can hear radio messages from a stationary-type radio.", nil, {
	data = {min = 10, max = 5000, decimals = 1},
	category = PLUGIN.name
})
ix.config.Add("radioStationListenRange", 384, "The maximum radius for which a player can hear radio stations from a stationary-type radio.", nil, {
	data = {min = 10, max = 5000, decimals = 1},
	category = PLUGIN.name
})

ix.config.Add("garbleRadio", true, "Whether or not radio messages become naturally garbled over long distances. Taken from Extended Radio.", nil, {
    category = PLUGIN.name
})
ix.config.Add("radioRangeMult", 70, "The multiplier applied to base chat range that determines the maximum radio range.", nil, {
    data = {min = 1, max = 200},
    category = PLUGIN.name
})