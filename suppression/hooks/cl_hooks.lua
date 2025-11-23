
local PLUGIN = PLUGIN

local suppression = 0
local suppressed = false

local function readVector()
    local vector = Vector(0, 0, 0)
    vector.x = net.ReadFloat()
    vector.y = net.ReadFloat()
    vector.z = net.ReadFloat()
    return vector
end

-- received when an entity fires
net.Receive("ixSuppressionBullet", function(len)
    local client = LocalPlayer()

    local entity = net.ReadEntity()
    local src = readVector()
    local dir = readVector()
    local maxDist = net.ReadFloat()

    -- dont suppress yourself
    if entity == client or (entity.GetOwner and entity:GetOwner() and entity:GetOwner() == client) then
        return
    end

    -- dont suppress while in a vehicle if the config is disabled
    if !ix.config.Get("enableSuppressionInVehicles", true) and client:InVehicle() then
        return
    end

    -- if a trace from the firing entity intersects with a sphere around the player (starting eye height to make suppression more likely) and they aren't in observer, add additional suppression to the tracker and put them into combat
    if client:Alive() and client:GetMoveType() != MOVETYPE_NOCLIP then
        local pos = client:EyePos()
        local radius = ix.config.Get("suppressionRadius", 96)
        local delta = dir * maxDist
        local int1, int2 = util.IntersectRayWithSphere(src, delta, pos, radius)

        if int1 and int2 then
            local intPos1 = LerpVector(int1, src, src + delta)
            local intPos2 = LerpVector(int2, src, src + delta)
            local dist = util.DistanceToLine(intPos1, intPos2, pos)
            local amount = 0.075 * math.max(0, (1 - dist / radius)) -- 7.5% suppression if hit, scaling down as the distance increases

            suppression = math.Clamp(suppression + amount, 0, 1)
            suppressed = true
        end
    end
end)

-- received when explosive damage is taken
net.Receive("ixSuppressionExplosion", function(len)
    local client = LocalPlayer()
    local amount = net.ReadFloat()

    if !ix.config.Get("enableSuppressionInVehicles", true) and client:InVehicle() then
        return
    end
    
    if client:Alive() and client:GetMoveType() != MOVETYPE_NOCLIP then
        suppression = math.Clamp(suppression + amount, 0, 1)
        suppressed = true
    end
end)

net.Receive("ixSuppressionReset", function(len)
    suppressed = false
    suppression = 0
end)

-- suppression fade think
do
    local nextThink
    hook.Add("Think", "ixSuppressionFade", function()
        if !ix.config.Get("enableSuppression", true) then
            return
        end

        if !LocalPlayer():Alive() then
            return
        end

        if !nextThink then
            nextThink = CurTime()
        end

        if CurTime() >= nextThink then
            if suppressed then -- if actively suppressed then do not subtract any suppression - suppression is set every time a hit or near miss happens nearby, so this is cleared and set regularly
                suppressed = false
                nextThink = CurTime() + ix.config.Get("suppressionFadeDelay", 5)
            elseif suppression > 0 then -- subtract 2.5% suppression while not under fire
                suppression = math.max(suppression - 0.025, 0)
                nextThink = CurTime() + 0.10 -- reduce every 0.10 seconds
            end
        end
    end)
end

-- heartbeat think
do
    local nextBeat
    local currentBeat = {}

    local function playHeartbeat(path, vol)
        -- reschedule to avoid any weird beat
        if currentBeat.sound and currentBeat.path then
            nextBeat = CurTime() + SoundDuration(currentBeat.path)
            currentBeat.sound:Stop()
            currentBeat = {}

            return
        end

        currentBeat.path = path
        currentBeat.sound = CreateSound(LocalPlayer(), path)
        currentBeat.sound:SetSoundLevel(0)
        currentBeat.sound:PlayEx(vol, 100)

        nextBeat = CurTime() + SoundDuration(path)
    end

    local function stopHeartbeat()
        if currentBeat.sound then
            currentBeat.sound:Stop()
            currentBeat = {}
        end
    end

    hook.Add("Think", "ixSuppressionHeartBeat", function()
        if !ix.config.Get("enableSuppressionHeartbeat") then
            return
        end

        if !LocalPlayer():Alive() then
            stopHeartbeat()
        end

        if !nextBeat then
            nextBeat = CurTime()
        end

        if CurTime() >= nextBeat then
            if suppression < 0.10 then
                stopHeartbeat()
            elseif suppression < 0.33 then
                playHeartbeat("player/heartbeat_slow.wav", 0.5)
            elseif suppression < 0.66 then
                playHeartbeat("player/heartbeat_med.wav", 0.75)
            elseif suppression <= 1 then
                playHeartbeat("player/heartbeat_fast.wav", 1)
            end
        end
    end)
end

-- draws the blur + vignette. most of the values here are magic numbers that i dialed in by testing, to my preference. feel free to change, it won't break anything (ymmv)
local vignette = ix.util.GetMaterial("helix/gui/vignette.png")
local hasVignetteMaterial = !vignette:IsError()
function PLUGIN:HUDPaintBackground()
    if !ix.config.Get("enableSuppression", true) then
        return
    end

    local client = LocalPlayer()

    if !client:GetCharacter() then
        return
    end

    if suppression <= 0 then
        return
    end

    local scrW, scrH = ScrW(), ScrH()

    if hasVignetteMaterial then
        local vignetteAlpha = math.min(125 + (255 * suppression), 255) -- start at 125 alpha, max at 255
        surface.SetDrawColor(0, 0, 0, vignetteAlpha)
        surface.SetMaterial(vignette)
        surface.DrawTexturedRect(0, 0, scrW, scrH)
    end

    if suppression >= 0.10 then
        local blurAmount = suppression * 3.5 -- i found this produces a nice feeling curve without being too extreme
        local blurAlpha = math.min(0 + (255 * (suppression - 0.10)), 160) -- capped at 160 alpha. subtract 10% so we start smoothly start at 0.

        ix.util.DrawBlurAt(0, 0, scrW, scrH, blurAmount, nil, blurAlpha)
    end
end

-- clear suppression when a new character is loaded
function PLUGIN:CharacterLoaded(char)
    suppressed = false
    suppression = 0
end