
local PLUGIN = PLUGIN

ix.resourcenodes = ix.resourcenodes or {}
ix.resourcenodes.stored = ix.resourcenodes.stored or {}

function ix.resourcenodes.LoadFromDir(directory)
	files, folders = file.Find(directory.."/*", "LUA")

	-- load from root
	for _, v in ipairs(files) do
		if string.find(v, ".lua") then
			local niceName = v:sub(4, -5)
			RESNODE = setmetatable({
				uniqueID = niceName
			}, ix.meta.resnode)
			ix.util.Include(directory.."/"..v, "shared")

			if (!scripted_ents.Get("ix_resourcenode_"..niceName)) then
				local RESNODE_ENT = scripted_ents.Get("ix_resourcenode")
				RESNODE_ENT.PrintName = RESNODE.name
				RESNODE_ENT.uniqueID = niceName
				RESNODE_ENT.Spawnable = true
				RESNODE_ENT.AdminOnly = true
				scripted_ents.Register(RESNODE_ENT, "ix_resourcenode_"..niceName)
			end

			ix.resourcenodes.stored[niceName] = RESNODE
			RESNODE = nil
		end
	end

	-- load from subfolder
	for _, v in ipairs(folders) do
		for _, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do

			local niceName = v2:sub(4, -5)
			RESNODE = setmetatable({
				uniqueID = niceName
			}, ix.meta.resnode)

			ix.util.Include(directory.."/"..v.."/"..v2, "shared")
	
			if (!scripted_ents.Get("ix_resourcenode_"..niceName)) then
				local RESNODE_ENT = scripted_ents.Get("ix_resourcenode")
				RESNODE_ENT.PrintName = RESNODE.name
				RESNODE_ENT.uniqueID = niceName
				RESNODE_ENT.Spawnable = true
				RESNODE_ENT.AdminOnly = true
				scripted_ents.Register(RESNODE_ENT, "ix_resourcenode_"..niceName)
			end

			ix.resourcenodes.stored[niceName] = RESNODE
			RESNODE = nil
		end
	end
end

hook.Add("DoPluginIncludes", "ixResourceNodes", function(path, pluginTable)
	if (!PLUGIN.paths) then
		PLUGIN.paths = {}
	end

	table.insert(PLUGIN.paths, path)
end)