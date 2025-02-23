
local CHAR = ix.meta.character

-- customize this to your liking - currently, it checks if CHAR:HasProfession() exists and runs it if it does
function CHAR:HasNodeProfession(profession)
    return false or (self.HasProfession and self:HasProfession(profession))
end