
local PLUGIN = PLUGIN

PLUGIN.name = "Character Physics Sounds"
PLUGIN.description = "Adds support for custom footstep and death sounds per faction or class."
PLUGIN.author = "bruck"

function PLUGIN:PlayerFootstep(client, pos, foot, sound, volume, rf)
    if client and client:GetCharacter() then
        local faction = ix.faction.Get(client:Team())
        local class
        if client:GetCharacter():GetClass() then
            class = ix.class.list[client:GetCharacter():GetClass()]
        end

        -- check class first
        if class then
            if client:IsRunning() and class.runSounds then
                client:EmitSound(class.runSounds[foot])
                return true
            elseif class.walkSounds then
                client:EmitSound(class.walkSounds[foot]);
                return true
            end
        end

        -- then check faction
        if faction then
            if client:IsRunning() and faction.runSounds then
                client:EmitSound(faction.runSounds[foot])
                return true
            elseif faction.walkSounds then
                client:EmitSound(faction.walkSounds[foot]);
                return true
            end
        end
    end
end

if SERVER then
    function PLUGIN:GetPlayerDeathSound(client)
        if client and client:GetCharacter() then
            local faction = ix.faction.Get(client:Team())
            local class
            if client:GetCharacter():GetClass() then
                class = ix.class.list[client:GetCharacter():GetClass()]
            end

            if class and class.deathSound then
                local sound = class.deathSound

                if istable(sound) then
                    return sound[math.random(1, #sound)]
                else
                    return sound
                end
            end

            if faction and faction.deathSound then
                local sound = faction.deathSound

                if istable(sound) then
                    return sound[math.random(1, #sound)]
                else
                    return sound
                end
            end
        end
    end

    function PLUGIN:GetPlayerPainSound(client)
        if client and client:GetCharacter() then
            local faction = ix.faction.Get(client:Team())
            local class
            if client:GetCharacter():GetClass() then
                class = ix.class.list[client:GetCharacter():GetClass()]
            end

            if class and class.painSound then
                local sound = class.painSound

                if istable(sound) then
                    return sound[math.random(1, #sound)]
                else
                    return sound
                end
            end

            if faction and faction.painSound then
                local sound = faction.painSound

                if istable(sound) then
                    return sound[math.random(1, #sound)]
                else
                    return sound
                end
            end
        end
    end
end