
local PLUGIN = PLUGIN;

ix.liquids = {}
ix.liquids.stored = {}
ix.liquids.sources = {}

function ix.liquids.LoadFromDir(directory)
    files, folders = file.Find(directory.."/*", "LUA")

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

function ix.liquids.Get(uniqueID)
    return ix.liquids.stored[uniqueID] or nil;
end

function ix.liquids.NameToUniqueID(name)
    return string.gsub(name, " ", "_"):lower();
end

hook.Add("DoPluginIncludes", "ixLiquids", function(path, pluginTable)
    if (!PLUGIN.paths) then
        PLUGIN.paths = {}
    end

    table.insert(PLUGIN.paths, path)
end)

function ix.liquids.RegisterSource(model, data)
    ix.liquids.sources[model:lower()] = data
end

-- returns the volume scaled to the nearest metric unit - 1000mL will become 1L, etc
function ix.liquids.ConvertUnit(vol)
    local units = {
        "mL",
        "L",
        "kL",
        "ML"
    }

    -- no need to rescale mL or the first L
    if vol < 1000 then
        return vol .. " mL"
    end

    local i = 0
    while vol >= 1 do
        vol = vol / 1000
        i = i + 1
    end

    return string.format("%.2f", vol * 1000) .. " " .. units[i]
end