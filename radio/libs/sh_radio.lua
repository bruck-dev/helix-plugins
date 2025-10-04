
local PLUGIN = PLUGIN

ix.radio = {}
ix.radio.stationaryRadios = {}          
ix.radio.stationaryRadios.stored = {}   -- stored stationary radio tables
ix.radio.stations = {}
ix.radio.stations.stored = {}           -- stored station tables

if SERVER then
    ix.radio.stations.instances = {}    -- live status of each station
end

function ix.radio.stations.LoadFromDir(directory)
    files, folders = file.Find(directory.."/*", "LUA")

    -- load from root
    for _, v in ipairs(files) do
        if string.find(v, ".lua") then
            local niceName = v:sub(4, -5)
            
            STATION = setmetatable({uniqueID = niceName}, ix.meta.radioStation)

            if !ix.radio.stations.FindByFrequency(STATION.frequency) then
                ix.util.Include(directory.."/"..v, "shared")
                ix.radio.stations.stored[niceName] = STATION
                ix.radio.stations.stored[niceName]:Register()

                if SERVER and !STATION.isStream then
                    ix.radio.stations.instances[niceName] = {}
                    ix.radio.stations.stored[niceName]:InitializeTimer()
                end
            end

            STATION = nil
        end
    end

    -- load from subfolder
    for _, v in ipairs(folders) do
        for _, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do
            local niceName = v2:sub(4, -5)
        
            STATION = setmetatable({uniqueID = niceName}, ix.meta.radioStation)
    
            if !ix.radio.stations.FindByFrequency(STATION.frequency) then
                ix.util.Include(directory.."/"..v.."/" .. v2, "shared")
                ix.radio.stations.stored[niceName] = STATION
                ix.radio.stations.stored[niceName]:Register()

                if SERVER and !STATION.isStream then
                    ix.radio.stations.instances[niceName] = {}
                    ix.radio.stations.stored[niceName]:InitializeTimer()
                end
            end
    
            STATION = nil
        end
    end
end

function ix.radio.stationaryRadios.LoadFromDir(directory)
    files, folders = file.Find(directory.."/*", "LUA")

    -- load from root
    for _, v in ipairs(files) do
        if string.find(v, ".lua") then
            local niceName = v:sub(4, -5)

            RADIO = setmetatable({
                uniqueID = niceName
            }, ix.meta.stationaryRadio)
                ix.util.Include(directory.."/"..v, "shared")

                if (!scripted_ents.Get("ix_radio_"..niceName)) then
                    local RADIO_ENT = scripted_ents.Get("ix_radio")
                    RADIO_ENT.PrintName = RADIO.name
                    RADIO_ENT.Description = RADIO.description
                    RADIO_ENT.uniqueID = niceName
                    RADIO_ENT.Spawnable = true
                    RADIO_ENT.AdminOnly = true

                    RADIO_ENT.TwoWay = RADIO.twoWay
                    RADIO_ENT.EnableStations = RADIO.enableStations
                    RADIO_ENT.CanGarble = RADIO.canGarble
                    RADIO_ENT.FrequencyBand = RADIO.frequencyBand

                    scripted_ents.Register(RADIO_ENT, "ix_radio_"..niceName)
                end

                ix.radio.stationaryRadios.stored[niceName] = RADIO
            RADIO = nil
        end
    end

    -- load from subfolder
    for _, v in ipairs(folders) do
        for _, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do
            local niceName = v2:sub(4, -5)
        
            RADIO = setmetatable({
                uniqueID = niceName
            }, ix.meta.stationaryRadio)
                ix.util.Include(directory.."/"..v.."/"..v2, "shared")

                if (!scripted_ents.Get("ix_radio_"..niceName)) then
                    local RADIO_ENT = scripted_ents.Get("ix_radio")
                    RADIO_ENT.PrintName = RADIO.name
                    RADIO_ENT.Description = RADIO.description
                    RADIO_ENT.uniqueID = niceName
                    RADIO_ENT.Spawnable = true
                    RADIO_ENT.AdminOnly = true

                    RADIO_ENT.TwoWay = RADIO.twoWay
                    RADIO_ENT.EnableStations = RADIO.enableStations
                    RADIO_ENT.CanGarble = RADIO.canGarble
                    RADIO_ENT.FrequencyBand = RADIO.frequencyBand

                    scripted_ents.Register(RADIO_ENT, "ix_radio_"..niceName)
                end

                ix.radio.stationaryRadios.stored[niceName] = RADIO
            RADIO = nil
        end
    end
end

function ix.radio.stations.Get(key)
    return ix.radio.stations.stored[key] or ix.radio.stations.FindByFrequency(key) or ix.radio.stations.FindByName(key)
end

function ix.radio.stations.FindByFrequency(frequency)
    if isnumber(frequency) then
        frequency = string.format("%.1f", frequency)
    end
    
    if !tonumber(frequency) then return nil end

    for k, v in pairs(ix.radio.stations.stored) do
        if string.format("%.1f", v.frequency) == frequency then
            return ix.radio.stations.stored[k]
        end
    end

    return nil
end

function ix.radio.stations.FindByName(name)
    name = name:lower()

    for k, v in pairs(ix.radio.stations.stored) do
        if string.find(v.name:lower(), name) then
            return ix.radio.stations.stored[k]
        end
    end

    return nil
end

hook.Add("DoPluginIncludes", "ixRadio", function(path, pluginTable)
    if (!PLUGIN.paths) then
        PLUGIN.paths = {}
    end

    table.insert(PLUGIN.paths, path)
end)