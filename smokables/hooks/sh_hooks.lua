
local PLUGIN = PLUGIN

-- Use this hook to add custom disable conditions in other plugins or the schema. Called via hook.Run(), so don't overwrite.
function PLUGIN:CanSmoke(client)
    if client:IsRestricted() then
        return false
    end
end