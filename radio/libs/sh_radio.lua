
local PLUGIN = PLUGIN

ix.radio = {}
ix.radio.stationaryRadios = {}          
ix.radio.stationaryRadios.stored = {}   -- stored stationary radio tables
ix.radio.stations = {}
ix.radio.stations.stored = {}           -- stored station tables

if SERVER then
    ix.radio.stations.instances = {}    -- live status of each station
end

function ix.radio.ConvertUnit(freq)
    freq = tonumber(freq)
    if !freq or freq <= 0 then return "0.0", "MHz" end

    if freq >= 1 and freq < 1000 then
        return string.format("%.1f", freq), "MHz"
    end

    local units = {"Hz", "kHz", "MHz", "GHz", "THz"}
    local hz = freq * 1000000 -- normalize to hz
    local index = math.Clamp(math.floor(math.log(hz, 1000)) + 1, 1, #units)
    local scaled = hz / (1000 ^ (index - 1))

    return string.format("%.1f", scaled), units[index]
end

function ix.radio.stations.LoadFromDir(directory)
    local files, folders = file.Find(directory.."/*", "LUA")

    -- load from root
    for _, v in ipairs(files) do
        if string.find(v, ".lua") then
            local niceName = v:sub(4, -5)
            
            STATION = setmetatable({uniqueID = niceName}, ix.meta.radioStation)

            if !ix.radio.stations.FindByFrequency(STATION.frequency) then
                ix.util.Include(directory.."/"..v, "shared")
                ix.radio.stations.stored[niceName] = STATION
                ix.radio.stations.stored[niceName]:Register()

                if SERVER then
                    ix.radio.stations.instances[niceName] = {
                        frequency = ix.radio.stations.stored[niceName]:GetFrequency(),
                    }
                    ix.radio.stations.stored[niceName]:InitializeTimers()
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

                if SERVER then
                    ix.radio.stations.instances[niceName] = {
                        frequency = ix.radio.stations.stored[niceName]:GetFrequency(),
                    }
                    ix.radio.stations.stored[niceName]:InitializeTimers()
                end
            end
    
            STATION = nil
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

function ix.radio.stationaryRadios.LoadFromDir(directory)
    local files, folders = file.Find(directory.."/*", "LUA")

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
                    RADIO_ENT.TransmitPower = RADIO.transmitPower or 1
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
                    RADIO_ENT.TransmitPower = RADIO.transmitPower or 1
                    RADIO_ENT.FrequencyBand = RADIO.frequencyBand

                    scripted_ents.Register(RADIO_ENT, "ix_radio_"..niceName)
                end

                ix.radio.stationaryRadios.stored[niceName] = RADIO
            RADIO = nil
        end
    end
end

if SERVER then
    function ix.radio.FrequencyJoin(client, frequency)
        if !client.frequencies then return end

        local radio = client.frequencies[frequency]
        if !radio then return end
        if !isentity(radio) then radio = radio.id end

        net.Start("ixRadioFrequencyJoin")
            net.WriteString(frequency)
            net.WriteType(radio)
        net.Send(client)
    end
    
    function ix.radio.FrequencyLeave(client, frequency)
        if !client.frequencies then return end
        
        local radio = client.frequencies[frequency]
        if !radio then return end

        net.Start("ixRadioFrequencyLeave")
            net.WriteString(frequency)
        net.Send(client)
    end

    function ix.radio.FrequencySync(client)
        local frequencies = {}
        for freq, radio in pairs(client.frequencies or {}) do
            if isentity(radio) then
                frequencies[freq] = radio
            else
                frequencies[freq] = radio.id
            end
        end

        net.Start("ixRadioFrequencySync")
            net.WriteTable(frequencies)
        net.Send(client)
    end

    -- sets or clears a station's host stationary radio. pass no radio to clear it
    function ix.radio.stations.SetHostRadio(radio, frequency)
        if radio and !radio.TwoWay then
            return false
        end

        local station = ix.radio.stations.Get(frequency)
        if !station then
            return false
        end

        local instance = ix.radio.stations.instances[station.uniqueID]
        if !instance then
            return false
        end

        if instance.host then
            instance.host.isHost = nil
        end

        if radio then
            radio.isHost = true
        end
        instance.host = radio

        PLUGIN:SaveData()

        return true
    end

    function ix.radio.stations.GetHostRadio(frequency)
        local station = ix.radio.stations.Get(frequency)
        if !station then
            return nil
        end

        local instance = ix.radio.stations.instances[station.uniqueID]
        if !instance then
            return nil
        end

        return instance.host
    end
end

hook.Add("DoPluginIncludes", "ixRadio", function(path, pluginTable)
    if (!PLUGIN.paths) then
        PLUGIN.paths = {}
    end

    table.insert(PLUGIN.paths, path)
end)