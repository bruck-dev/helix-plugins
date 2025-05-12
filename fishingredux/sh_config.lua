
-- Configure catchable fish here
-- FChance is relative to a catch being *rolled*, not overall. It isn't exclusive, either; if a chance of 0.4 is rolled after a catch is confirmed, anything over 0.4 has an equal chance of being picked. A 0.01 could feasibly catch ANY fish.
-- A fish with an FChance of 1.0 will always be able to be caught, so long as you are in their biome.
PLUGIN.fish = {
    {
        FName = "River Catfish",
        FId = "catfish",
        FModel = "models/tsbb/fishes/catfish.mdl",
        FDesc = "A type of bottom-feeding fish, identifiable by its four stinging barbels and flat head.",
        FPrice = 20,
        FWidth = 2,
        FChance = 0.55,
        FBiome = "Freshwater",
    },
    {
        FName = "Black Bass",
        FId = "bass",
        FModel = "models/tsbb/fishes/bass.mdl",
        FDesc = "A very common species of lake and river fish, popular for sport fishing. Most are, ironically, a dull green color.",
        FPrice = 2,
        FWidth = 2,
        FChance = 1.0,
        FBiome = "Freshwater",
    },
    {
        FName = "Common Carp",
        FId = "carp",
        FModel = "models/tsbb/fishes/carp.mdl",
        FDesc = "A freshwater species of bottom-feeding fish, carp are known primarily as invasive pests in many parts of the world. Seen by some as undesirable for consumption due to their oily meat.",
        FPrice = 1,
        FWidth = 2,
        FChance = 1.0,
        FBiome = "Freshwater",
    },
    {
        FName = "Red Salmon",
        FId = "salmon",
        FModel = "models/tsbb/fishes/sockeye_salmon.mdl",
        FDesc = "A species of red-colored salmon that migrates from freshwater rivers to the seas to spawn.",
        FPrice = 25,
        FWidth = 2,
        FChance = 0.4,
        FBiome = "Freshwater",
    },
    {
        FName = "Lake Pike",
        FId = "pike",
        FModel = "models/tsbb/fishes/pike.mdl",
        FDesc = "An aggressive ambush predator, Pike are a large, olive-green colored species of freshwater fish that prefers to live in weedy or rocky areas with plenty of places to hide.",
        FPrice = 12,
        FWidth = 2,
        FChance = 0.6,
        FBiome = "Freshwater",
    },
    {
        FName = "Coastal Trout",
        FId = "trout",
        FModel = "models/tsbb/fishes/trout.mdl",
        FDesc = "A species of trout, often found in the tributaries and rivers that feed into the oceans. This particular species prefers to live in brackish rivers near the ocean, returning to freshwater to spawn.",
        FPrice = 8,
        FWidth = 2,
        FChance = 0.8,
        FBiome = { "Freshwater", "Brackish" },
    },
    {
        FName = "Pilchard Sardine",
        FId = "sardine",
        FModel = "models/tsbb/fishes/sardine.mdl",
        FDesc = "Normally caught with nets instead of rod-and-reel, Sardines are tiny saltwater fish that live in large schools.",
        FPrice = 2,
        FChance = 0.9,
        FBiome = "Saltwater",
    },
    {
        FName = "Anchovy",
        FId = "anchovy",
        FModel = "models/tsbb/fishes/anchovy.mdl",
        FDesc = "Anchovies are a tiny saltwater fish, commonly preyed on by other species. Their schools are often uses as indicators for where other, larger fish could be.",
        FPrice = 2,
        FChance = 0.9,
        FBiome = "Saltwater",
    },
    {
        FName = "Silver Coalfish",
        FId = "coalfish",
        FModel = "models/tsbb/fishes/pollock.mdl",
        FDesc = "A species of pollock, often fished for food. Its white meat is popular in fried snacks.",
        FPrice = 10,
        FWidth = 2,
        FChance = 0.65,
        FBiome = "Saltwater",
    },
    {
        FName = "Spotted Mackerel",
        FId = "mackerel",
        FModel = "models/tsbb/fishes/mackerel.mdl",
        FDesc = "A blue-colored fish, analogous to a slimmer tuna. They are often caught in schools with fishing nets.",
        FPrice = 2,
        FChance = 1.0,
        FBiome = "Saltwater",
    },
    {
        FName = "Ocean Cod",
        FId = "cod",
        FModel = "models/tsbb/fishes/cod.mdl",
        FDesc = "A popular species of ocean fish, known for its dense white meat. Occasionally used as a source of oil production if caught in large quantities.",
        FPrice = 2,
        FWidth = 2,
        FChance = 1.0,
        FBiome = "Saltwater",
    },
    {
        FName = "Brown Rockfish",
        FId = "rockfish",
        FModel = "models/tsbb/fishes/rockfish.mdl",
        FDesc = "A sea water fish most often found in shallow waters or bays, Brown Rockfish are mostly caught for recreation due to their less than desirable flavor.",
        FPrice = 10,
        FChance = 0.75,
        FBiome = "Saltwater",
    },
    {
        FName = "Blue Tuna",
        FId = "tuna",
        FModel = "models/tsbb/fishes/tuna.mdl",
        FDesc = "Tuna are an agile species of predatory ocean fish, commonly used as a source of food. Tuna are one of the only species of fish that has a higher body temperature than the water it lives in.",
        FPrice = 25,
        FChance = 0.4,
        FBiome = "Saltwater",
    },
}

-- Config options
ix.config.Add("catchChance", 80, "The raw percentage of the time something should be caught while fishing. Does not affect fish rarities - only if something is successfully caught.", nil, {
    category = PLUGIN.name,
    data = {min = 0, max = 100},
})
ix.config.Add("requireFishingBait", true, "Whether or not fishing bait must be in a player's inventory for them to be able to fish.", nil, {
    category = PLUGIN.name
})

ix.config.Add("useBiomeZones", false, "If true, fish will only appear in the Helix Area matching their biome preference. If the Areas plugin is not installed, this does nothing.", nil, {
    category = PLUGIN.name
})