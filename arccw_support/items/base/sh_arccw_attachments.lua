ITEM.name = "ArcCW Attachment"
ITEM.description = "ArcCW attachment base."
ITEM.category = "ArcCW Attachments"
ITEM.model = "models/props_junk/cardboard_box004a.mdl"
ITEM.width = 1
ITEM.height = 1

ITEM.isArcCWAttachment = true
ITEM.att = "undefined"              -- id of the attachment this item is linked to
ITEM.tool = nil                     -- item unique id of the tool needed to use the attachment on a weapon

if (CLIENT) then
    function ITEM:PopulateTooltip(tooltip)
        if self.tool then
            local font = "ixSmallFont"
            local tool = tooltip:AddRowAfter("description", "tool")

            local text = "Required Tool: "
            local tool = ix.item.Get(self.tool)
            if tool then
                text = text .. item:GetName()
            else
                text = text .. self.tool
            end

            tool:SetText(text)
            tool:SetFont(font)
            tool:SizeToContents()
        end
    end
end

function ITEM:GetModel()
    if self.model == "models/error.mdl" then
        return "models/props_junk/cardboard_box004a.mdl"
    else
        return self.model
    end
end

function ITEM:GetAttachment()
    if self.att then
        local atttbl = ArcCW.AttachmentTable[self.att]
        if atttbl then
            if atttbl.InvAtt then
                return atttbl.InvAtt, atttbl
            else
                return self.att, atttbl
            end
        end
    end

    return "undefined", nil
end

function ITEM:HasTool(client)
    if self.tool == nil then return true end
    if ix.config.Get("freeAttachments(ArcCW)", false) then return true end
    
    return client:GetCharacter():GetInventory():HasItem(self.tool)  -- just a note: hasitem does NOT check bags
end