
local PLUGIN = PLUGIN

ix.loot = ix.loot or {}
ix.loot.containers = ix.loot.containers or {}

--[[
["class_id"] = {                            -- how this container class is internally identified
    name = "Display Name",
    description = "Description",
    model = "path/to/model.mdl",
    actionText = "Looting...",              -- (OPTIONAL) the text displayed above the action bar while looting the container. defaults to "Looting..."
    skin = 0,                               -- (OPTIONAL) model skin group to use for the container
    hideTooltip = false,                    -- (OPTIONAL) whether or not the helix tooltip should be shown when hovering the crosshair over the container
    delay = 180,                            -- time in seconds before the container can be reopened. optional if using oncePerCharacter
    lootTime = {2, 3, 5},                   -- can be an integer or a table of {["min"] = x, ["max"] = y}, or {x, y, z}
    lootCount = 1,                          -- how many items can be in the container. can be a table of {["min"] = x, ["max"] = y}, or {x, y, z} or an integer
    items = {                               -- a table of possible loot items, of the form {["uniqueID"] = {["amount"] = n}, where amount can be an int, a table like {x,y,z}, or a table like {["min"] = x, ["max"] = y}
        ["unique_id] = {                    -- item unique id to spawn. if "money", will give the player money instead
            ["amount"] = {                  -- quantity to spawn. can be an int or a table of {["min"] = x, ["max"] = y}, or {x, y, z}

            },
            ["data"] = {                    -- (OPTIONAL) data for spawned item(s)

            },
            ["chance"] = 0.10,              -- (OPTIONAL) the chance that the item will be included in the possible list of random items. does NOT dictate absolute chance, just inclusion. deleting is equivalent to making the chance 1, or 100%
            ["maxLooted"] = 1,              -- (OPTIONAL) the maximum amount of times this unique ID can be looted. if lootCount is 2 and maxLooted is 1, it will not be looted again. deleting is equivalent to allowing it to be looted an infinite number of times.
        }
    },
    oncePerCharacter = false,               -- (OPTIONAL) if true, each player can only loot the container once. in this case, the delay is ignored.
    maxUses = 1,                            -- (OPTIONAL) if greater than zero, the container will be deleted and replaced with an identical prop so that it cannot be looted again once it has been looted the max number of times
    tool = "unique_id",                     -- (OPTIONAL) the item unique id that is required to open the loot container
    lootActionSound = {"1.wav, 2.wav"},     -- (OPTIONAL) sound to play while looting, once per second. can be a string path or a table of paths
    lootFinishSound = "1.wav",              -- (OPTIONAL) sound to play once the container has been looted. can be a string path or a table of paths
    onStart = function(client, ent)         -- (OPTIONAL) fired when the use key is pressed
    end,
    onEnd = function(client, ent)           -- (OPTIONAL) fired when the container has been looted
    end,
    onCancel = function(client, ent)        -- (OPTIONAL) fired when the loot attempt is canceled by looking away
    end,
},
]]--

ix.loot.containers = {
    ["crate_large"] = {
        name = "Wooden Crate",
        description = "A sealed wooden storage crate.",
        model = "models/props_junk/wood_crate002a.mdl",
        lootTime = 3,
        lootCount = {["min"] = 1, ["max"] = 4},
        items = {
            ["currency_default"] = {
                ["amount"] = {
                    ["min"] = 5,
                    ["max"] = 75
                },
            },
            ["beretta_m9"] = { -- shameless self plug for my arc9 support plugin :)
                ["amount"] = 1,
                ["data"] = {
                    ["preset"] = "XQAAAQCNAQAAAAAAAAA9iIIiM7tuo1AtT00OeFDtNRc/1CeetV+ujTKgaKZq1lGZDS6WAHmy6LvNi11Vq2HP1HE3MB5OSFJXKD/RWHvAROzJA7xPDoo3M1gkO90Ak/W89qJKNvkXE9rW/mL3Jue1ZeTFTCbyeck059a2LEweUl67LU5ecOE3QpUkovI8n5MutGPe13CaT1wbmVEZtt8lsdDdw9F+jOphz/HixakUPZiXzU8vjVxZmKy08gA=",
                },
                ["chance"] = 0.30,
                ["maxLooted"] = 1,
            },
            ["first_aid_kit"] = {
                ["amount"] = 1,
                ["chance"] = 0.75,
            },
        },
        oncePerCharacter = true,
        maxUses = 1,
        tool = "hammer",
        lootActionSound = {"foley/eli_fall_against_table.wav", "foley/eli_grab_frame.wav", "foley/eli_place_frame.wav", "ambient/materials/dinnerplates1.wav"},
        lootFinishSound = "foley/alyx_hug_eli.wav",
    },
}