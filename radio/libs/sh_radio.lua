
local PLUGIN = PLUGIN

ix.radio = {}
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
			
			STATION = setmetatable({uniqueID = niceName}, ix.meta.radiostation)

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
		
			STATION = setmetatable({uniqueID = niceName}, ix.meta.radiostation)
	
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