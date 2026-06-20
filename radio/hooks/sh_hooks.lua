
local PLUGIN = PLUGIN

-- run this at the very, very end of all plugin initializations. loads radios and stations.
function PLUGIN:InitializedConfig()
    for _, path in ipairs(self.paths or {}) do
        ix.radio.stations.LoadFromDir(path.."/radiostations")
        ix.radio.stationaryRadios.LoadFromDir(path.."/radios")
    end
end

-- corrupts the given message relative to the corruption percentage (decimal)
local function corruptMessage(text, corruption)
    if corruption <= 0 then
        return text
    end

    -- interference words
    local inter = {"*BZZT*", "*KSSH*", "*KZZT*", "*SHHH*", "*BZZZT*"}
    local words = string.Explode(" ", text)
    local result = {}

    -- Set probabilities based on corruption thresholds
    local cutChance, dropoutChance
    if corruption < 0.2 then
        cutChance = 0
        dropoutChance = 0
    elseif corruption < 0.3 then
        cutChance = 0.10
        dropoutChance = 0
    elseif corruption < 0.5 then
        cutChance = 0.25
        dropoutChance = 0.05
    elseif corruption < 0.7 then
        cutChance = 0.40
        dropoutChance = 0.25
    elseif corruption < 0.8 then
        cutChance = 0.8
        dropoutChance = 0.5
    else
        cutChance = 0.9
        dropoutChance = 0.75
    end

    for i, word in ipairs(words) do
        -- replace word with interference
        if math.random() < dropoutChance then
            table.insert(result, inter[math.random(#inter)])
        else
            -- cut start or end chars off
            local length = #word
            if length > 1 and math.random() < cutChance then
                local base = math.min(0.4 + (length / 12), 0.90)
                local min = base * (1 - cutChance * 0.33)
                local keepFrac = math.max(min * math.random(0.85, 1.0), min)

                local cut = math.floor(length * keepFrac * math.random(0.8, 1.2))
                cut = math.Clamp(cut, 1, length - 1)

                if math.random() < 0.5 then
                    table.insert(result, string.sub(word, 1, cut) .. string.rep("—", length - cut))
                else
                    local start = math.max(length - cut + 1, 1)
                    table.insert(result, string.rep("—", start - 1) .. string.sub(word, start))
                end
            else
                -- unchanged
                table.insert(result, word)
            end
        end
    end

    return table.concat(result, " ")
end

-- determines radio strength, and corrupts the passed message if needed
local function garbleMessage(speaker, text, pwr)
    local listener = LocalPlayer()
    pwr = pwr or 1

    local maxRange = ix.config.Get("chatRange", 280) * ix.config.Get("radioRangeMult", 100)

    local dist = speaker:GetPos():Distance(listener:GetPos())
    local distFactor = 1 - 0.85 * (math.Clamp(dist / maxRange, 0, 1) ^ 2)

    local losFactor = speaker:IsLineOfSightClear(listener) and 1.25 or 1
    local strength = math.Clamp(distFactor * losFactor * pwr, 0, 1)

    if strength < 1 then
        return corruptMessage(text, 1 - strength)
    else
        return text
    end
end

-- initializes all radio chat classes, including eavesdrops
function PLUGIN:InitializedChatClasses()
    -- Primary radio chat classes
    do
        -- Radio Talking
        ix.chat.Register("radio", {
            format = "%s speaks over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.ic.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.config.Get("chatRadioColor")
            end,
            CanHear = function(self, speaker, listener, data)
                return listener:GetCharacter():CanHearFrequency(data.frequency)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local radio = char:GetActiveRadio(data.frequency)

                if ix.config.Get("garbleRadio", true) and data.garble and speaker and LocalPlayer() != speaker then 
                    text = garbleMessage(speaker, text, data.power)
                end

                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio") or
                (IsValid(speaker) and speaker:Name() or "Console")

                text = string.format("<:: %s ::>", text)
                chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))

                local snd = radio:GetReceiveSound()
                if snd then
                    if isentity(radio) then
                        radio:EmitSound(snd)
                    else
                        surface.PlaySound(snd)
                    end
                end
            end,
        })

        -- Radio Whisper
        ix.chat.Register("radio_w", {
            format = "%s whispers over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.w.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                local color = ix.config.Get("chatRadioColor")
                return Color(color.r - 35, color.g - 35, color.b - 35)
            end,
            CanHear = function(self, speaker, listener, data)
                return listener:GetCharacter():CanHearFrequency(data.frequency)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local radio = char:GetActiveRadio(data.frequency)

                if ix.config.Get("garbleRadio", true) and data.garble and speaker and LocalPlayer() != speaker then 
                    text = garbleMessage(speaker, text, data.power)
                end

                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio_w") or
                (IsValid(speaker) and speaker:Name() or "Console")

                text = string.format("<:: %s ::>", text)
                chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))

                local snd = radio:GetReceiveSound()
                if snd then
                    if isentity(radio) then
                        radio:EmitSound(snd)
                    else
                        surface.PlaySound(snd)
                    end
                end
            end,
        })

        -- Radio Yell
        ix.chat.Register("radio_y", {
            format = "%s yells over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.y.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                local color = ix.config.Get("chatRadioColor")
                return Color(color.r + 35, color.g + 35, color.b + 35)
            end,
            CanHear = function(self, speaker, listener, data)
                return listener:GetCharacter():CanHearFrequency(data.frequency)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local radio = char:GetActiveRadio(data.frequency)

                if ix.config.Get("garbleRadio", true) and data.garble and speaker and LocalPlayer() != speaker then 
                    text = garbleMessage(speaker, text, data.power)
                end

                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio_y") or
                (IsValid(speaker) and speaker:Name() or "Console")

                text = string.format("<:: %s ::>", text)
                chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))

                local snd = radio:GetReceiveSound()
                if snd then
                    if isentity(radio) then
                        radio:EmitSound(snd)
                    else
                        surface.PlaySound(snd)
                    end
                end
            end,
        })

        -- Station Broadcast
        ix.chat.Register("radio_broadcast", {
            format = "%s broadcasts over the radio: \"%s\"",
            CanSay = function(speaker, text)
                return true
            end,
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.ic.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.config.Get("chatRadioColor")
            end,
            CanHear = function(self, speaker, listener, data)
                return listener:GetCharacter():CanHearFrequency(data.frequency)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local radio = char:GetActiveRadio(data.frequency)

                if ix.config.Get("garbleRadio", true) and data.garble then 
                    text = garbleMessage(nil, text, data.power)
                end

                local info = {
                    chatType = self.uniqueID,
                    text = text,
                    anonymous = anonymous,
                    data = data
                }
                PLUGIN:MessageReceived(nil, info)

                if !data.noChat then
                    text = string.format("<:: %s ::>", text)
                    chat.AddText(self:GetColor(nil, text), string.format(self.format, data.name, text))
                end

                local snd = radio:GetReceiveSound()
                if snd then
                    if isentity(radio) then
                        radio:EmitSound(snd)
                    else
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
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.ic.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.chat.classes.ic:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener, data)
                if speaker == listener then
                    return false
                end

                if listener:GetCharacter():CanHearFrequency(data.frequency) then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280)
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop") or
                (IsValid(speaker) and speaker:Name() or "Console")

                chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))
            end,
        })

        -- Whisper Range
        ix.chat.Register("radio_eavesdrop_w", {
            format = "%s whispers over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.w.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.chat.classes.w:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener, data)
                if speaker == listener then
                    return false
                end

                if listener:GetCharacter():CanHearFrequency(data.frequency) then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280) * 0.25
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop_w") or
                (IsValid(speaker) and speaker:Name() or "Console")

                chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))
            end,
        })

        -- Yelling Range
        ix.chat.Register("radio_eavesdrop_y", {
            format = "%s yells over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.y.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.chat.classes.y:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener, data)
                if speaker == listener then
                    return false
                end

                if listener:GetCharacter():CanHearFrequency(data.frequency) then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280) * 2
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio_eavesdrop_y") or
                (IsValid(speaker) and speaker:Name() or "Console")

                chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, text))
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

-- ditto, but for language plugin support
function PLUGIN:InitializedLanguageClasses()
    -- Primary radio chat classes
    do
        -- Radio Talking
        ix.chat.Register("radio_lang", {
            format = "%s speaks in %s over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.ic.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.config.Get("chatRadioColor")
            end,
            CanHear = function(self, speaker, listener, data)
                return listener:GetCharacter():CanHearFrequency(data.frequency)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local radio = char:GetActiveRadio(data.frequency)
                local language = data.language

                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio") or
                (IsValid(speaker) and speaker:Name() or "Console")

                if (char:HasLanguage(language)) then
                    if ix.config.Get("garbleRadio", true) and data.garble and speaker and LocalPlayer() != speaker then 
                        text = garbleMessage(speaker, text, data.power)
                    end

                    text = string.format("<:: %s ::>", text)
                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))
                else
                    text = string.format("%s says something unintelligible over the radio in %s.", name, language)
                    chat.AddText(self:GetColor(speaker, text), text)
                end

                local snd = radio:GetReceiveSound()
                if snd then
                    if isentity(radio) then
                        radio:EmitSound(snd)
                    else
                        surface.PlaySound(snd)
                    end
                end
            end,
        })

        -- Radio Whisper
        ix.chat.Register("radio_lang_w", {
            format = "%s whispers in %s over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.w.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                local color = ix.config.Get("chatRadioColor")
                return Color(color.r - 35, color.g - 35, color.b - 35)
            end,
            CanHear = function(self, speaker, listener, data)
                return listener:GetCharacter():CanHearFrequency(data.frequency)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local radio = char:GetActiveRadio(data.frequency)
                local language = data.language

                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio_w") or
                (IsValid(speaker) and speaker:Name() or "Console")

                if (char:HasLanguage(language)) then
                    if ix.config.Get("garbleRadio", true) and data.garble and speaker and LocalPlayer() != speaker then 
                        text = garbleMessage(speaker, text, data.power)
                    end

                    text = string.format("<:: %s ::>", text)
                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))
                else
                    text = string.format("%s whispers something unintelligible over the radio in %s.", name, language)
                    chat.AddText(self:GetColor(speaker, text), text)
                end

                local snd = radio:GetReceiveSound()
                if snd then
                    if isentity(radio) then
                        radio:EmitSound(snd)
                    else
                        surface.PlaySound(snd)
                    end
                end
            end,
        })

        -- Radio Yell
        ix.chat.Register("radio_lang_y", {
            format = "%s yells in %s over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.y.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                local color = ix.config.Get("chatRadioColor")
                return Color(color.r + 35, color.g + 35, color.b + 35)
            end,
            CanHear = function(self, speaker, listener, data)
                return listener:GetCharacter():CanHearFrequency(data.frequency)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
                local radio = char:GetActiveRadio(data.frequency)
                local language = data.language

                local name = anonymous and
                L"someone" or hook.Run("GetCharacterName", speaker, "radio_y") or
                (IsValid(speaker) and speaker:Name() or "Console")

                if (char:HasLanguage(language)) then
                    if ix.config.Get("garbleRadio", true) and data.garble and speaker and LocalPlayer() != speaker then 
                        text = garbleMessage(speaker, text, data.power)
                    end

                    text = string.format("<:: %s ::>", text)
                    chat.AddText(self:GetColor(speaker, text), string.format(self.format, name, language, text))
                else
                    text = string.format("%s yells something unintelligible over the radio in %s.", name, language)
                    chat.AddText(self:GetColor(speaker, text), text)
                end

                local snd = radio:GetReceiveSound()
                if snd then
                    if isentity(radio) then
                        radio:EmitSound(snd)
                    else
                        surface.PlaySound(snd)
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
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.ic.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.chat.classes.ic:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener, data)
                if speaker == listener then
                    return false
                end

                if listener:GetCharacter():CanHearFrequency(data.frequency) then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280)
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
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
            end,
        })

        -- Whisper Range
        ix.chat.Register("radio_eavesdrop_lang_w", {
            format = "%s whispers in %s over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.w.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.chat.classes.w:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener, data)
                if speaker == listener then
                    return false
                end

                if listener:GetCharacter():CanHearFrequency(data.frequency) then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280) * 0.25
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
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
            end,
        })

        -- Yelling Range
        ix.chat.Register("radio_eavesdrop_lang_y", {
            format = "%s yells in %s over the radio: \"%s\"",
            GetFont = function(self, speaker, text, data)
                return ix.chat.classes.y.font or "ixChatFont"
            end,
            GetColor = function(self, speaker, text)
                return ix.chat.classes.y:GetColor(speaker, text)
            end,
            CanHear = function(self, speaker, listener, data)
                if speaker == listener then
                    return false
                end

                if listener:GetCharacter():CanHearFrequency(data.frequency) then
                    return false
                end

                local chatRange = ix.config.Get("chatRange", 280) * 2
                return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= (chatRange * chatRange)
            end,
            OnChatAdd = function(self, speaker, text, anonymous, data)
                local char = LocalPlayer():GetCharacter()
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