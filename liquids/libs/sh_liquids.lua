
local PLUGIN = PLUGIN

ix.liquids = {}
ix.liquids.stored = {}
ix.liquids.sources = {}

-- returns the volume scaled to the nearest metric unit - 1000mL will become 1L, etc
function ix.liquids.ConvertUnit(vol)
    vol = tonumber(vol)
    if !vol or vol <= 0 then
        return "0.00", "mL"
    end

    if vol >= 1 and vol < 1000 then
        return string.format("%.2f", vol), "mL"
    end

    local units = {"mL", "L", "kL", "ML"}
    local index = math.Clamp(math.floor(math.log(vol, 1000)) + 1, 1, #units)
    local scaled = vol / (1000 ^ (index - 1))

    return string.format("%.2f", scaled), units[index]
end

-- display a given volume as a specific unit
function ix.liquids.ConvertToUnit(vol, unit)
    local units = {
        ["nL"] = 0.000001,
        ["µL"] = 0.001,
        ["mL"] = 1,
        ["cL"] = 10,
        ["dL"] = 100,
        ["L"] = 1000,
        ["daL"] = 10000,
        ["hL"] = 100000,
        ["kL"] = 1000000,
        ["ML"] = 1000000000,
    }

    if unit == "uL" then unit = "µL" end
    local div = units[unit]
    if !div then
        return vol, "mL"
    end

    return vol / div, unit
end

function ix.liquids.LoadFromDir(directory)
    local files, folders = file.Find(directory.."/*", "LUA")

    -- load from root
    for _, v in ipairs(files) do
        if string.find(v, ".lua") then
            local niceName = v:sub(4, -5)
            
            LIQUID = setmetatable({uniqueID = niceName}, ix.meta.liquid)

            ix.util.Include(directory.."/"..v, "shared")
            ix.liquids.stored[niceName] = LIQUID
            ix.liquids.stored[niceName]:Register()

            LIQUID = nil
        end
    end

    -- load from subfolder
    for _, v in ipairs(folders) do
        for _, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do
            local niceName = v2:sub(4, -5)
        
            LIQUID = setmetatable({uniqueID = niceName}, ix.meta.liquid)
    
            ix.util.Include(directory.."/"..v.."/"..v2, "shared")
            ix.liquids.stored[niceName] = LIQUID
            ix.liquids.stored[niceName]:Register()
    
            LIQUID = nil
        end
    end
end

function ix.liquids.FindByName(liquid)
    liquid = liquid:lower()

    for k, v in pairs(ix.liquids.stored) do
        if (liquid:find(v.name:lower())) then
            return ix.liquids.stored[k]
        end
    end

    return nil
end

function ix.liquids.Get(key)
    if !key then return end
    
    return ix.liquids.stored[key] or ix.liquids.FindByName(key)
end

function ix.liquids.NameToUniqueID(name)
    return string.gsub(name, " ", "_"):lower()
end

function ix.liquids.RegisterSource(model, data)
    ix.liquids.sources[model:lower()] = data
end

hook.Add("DoPluginIncludes", "ixLiquids", function(path, pluginTable)
    if (!PLUGIN.paths) then
        PLUGIN.paths = {}
    end

    table.insert(PLUGIN.paths, path)
end)
