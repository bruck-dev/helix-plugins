
local PLUGIN = PLUGIN

ix.config.Add("chatRadioColor", Color(110, 185, 85, 255), "The color for IC chat over the radio.", nil, {
    category = PLUGIN.name
})
ix.config.Add("enableRadio", true, "Whether or not players are able to use radio items to communicate.", nil, {
    category = PLUGIN.name
})
ix.config.Add("radioListenRange", 92, "The maximum radius for which a player can hear radio messages and music from a stationary-type radio.", nil, {
	data = {min = 10, max = 5000, decimals = 1},
	category = PLUGIN.name
})

-- these are from fauxzor's Extended Radio plugin, although slightly modified in their application
ix.config.Add("garbleRadio", true, "Whether or not radio messages become naturally garbled over long distances. Taken from Extended Radio.", nil, {
    category = PLUGIN.name
})
ix.config.Add("radioRangeMult", 100, "The multiplier applied to base chat range that determines the maximum radio range.", nil, {
    data = {min = 1, max = 175},
    category = PLUGIN.name
})
ix.config.Add("radioDecayModel", 3, "The model used to calculate how scrambled radio messages become over a distance.\n\n"..
    "(1) Quadratic (x^2): Good close range, bad past medium range.\n\n"..
    "(2) Logarithmic (x^(1/3)Log10[2]/Log10[2/x]): Worst overall, but smoothest/most predictable decay.\n\n"..
    "(3) Hybrid (0.5(x + x^8)): Worse close range than quadratic, better long range than logarithmic.\n\n"..
    "(4) Lowest (0.5(x^2 + x^9)): Best overall, with approximately quadratic decay at long range.", nil, {
    data = {min = 1, max = 4},
    category = PLUGIN.name,
})