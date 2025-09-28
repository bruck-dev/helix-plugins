
local PLUGIN = PLUGIN

-- run this at the very, very end of all plugin initializations
function PLUGIN:InitializedConfig()
	for _, path in ipairs(self.paths or {}) do
		ix.radio.stations.LoadFromDir(path.."/radiostations")
	end
end

function PLUGIN:InitializedChatClasses()
    -- Primary radio chat classes
    do
        -- Radio Talking
        ix.chat.Register("radio", {
            format = "%s speaks over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                return ix.config.Get("chatRadioColor")
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local can, radio = char:CanHearFrequency(data.frequency)
                if can then
                    if ix.config.Get("garbleRadio", true) and data.garble and speaker then 
                        text = garbleMessage(speaker, text)
                    end

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    text = string.format("<:: %s ::>", text)
                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))

                    local snd = radio:GetReceiveSound()
                    if snd then
                        surface.PlaySound(snd)
                    end
                end
            end,
        })

        -- Radio Whisper
        ix.chat.Register("radio_w", {
            format = "%s whispers over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                local color = ix.config.Get("chatRadioColor")
                return Color(color.r - 35, color.g - 35, color.b - 35)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local can, radio = char:CanHearFrequency(data.frequency)
                if can then
                    if ix.config.Get("garbleRadio", true) and data.garble and speaker then 
                        text = garbleMessage(speaker, text)
                    end

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_w") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    text = string.format("<:: %s ::>", text)
                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))

                    local snd = radio:GetReceiveSound()
                    if snd then
                        surface.PlaySound(snd)
                    end
                end
            end,
        })

        -- Radio Yell
        ix.chat.Register("radio_y", {
            format = "%s yells over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                local color = ix.config.Get("chatRadioColor")
                return Color(color.r + 35, color.g + 35, color.b + 35)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local can, radio = char:CanHearFrequency(data.frequency)
                if can then
                    if ix.config.Get("garbleRadio", true) and data.garble and speaker then 
                        text = garbleMessage(speaker, text)
                    end

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_y") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    text = string.format("<:: %s ::>", text)
                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))

                    local snd = radio:GetReceiveSound()
                    if snd then
                        surface.PlaySound(snd)
                    end
                end
            end,
        })
    end

    -- Eavesdrop radio chat classes
    do
        -- Talking Range
        ix.chat.Register("radio_eavesdrop", {
            format = "%s speaks over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                return ix.chat.classes.ic:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener)
                if speaker == listener then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280)
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                if !char:CanHearFrequency(data.frequency) then
                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))
                end
            end,
        })

        -- Whisper Range
        ix.chat.Register("radio_eavesdrop_w", {
            format = "%s whispers over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                return ix.chat.classes.w:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener)
                if speaker == listener then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280) * 0.25
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                if !char:CanHearFrequency(data.frequency) then
                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop_w") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))
                end
            end,
        })

        -- Yelling Range
        ix.chat.Register("radio_eavesdrop_y", {
            format = "%s yells over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                return ix.chat.classes.y:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener)
                if speaker == listener then
                    return false
                end
                
                local chatRange = ix.config.Get("chatRange", 280) * 2
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                if !char:CanHearFrequency(data.frequency) then
                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop_y") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))
                end
            end,
        })
    end

    if(CLIENT) then
        CHAT_RECOGNIZED = CHAT_RECOGNIZED or {}
        CHAT_RECOGNIZED["radio"] = true
        CHAT_RECOGNIZED["radio_w"] = true
        CHAT_RECOGNIZED["radio_y"] = true
        CHAT_RECOGNIZED["radio_eavesdrop"] = true
        CHAT_RECOGNIZED["radio_eavesdrop_w"] = true
        CHAT_RECOGNIZED["radio_eavesdrop_y"] = true
    end

    if ix.language and ix.language.stored and (next(ix.language.stored) != nil) then
        self:InitializedLanguageClasses()
    end
end

function PLUGIN:InitializedLanguageClasses()
    -- Primary radio chat classes
    do
        -- Radio Talking
        ix.chat.Register("radio_lang", {
            format = "%s speaks in %s over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                return ix.config.Get("chatRadioColor")
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local can, radio = char:CanHearFrequency(data.frequency)
                if can then
                    local language = data.language

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    if (char:HasLanguage(language)) then
                        if ix.config.Get("garbleRadio", true) and data.garble and speaker then 
                            text = garbleMessage(speaker, text)
                        end

                        text = string.format("<:: %s ::>", text)
                        chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))

                        local snd = radio:GetReceiveSound()
                        if snd then
                            surface.PlaySound(snd)
                        end
                    else
                        text = string.format("%s says something unintelligible over the radio in %s.", name, language)
                        chat.AddText(self:GetColor(speaker, text), text)

                        local snd = radio:GetReceiveSound()
                        if snd then
                            surface.PlaySound(snd)
                        end
                    end
                end
            end,
        })

        -- Radio Whisper
        ix.chat.Register("radio_lang_w", {
            format = "%s whispers in %s over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                local color = ix.config.Get("chatRadioColor")
                return Color(color.r - 35, color.g - 35, color.b - 35)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local can, radio = char:CanHearFrequency(data.frequency)
                if can then
                    local language = data.language

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_w") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    if (char:HasLanguage(language)) then
                        if ix.config.Get("garbleRadio", true) and data.garble and speaker then 
                            text = garbleMessage(speaker, text)
                        end

                        text = string.format("<:: %s ::>", text)
                        chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))

                        local snd = radio:GetReceiveSound()
                        if snd then
                            surface.PlaySound(snd)
                        end
                    else
                        text = string.format("%s whispers something unintelligible over the radio in %s.", name, language)
                        chat.AddText(self:GetColor(speaker, text), text)

                        local snd = radio:GetReceiveSound()
                        if snd then
                            surface.PlaySound(snd)
                        end
                    end
                end
            end,
        })

        -- Radio Yell
        ix.chat.Register("radio_lang_y", {
            format = "%s yells in %s over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                local color = ix.config.Get("chatRadioColor")
                return Color(color.r + 35, color.g + 35, color.b + 35)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local can, radio = char:CanHearFrequency(data.frequency)
                if can then
                    local language = data.language

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_y") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    if (char:HasLanguage(language)) then
                        if ix.config.Get("garbleRadio", true) and data.garble and speaker then 
                            text = garbleMessage(speaker, text)
                        end

                        text = string.format("<:: %s ::>", text)
                        chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))

                        local snd = radio:GetReceiveSound()
                        if snd then
                            surface.PlaySound(snd)
                        end
                    else
                        text = string.format("%s yells something unintelligible over the radio in %s.", name, language)
                        chat.AddText(self:GetColor(speaker, text), text)

                        local snd = radio:GetReceiveSound()
                        if snd then
                            surface.PlaySound(snd)
                        end
                    end
                end
            end,
        })
    end

    -- Eavesdrop radio chat classes
    do
        -- Talking Range
        ix.chat.Register("radio_eavesdrop_lang", {
            format = "%s speaks in %s over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                return ix.chat.classes.ic:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener)
                if speaker == listener then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280)
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                if !char:CanHearFrequency(data.frequency) then
                    local language = data.language

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    if (char:HasLanguage(language)) then
                        chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))
                    else
                        text = string.format("%s says something unintelligible over the radio in %s.", name, language)
                        chat.AddText(self:GetColor(speaker, text), text)
                    end
                end
            end,
        })

        -- Whisper Range
        ix.chat.Register("radio_eavesdrop_lang_w", {
            format = "%s whispers in %s over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                return ix.chat.classes.w:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener)
                if speaker == listener then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280) * 0.25
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                if !char:CanHearFrequency(data.frequency) then
                    local language = data.language

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop_w") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    if (char:HasLanguage(language)) then
                        chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))
                    else
                        text = string.format("%s whispers something unintelligible over the radio in %s.", name, language)
                        chat.AddText(self:GetColor(speaker, text), text)
                    end
                end
            end,
        })

        -- Yelling Range
        ix.chat.Register("radio_eavesdrop_lang_y", {
            format = "%s yells in %s over the radio: \"%s\"",
            GetColor = function(self, speaker, text)
                return ix.chat.classes.y:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener)
                if speaker == listener then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280) * 2
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                if !char:CanHearFrequency(data.frequency) then
                    local language = data.language

                    local name = anonymous and
                    L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop_y") or
                    (IsValid(speaker) and speaker:Name() or "Console")

                    if (char:HasLanguage(language)) then
                        chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))
                    else
                        text = string.format("%s yells something unintelligible over the radio in %s.", name, language)
                        chat.AddText(self:GetColor(speaker, text), text)
                    end
                end
            end,
        })
    end

    if(CLIENT) then
        CHAT_RECOGNIZED = CHAT_RECOGNIZED or {}
        CHAT_RECOGNIZED["radio_lang"] = true
        CHAT_RECOGNIZED["radio_lang_w"] = true
        CHAT_RECOGNIZED["radio_lang_y"] = true
        CHAT_RECOGNIZED["radio_eavesdrop_lang"] = true
        CHAT_RECOGNIZED["radio_eavesdrop_lang_w"] = true
        CHAT_RECOGNIZED["radio_eavesdrop_lang_y"] = true
    end
end

function garbleMessage(speaker, text)
    local maxRadioRange = ix.config.Get("chatRange", 280) * ix.config.Get("radioRangeMult", 100)
    local dist = LocalPlayer():GetPos():Distance(speaker:GetPos())

    local maxScaleGarbleFrac = 72.5 -- ix.config.Get("garbleMaxFrac",60) -- Maximum percent garbling at maximum radio distance
    local normDist = dist / maxRadioRange -- math.min(1, (dist / maxRadioRange))
    local quadratic = normDist^2 -- Quadratic, inverse square law
    local log2cal = 0.3 -- Approx. Log10(2)

    local logarithmic = normDist^(1/3)*( log2cal / (math.log10(1/normDist) + log2cal) ) -- Logarithmic, signal strength
    local hybrid = 0.5*(normDist + normDist^8) -- Quadratic/logarithmic hybrid, worse at close range but better at long range
    local lowest = 0.5*(normDist^2 + normDist^9) -- Better than hybrid model at all ranges with similar long range decay to quadratic

    local models = {quadratic,logarithmic,hybrid,lowest}
    local distModel = models[ix.config.Get("radioDecayModel",3)]

    frac = math.max(0, (maxScaleGarbleFrac * distModel )) -- Original garbling fraction

    if LocalPlayer():IsLineOfSightClear(speaker) then -- If you can see them, you get a bonus
        frac = 0.5 * frac
    elseif (!isOutdoors(speaker) or !isOutdoors(LocalPlayer())) then -- Indoors stuff
        frac = frac * (1 + (5/100)*math.random()) -- First penalty
        frac = numTraces(speaker,LocalPlayer(),frac,0.5) -- Penalty for each trace
    end

    local frac = math.min(math.max(0, frac), 100)

    text = mangleString(text, frac)

    return text
end

function mangleString(str, pct)
    local limit = pct/100
    local last
    return (string.gsub(str, ".", function(c)
        if not c:match("%W") and math.random() < limit*((last and 3 or c:match("[AEIOUaeiou]")) and 1.5 or 0.5) then
            last = true
            return "-"
        end
        last = false
    end))
end

function isOutdoors(target)
    local tr = util.TraceLine( util.GetPlayerTrace(target,target:GetUp()) )

    return tr.HitSky
end

function numTraces(t1,t2, stFrac, incrementFrac)
    local hits = 0
    local st,en = t1:GetPos(),t2:GetPos()

    local curTrace
    local frac = 1
    local retFrac = stFrac
    local increFrac = (incrementFrac / 100) --0.005
    --local endPos = Vector(0,0,0)
    local holder = {}
    local data = {}
        data.start = st
        data.endpos = en
        data.filter = {t1}
        data.mask = MASK_ALL

    local curHit
    local multiplier = 64
    local tries,maxTries = 0,100
    while curHit != data.endpos do
        tries = tries+1
        curTrace = util.TraceLine(data)
        curHit = curTrace.HitPos
        if data.start == curHit then
            data.start = data.start + ( multiplier*curTrace.Normal )
        else
            data.start = curHit
        end
        hits = hits+1
        frac = frac + increFrac
        retFrac = retFrac*frac
        if tries >= maxTries then
            retFrac = stFrac * (1 + stFrac*math.random())
            break
        end
    end
    return retFrac
end