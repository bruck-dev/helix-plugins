
-- Standard radio speaking commands
do
    ix.command.Add("Radio", {
        description = "Communicate over a long distance with a radio. Eavesdroppers can hear like normal.",
        arguments = ix.type.text,
        alias = {"R"},
        bNoIndicator = false,
        indicator = "chatRadioing",
        OnRun = function(self, client, message)
            if !message or message == "" then
                client:Notify("You must enter a message to say!")
                return
            end

            local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio(message)
            if can then
                local freq = radio:GetFrequency()

                if radio.TwoWay and ix.radio.stations.Get(freq) and !radio.isHost then
                    client:Notify("This radio is not the host of the tuned radio station!")
                    return
                end

                -- transmit power multiplier for the specific radio; defaults to 1, no change
                local pwr = radio.transmitPower or radio.TransmitPower or 1

                local data = {frequency = freq, garble = canGarble, power = pwr}
                if isentity(radio) then
                    data.radio = radio
                end
                ix.chat.Send(client, "radio", message, nil, nil, data)
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
            if !message or message == "" then
                client:Notify("You must enter a message to say!")
                return
            end

            local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio(message)
            if can then
                local freq = radio:GetFrequency()

                if radio.TwoWay and ix.radio.stations.Get(freq) and !radio.isHost then
                    client:Notify("This radio is not the host of the tuned radio station!")
                    return
                end

                -- transmit power multiplier for the specific radio; defaults to 1, no change
                local pwr = radio.transmitPower or radio.TransmitPower or 1

                local data = {frequency = freq, garble = canGarble, power = pwr}
                if isentity(radio) then
                    data.radio = radio
                end
                ix.chat.Send(client, "radio_w", message, nil, nil, data)
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
            if !message or message == "" then
                client:Notify("You must enter a message to say!")
                return
            end

            local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio(message)
            if can then
                local freq = radio:GetFrequency()

                if radio.TwoWay and ix.radio.stations.Get(freq) and !radio.isHost then
                    client:Notify("This radio is not the host of the tuned radio station!")
                    return
                end

                -- transmit power multiplier for the specific radio; defaults to 1, no change
                local pwr = radio.transmitPower or radio.TransmitPower or 1

                local data = {frequency = freq, garble = canGarble, power = pwr}
                if isentity(radio) then
                    data.radio = radio
                end
                ix.chat.Send(client, "radio_y", message, nil, nil, data)
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
                if !message or message == "" then
                    client:Notify("You must enter a message to say!")
                    return
                end

                local lang = ix.language.Get(language)
                if !lang then
                    client:Notify(language .. " is not a valid language.")
                    return
                elseif lang and !client:GetCharacter():HasLanguage(lang) then
                    client:Notify("You do not know how to speak " .. lang .. ".")
                    return
                end

                local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio(message)
                if can then
                    local freq = radio:GetFrequency()

                    if radio.TwoWay and ix.radio.stations.Get(freq) and !radio.isHost then
                        client:Notify("This radio is not the host of the tuned radio station!")
                        return
                    end

                    -- transmit power multiplier for the specific radio; defaults to 1, no change
                    local pwr = radio.transmitPower or radio.TransmitPower or 1

                    local data = {frequency = freq, garble = canGarble, language = lang, power = pwr}
                    if isentity(radio) then
                        data.radio = radio
                    end
                    ix.chat.Send(client, "radio_lang", message, nil, nil, data)
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
                if !message or message == "" then
                    client:Notify("You must enter a message to say!")
                    return
                end

                local lang = ix.language.Get(language)
                if !lang then
                    client:Notify(language .. " is not a valid language.")
                    return
                elseif lang and !client:GetCharacter():HasLanguage(lang) then
                    client:Notify("You do not know how to speak " .. lang .. ".")
                    return
                end

                local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio(message)
                if can then
                    local freq = radio:GetFrequency()

                    if radio.TwoWay and ix.radio.stations.Get(freq) and !radio.isHost then
                        client:Notify("This radio is not the host of the tuned radio station!")
                        return
                    end

                    -- transmit power multiplier for the specific radio; defaults to 1, no change
                    local pwr = radio.transmitPower or radio.TransmitPower or 1

                    local data = {frequency = freq, garble = canGarble, language = lang, power = pwr}
                    if isentity(radio) then
                        data.radio = radio
                    end
                    ix.chat.Send(client, "radio_lang_w", message, nil, nil, data)
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
                if !message or message == "" then
                    client:Notify("You must enter a message to say!")
                    return
                end

                local lang = ix.language.Get(language)
                if !lang then
                    client:Notify(language .. " is not a valid language.")
                    return
                elseif lang and !client:GetCharacter():HasLanguage(lang) then
                    client:Notify("You do not know how to speak " .. lang .. ".")
                    return
                end

                local can, err, radio, canGarble = client:GetCharacter():CanTalkOverRadio(message)
                if can then
                    local freq = radio:GetFrequency()

                    if radio.TwoWay and ix.radio.stations.Get(freq) and !radio.isHost then
                        client:Notify("This radio is not the host of the tuned radio station!")
                        return
                    end

                    -- transmit power multiplier for the specific radio; defaults to 1, no change
                    local pwr = radio.transmitPower or radio.TransmitPower or 1

                    local data = {frequency = freq, garble = canGarble, language = lang, power = pwr}
                    if isentity(radio) then
                        data.radio = radio
                    end
                    ix.chat.Send(client, "radio_lang_y", message, nil, nil, data)
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
        local radio = character:GetRadioItem()

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

ix.command.Add("SetStationHost", {
    description = "Sets the stationary radio you are currently looking at as the 'host' radio of the given station, meaning only it can broadcast on that frequency.",
    alias = {"SetRadioHost", "SetHost"},
    adminOnly = true,
    arguments = ix.type.number,
    OnRun = function(self, client, frequency)

        frequency = string.format("%.1f", tonumber(frequency))
        local station = ix.radio.stations.Get(frequency)
        if !station then
            client:Notify("The given frequency is not a valid radio station!")
            return
        end

        local data = {}
            data.start = client:GetShootPos()
            data.endpos = data.start + client:GetAimVector() * 128
            data.filter = client
        local trace = util.TraceLine(data)
        local entity = trace.Entity

        if !entity or !string.find(entity:GetClass(), "ix_radio") then
            client:Notify("You must be looking at a stationary radio to set it as a host!")
            return
        elseif !entity.EnableStations then
            client:Notify("This radio cannot receive radio station broadcasts!")
            return
        elseif !entity.TwoWay then
            client:Notify("This radio cannot broadcast messages!")
            return
        end

        entity:UpdateFrequency(frequency)
        ix.radio.stations.SetHostRadio(entity, frequency)

        client:Notify("Radio set as host for " .. station:GetName() .. ".")
    end
})

ix.command.Add("ClearStationHost", {
    description = "Clears the assigned host radio from the given radio station frequency.",
    alias = {"ClearRadioHost", "ClearHost"},
    adminOnly = true,
    arguments = ix.type.number,
    OnRun = function(self, client, frequency)

        frequency = string.format("%.1f", tonumber(frequency))
        local station = ix.radio.stations.Get(frequency)
        if !station then
            client:Notify("The given frequency is not a valid radio station!")
            return
        end

        ix.radio.stations.SetHostRadio(nil, frequency)

        client:Notify("Station host cleared for " .. station:GetName() .. ".")
    end
})