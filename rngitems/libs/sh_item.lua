
ix.item = ix.item or {}

-- adds the "OnItemInstanced" hook at the end of the instance method
function ix.item.Instance(index, uniqueID, itemData, x, y, callback, characterID, playerID)
    if (!uniqueID or ix.item.list[uniqueID]) then
        itemData = istable(itemData) and itemData or {}

        local query = mysql:Insert("ix_items")
            query:Insert("inventory_id", index)
            query:Insert("unique_id", uniqueID)
            query:Insert("data", util.TableToJSON(itemData))
            query:Insert("x", x)
            query:Insert("y", y)

            if (characterID) then
                query:Insert("character_id", characterID)
            end

            if (playerID) then
                query:Insert("player_id", playerID)
            end

            query:Callback(function(result, status, lastID)
                local item = ix.item.New(uniqueID, lastID)

                if (item) then
                    item.data = table.Copy(itemData)
                    item.invID = index
                    item.characterID = characterID
                    item.playerID = playerID

                    if (callback) then
                        callback(item)
                    end

                    if (item.OnInstanced) then
                        item:OnInstanced(index, x, y, item)
                    end

                    hook.Run("OnItemInstanced", item)
                end
            end)
        query:Execute()
    else
        ErrorNoHalt("[Helix] Attempt to give an invalid item! (" .. (uniqueID or "nil") .. ")\n")
    end
end