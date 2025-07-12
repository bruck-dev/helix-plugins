
local PLUGIN = PLUGIN

-- Called when smoking is started to reduce the timer.
function PLUGIN:StartSmoking(character, item)
    local client = character:GetPlayer()
    local timerName = string.format("%s%s", "SmokeTick", item.id)
    self:DestroyTimer(client, timerName)

    client:SetNetVar("smoking", item.id)
    item:SetData("startTime", item:GetTime())
    item:OnStartSmoke(client)

    client:RemovePart(item.uniqueID)
    client:AddPart(item.uniqueID, self)

    timer.Create(timerName, 1, 0, function()
        if !item or !IsValid(client) then
            self:DestroyTimer(client, timerName)
            return
        end

        local newTime = math.Clamp(item:GetTime() - 1, 0, 99999)
        item:SetData("time", newTime)

        -- Do effects every effectInterval ticks by comparing when we started to how long is left
        local interval = item.effectInterval
        if interval != nil and isnumber(interval) and interval > 0 then
            interval = math.floor(interval)
            if (item.time - newTime) % interval == 0 then
                item:DoSmokingEffects(character:GetPlayer())
            end
        end

        if(newTime <= 0) then
            item:Remove()
            self:DestroyTimer(client, timerName)
        end
    end)
end

function PLUGIN:DestroyTimer(client, timerName)
    if(timer.Exists(timerName)) then
        timer.Destroy(timerName)
    end

    if client and IsValid(client) then
        client:SetNetVar("smoking", nil)
    end
end

function PLUGIN:PlayerLoadedCharacter(client, char, prevChar)
    client:SetNetVar("smoking", nil)

    local is, smokable = char:IsSmoking()
    if is and smokable then
        self:StartSmoking(char, smokable)
    end
end