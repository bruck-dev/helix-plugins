
-- Standard radio speaking commands
do
    ix.command.Add("Radio", {
        description = "Communicate over a long distance with a radio. Eavesdroppers can hear like normal.",
        arguments = ix.type.text,
        alias = {"R"},
        bNoIndicator = false,
        indicator = "chatRadioing",
        OnRun = function(self, client, message)
            local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio()
            if can then
                local freq = radio:GetFrequency()
                ix.chat.Send(client, "radio", message, nil, nil, {frequency = freq, garble = canGarble})
                ix.chat.Send(client, "radio_eavesdrop", message, nil, nil, {frequency = freq})
            else
                return err
            end
        end,
    })

    ix.command.Add("RadioW", {
        description = "Communicate over a long distance with a radio. Eavesdroppers can hear in a whisper range.",
        arguments = ix.type.text,
        alias = {"RW"},
        bNoIndicator = false,
        indicator = "chatRadioing",
        OnRun = function(self, client, message)
            local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio()
            if can then
                local freq = radio:GetFrequency()
                ix.chat.Send(client, "radio_w", message, nil, nil, {frequency = freq, garble = canGarble})
                ix.chat.Send(client, "radio_eavesdrop_w", message, nil, nil, {frequency = freq})
            else
                return err
            end
        end,
    })

    ix.command.Add("RadioY", {
        description = "Communicate over a long distance with a radio. Eavesdroppers can hear in a yell range.",
        arguments = ix.type.text,
        alias = {"RY"},
        bNoIndicator = false,
        indicator = "chatRadioing",
        OnRun = function(self, client, message)
            local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio()
            if can then
                local freq = radio:GetFrequency()
                ix.chat.Send(client, "radio_y", message, nil, nil, {frequency = freq, garble = canGarble})
                ix.chat.Send(client, "radio_eavesdrop_y", message, nil, nil, {frequency = freq})
            else
                return err
            end
        end,
    })
end

-- Optional language speaking commands
do
    if ix.language and ix.language.stored and (next(ix.language.stored) != nil) then
        ix.command.Add("RadioLang", {
            description = "Communicate in a language over a long distance with a radio. Eavesdroppers can hear like normal.",
            arguments = {
                ix.type.string,
                ix.type.text,
            },
            alias = {"RL"},
            bNoIndicator = false,
            indicator = "chatRadioing",
            OnRun = function(self, client, language, message)
                local lang = ix.language.Get(language)
                if !lang then
                    client:Notify(language .. " is not a valid language.")
                    return
                elseif lang and !client:GetCharacter():HasLanguage(lang) then
                    client:Notify("You do not know how to speak " .. lang .. ".")
                    return
                end

                local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio()
                if can then
                    local freq = radio:GetFrequency()
                    ix.chat.Send(client, "radio_lang", message, nil, nil, {frequency = freq, garble = canGarble, language = lang})
                    ix.chat.Send(client, "radio_eavesdrop_lang", message, nil, nil, {frequency = freq, language = lang})
                else
                    return err
                end
            end,
        })
    
        ix.command.Add("RadioLangW", {
            description = "Communicate in a language over a long distance with a radio. Eavesdroppers can hear in a whisper range.",
            arguments = {
                ix.type.string,
                ix.type.text,
            },
            alias = {"RLW"},
            bNoIndicator = false,
            indicator = "chatRadioing",
            OnRun = function(self, client, language, message)
                local lang = ix.language.Get(language)
                if !lang then
                    client:Notify(language .. " is not a valid language.")
                    return
                elseif lang and !client:GetCharacter():HasLanguage(lang) then
                    client:Notify("You do not know how to speak " .. lang .. ".")
                    return
                end

                local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio()
                if can then
                    local freq = radio:GetFrequency()
                    ix.chat.Send(client, "radio_lang_w", message, nil, nil, {frequency = freq, garble = canGarble, language = lang})
                    ix.chat.Send(client, "radio_eavesdrop_lang_w", message, nil, nil, {frequency = freq, language = lang})
                else
                    return err
                end
            end,
        })
    
        ix.command.Add("RadioLangY", {
            description = "Communicate in a language over a long distance with a radio. Eavesdroppers can hear in a yell range.",
            arguments = {
                ix.type.string,
                ix.type.text,
            },
            alias = {"RLY"},
            bNoIndicator = false,
            indicator = "chatRadioing",
            OnRun = function(self, client, language, message)
                local lang = ix.language.Get(language)
                if !lang then
                    client:Notify(language .. " is not a valid language.")
                    return
                elseif lang and !client:GetCharacter():HasLanguage(lang) then
                    client:Notify("You do not know how to speak " .. lang .. ".")
                    return
                end

                local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio()
                if can then
                    local freq = radio:GetFrequency()
                    ix.chat.Send(client, "radio_lang_y", message, nil, nil, {frequency = freq, garble = canGarble, language = lang})
                    ix.chat.Send(client, "radio_eavesdrop_lang_y", message, nil, nil, {frequency = freq, language = lang})
                else
                    return err
                end
            end,
        })
    end
end

ix.command.Add("SetFrequency", {
    description = "Set the frequency of your currently enabled radio. Accepts values in the form of 'XX.XX' or 'XXX.XX'",
    alias = {"SetFreq"},
    arguments = ix.type.number,
    OnRun = function(self, client, frequency)
        local character = client:GetCharacter()
        local en, radio = character:HasRadioEnabled()

        if radio then
            if tonumber(frequency) then
                frequency = string.format("%.1f", tonumber(frequency))
                client:Notify(radio:SetFrequency(frequency))
            else
                client:Notify(string.format("%s is an invalid frequency.", frequency))
            end
        else
            client:Notify("You do not have an enabled radio to set the frequency of.")
        end
    end
})