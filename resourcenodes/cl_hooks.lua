
function PLUGIN:PopulateResNodeTooltip(tooltip, resNode, canHarvest)

    local name = tooltip:AddRow("name")
    local nameText = resNode.name
    
    if (resNode.fullName and canHarvest) then
        nameText = resNode.fullName
    elseif resNode.emptyName and !canHarvest then
        nameText = resNode.emptyName
    end

    name:SetImportant()
    name:SetText(nameText)
    name:SetMaxWidth(math.max(name:GetMaxWidth(), ScrW() * 0.5))
    name:SizeToContents()

    local description = tooltip:AddRow("description")
    description:SetText(resNode.GetDescription and resNode:GetDescription() or L(resNode.description))
    description:SizeToContents()

    if (resNode.PopulateTooltip) then
        resNode:PopulateTooltip(tooltip)
    end
end