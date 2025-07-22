
local CHAR = ix.meta.character

function CHAR:TFA_HasAttachment(attID)
    if ix.config.Get("freeAttachments(Tfa)", false) or ix.tfa.freeAttachments[attID] then return true end

    local itemID = ix.tfa.GetItemForAttachment(attID)
    
    if itemID then
        return self:GetInventory():HasItem(itemID)
    else
        return false
    end
end

function CHAR:TFA_TakeAttachment(attID)
    if SERVER then
        if ix.config.Get("freeAttachments(Tfa)", false) then return end

        local itemID = ix.tfa.GetItemForAttachment(attID)
        if itemID then
            local item = self:GetInventory():HasItem(itemID)
            
            if item then
                item:Remove()
                return true
            end
        end
    end
end

function CHAR:TFA_GiveAttachment(attID)
    if SERVER then
        if ix.config.Get("freeAttachments(Tfa)", false) then return end

        local itemID = ix.tfa.GetItemForAttachment(attID)
        if itemID then
            local item = ix.item.Get(itemID)
            
            if item then
                if (!self:GetInventory():Add(itemID)) then
                    ix.item.Spawn(itemID, self:GetPlayer())
                end
                
                return true
            end
        end
    end
end