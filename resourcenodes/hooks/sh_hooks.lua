
local PLUGIN = PLUGIN

function PLUGIN:InitializedPlugins()
    for _, path in ipairs(self.paths or {}) do
        ix.resourcenodes.LoadFromDir(path.."/resourcenodes")
    end
end