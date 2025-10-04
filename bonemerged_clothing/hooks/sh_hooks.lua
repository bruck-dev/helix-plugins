
-- disables smoking if the player has a mouth or full-face item equipped
function PLUGIN:CanSmoke(client)
    for _, v in ipairs(client:GetCharacter():GetWornItems()) do
        if isstring(v.outfitCategory) and (v.outfitCategory == "mouth" or v.outfitCategory == "face") then
            return false
        elseif istable(v.outfitCategory) then
            for _, v in ipairs(v.outfitCategory) do
                if v == "mouth" or v == "face" then
                    return false
                end
            end
        end
    end
end