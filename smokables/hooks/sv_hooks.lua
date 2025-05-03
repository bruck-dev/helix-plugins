
local PLUGIN = PLUGIN

-- Called when smoking is started to reduce the timer.
function PLUGIN:StartSmoking(character, item)
    local smokeTick = string.format("%s%s", "SmokeTick", character:GetID())

    self:DestroyTimer(character)

    timer.Create(smokeTick, 1, 0, function()
        if(!item) then
            self:DestroyTimer(character)
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
            self:DestroyTimer(character)
        end
    end)
end

function PLUGIN:DestroyTimer(character)
    local smokeTick = string.format("%s%s", "SmokeTick", character:GetID())

    if(timer.Exists(smokeTick)) then
        timer.Destroy(smokeTick)
    end
end