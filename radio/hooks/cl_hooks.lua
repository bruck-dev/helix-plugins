
local PLUGIN = PLUGIN

-- wipes all frequency tracking from stationary radio ents when the player loads a new character
function PLUGIN:CharacterLoaded(character)
	for _, radio in ipairs(ents.FindByClass("ix_radio_*")) do
        radio.canCurrentlyHear = nil
    end
end

-- integration with my ambient music plugin to block ambient tracks when listening to the radio
function PLUGIN:CanPlayAmbientMusic(client)
    if client.radioStations and next(client.radioStations) != nil then
        return false
    end
end

-- integration for my 3DText edit
do
    function PLUGIN:ShouldChatMessageDisplay(speaker, messageInfo)
        local chatType = messageInfo.chatType
        return string.find(chatType, "eavesdrop")
    end
    
    function PLUGIN:GetChatMessageDisplayText(speaker, messageInfo, truncated)
        local chatType = messageInfo.chatType
        if string.find(chatType, "eavesdrop_lang") then
            local lang = messageInfo.data and messageInfo.data.language
            if lang then
                local char = LocalPlayer():GetCharacter()
                if !char:HasLanguage(lang) then
                    return string.format("** Says something unintelligible over the radio in %s.", lang)
                else
                    return truncated
                end
            end
        end
    end

    -- repurposed from chat display to display messages over valid frequency connected radios
    local radioMessages = {}
    function PLUGIN:MessageReceived(speaker, messageInfo)
        if ix.option.Get("chatDisplayEnabled", false) then
            if (IsValid(speaker) and speaker == LocalPlayer()) and !ix.option.Get("chatDisplayOwnDisplayEnabled", true) then
                return
            end

            if !(string.find(messageInfo.chatType, "radio") and !string.find(messageInfo.chatType, "eavesdrop")) then return end
    
            local client = LocalPlayer()
            for _, entity in ipairs(ents.FindByClass("ix_radio_*")) do
                if !entity:GetEnabled() then continue end
                if entity:GetFrequency() != messageInfo.data.frequency and messageInfo.data.frequency != "all" then continue end
                if !client:IsLineOfSightClear(entity) then continue end
        
                local dist = client:GetPos():DistToSqr(entity:GetPos())
                local range = ix.config.Get("radioStationListenRange", 384)
                if dist > range * range then continue end
        
                local text = messageInfo.text
                local maxLen = ix.option.Get("chatDisplayLength", 256)
                local truncated = #text > maxLen and text:sub(1, maxLen) .. "..." or text
                local duration = math.max(2, (#truncated * ix.option.Get("chatDisplayDurationPerSymbol", 0.3) / 2))
                local class = ix.chat.classes[messageInfo.chatType]
        
                radioMessages[entity] = {
                    text = "\"<:: " .. truncated .. " ::>\"",
                    font = (class and ((class.GetFont and class:GetFont(speaker, messageInfo.text, messageInfo.data)) or class.font)) or "ixChatFont",
                    color = (class and ((class.GetColor and class:GetColor(speaker, messageInfo.text)) or class.color)) or ix.config.Get("chatColor") or color_white,
                    fadeTime = duration,
                }
            end
        end
    end
    
    function PLUGIN:HUDPaint()
        if !ix.option.Get("chatDisplayEnabled", false) then return end
        if !next(radioMessages) then return end

        local client = LocalPlayer()
        if !client:GetCharacter() then return end
    
        local toRem = {}
        local scrW, scrH = ScrW(), ScrH()
        local halfWidth, halfHeight = scrW * 0.5, scrH * 0.5
        local plyPos = client:EyePos()
    
        for entity, v in pairs(radioMessages or {}) do
            if !IsValid(entity) then
                table.insert(toRem, entity)
                continue
            end
    
            local worldPos = entity:GetPos() + Vector(0, 0, entity:BoundingRadius() + 0.5)
            local pos = worldPos:ToScreen()
            if !pos.visible then
                v.fadeTime = v.fadeTime - FrameTime()
                if v.fadeTime <= 0 then table.insert(toRem, entity) end
                continue
            end
    
            local distSqr = plyPos:DistToSqr(worldPos)
            local range = ix.config.Get("radioStationListenRange", 384)
            local rangeSqr = range * range
    
            if distSqr > rangeSqr then
                table.insert(toRem, entity)
                continue
            end
    
            local camMult = math.Clamp(1 - math.Distance(halfWidth, halfHeight, pos.x, pos.y) / scrW * 1.5, 0, 1)
            local distanceMult = 1 - (distSqr / rangeSqr)
            local alpha = (!client:IsLineOfSightClear(entity) and 0) or (!entity:GetEnabled() and 0) or (255 * camMult * distanceMult * math.min(v.fadeTime, 1))
    
            local font = v.font
            local color = ColorAlpha(v.color, alpha)
    
            surface.SetFont(font)
            local lines = ix.util.WrapText(v.text, scrW * 0.2, font) or {}
            local _, lineH = surface.GetTextSize(v.text)
            local offset = 4
            local curY = pos.y - ((lineH + offset) * #lines) / 2
    
            for _, line in ipairs(lines) do
                local w, h = surface.GetTextSize(line)
                draw.SimpleTextOutlined(line, font, pos.x - w / 2, curY, color, nil, nil, 1, Color(0, 0, 0, alpha))
                curY = curY + h + offset
            end
    
            v.fadeTime = v.fadeTime - FrameTime()
            if v.fadeTime <= 0 then
                table.insert(toRem, entity)
            end
        end
    
        for _, entity in ipairs(toRem) do
            radioMessages[entity] = nil
        end
    end
end