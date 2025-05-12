local PLUGIN = PLUGIN

PLUGIN.name = "Fishing: Redux"
PLUGIN.author = "JohnyReaper/Spook, modified by bruck"
PLUGIN.description = "Adds a complete fishing system, with support for biomes, non-fish catches, and more."
PLUGIN.important = "NOTE: PLEASE MOVE THE CONTENTS OF THE REQUIRED ASSETS FOLDER IN A CONTENT PACK, SUCH THAT YOUR PLAYERS CAN DOWNLOAD IT!"

ix.util.Include("sv_hooks.lua")
ix.util.Include("sh_config.lua")

-- Create fishing area types. "Any" is the default for fish/items without a given biome.
if ix.area then
    function PLUGIN:SetupAreaProperties()
        if (SERVER) then
            if timer.Exists("ixFishingAreaThink") then
                timer.Remove("ixFishingAreaThink")
            end
            timer.Create("ixFishingAreaThink", ix.config.Get("areaTickTime", 1), 0, function()
                self:FishingAreaThink()
            end)
        end

        ix.area.AddType("Fishing - Freshwater")
        ix.area.AddType("Fishing - Saltwater")
        ix.area.AddType("Fishing - Brackish")
        ix.area.AddType("Fishing - Any")
    end
end

function PLUGIN:InitializedPlugins()

    ALWAYS_RAISED["weapon_fishingrod"] = true

    -- Create fish from PLUGIN.fish specified above
    for k, v in ipairs(PLUGIN.fish) do
        local id = v.FId or string.lower(string.Replace(string.Replace(v.FName,"'", "")," ","_"))
        id = "fish_" .. id
        local ITEM = ix.item.Register(id, "base_stackable", false, nil, true)
        ITEM.maxStack = 10
        ITEM.defaultStack = 1
        ITEM.name = v.FName
        ITEM.description = v.FDesc
        ITEM.model = v.FModel
        ITEM.width = v.FWidth or 1
        ITEM.height = v.FHeight or 1
        ITEM.price = v.FPrice or 0
        ITEM.category = "Fishing"
        ITEM.noBusiness = true
        ITEM.canCatch = true
        ITEM.catchChance = v.FChance
    end

    -- Goes through any items that are not currently in PLUGIN.fish and should be catchable and adds them to the list
    -- If you want something like junk items to be caught, use ITEM.canCatch and ITEM.catchChance like you would for standard fish. Biome is assumed to be 'any' unless specified in ITEM.biome
    for k, v in pairs(ix.item.list) do
        if v.category != "Fishing" and v.canCatch and v.catchChance then
            table.insert(PLUGIN.fish, {
                FName = v.name,
                FId = v.uniqueID,
                FChance = v.catchChance,
                FBiome = v.biome or "Any",
            })
        end
    end

end

-- gets all fish based on their found biome
function PLUGIN:GetFishByBiome(biome)
    biome = biome:lower()
    local fish = {}
    for _, v in ipairs(self.fish) do
        -- list of biomes
        if v.FBiome and istable(v.FBiome) then
            for i, bio in ipairs(v.FBiome) do
                if string.find(biome, bio:lower()) then
                    table.insert(fish, v)
                end
            end

        -- single biome
        elseif v.FBiome and string.find(biome, v.FBiome:lower()) then
            table.insert(fish, v)

        -- no biome specified or any
        elseif !v.FBiome or (biome == "any" and v.FBiome:lower() == "any") then
            table.insert(fish, v)
        end
    end

    return fish
end