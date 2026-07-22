NASG_RADIO_SPEECH = NASG_RADIO_SPEECH or {}

NASG_RADIO_SPEECH.DigitWords = {
    ["0"] = "zero",
    ["1"] = "one",
    ["2"] = "two",
    ["3"] = "three",
    ["4"] = "four",
    ["5"] = "five",
    ["6"] = "six",
    ["7"] = "seven",
    ["8"] = "eight",
    ["9"] = "niner",
}

NASG_RADIO_SPEECH.PhoneticToLetter = {
    ALPHA = "A",
    ALFA = "A",  -- MOOSE ATIS spells the A-letter "Alfa" (ATIS.Alphabet[1]).
    BRAVO = "B",
    CHARLIE = "C",
    DELTA = "D",
    ECHO = "E",
    FOXTROT = "F",
    GOLF = "G",
    HOTEL = "H",
    INDIA = "I",
    JULIET = "J",
    JULIETT = "J",
    KILO = "K",
    LIMA = "L",
    MIKE = "M",
    NOVEMBER = "N",
    OSCAR = "O",
    PAPA = "P",
    QUEBEC = "Q",
    ROMEO = "R",
    SIERRA = "S",
    TANGO = "T",
    UNIFORM = "U",
    VICTOR = "V",
    WHISKEY = "W",
    XRAY = "X",
    ["X-RAY"] = "X",
    YANKEE = "Y",
    ZULU = "Z",
}

NASG_RADIO_SPEECH.LetterToPhonetic = {
    A = "Alpha",
    B = "Bravo",
    C = "Charlie",
    D = "Delta",
    E = "Echo",
    F = "Foxtrot",
    G = "Golf",
    H = "Hotel",
    I = "India",
    J = "Juliett",
    K = "Kilo",
    L = "Lima",
    M = "Mike",
    N = "November",
    O = "Oscar",
    P = "Papa",
    Q = "Quebec",
    R = "Romeo",
    S = "Sierra",
    T = "Tango",
    U = "Uniform",
    V = "Victor",
    W = "Whiskey",
    X = "X-ray",
    Y = "Yankee",
    Z = "Zulu",
}

function NASG_RADIO_SPEECH:Trim(value)
    local text = tostring(value or "")

    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")

    return text
end

function NASG_RADIO_SPEECH:DigitToSpeech(digit)
    return self.DigitWords[tostring(digit)] or tostring(digit)
end

function NASG_RADIO_SPEECH:DigitsToSpeech(value)
    local text = tostring(value or "")
    local parts = {}

    for i = 1, string.len(text) do
        local char = string.sub(text, i, i)

        if char:match("%d") then
            parts[#parts + 1] = self:DigitToSpeech(char)
        elseif char == "." then
            parts[#parts + 1] = "decimal"
        elseif char == "-" then
            parts[#parts + 1] = "dash"
        elseif char == "/" then
            parts[#parts + 1] = "slash"
        else
            parts[#parts + 1] = char
        end
    end

    return table.concat(parts, " ")
end

function NASG_RADIO_SPEECH:FormatNumberGroups(text)
    local formatted = tostring(text or "")

    formatted = formatted:gsub("(%d+%.%d+)", function(numberText)
        return self:DigitsToSpeech(numberText)
    end)

    formatted = formatted:gsub("(%d+)", function(numberText)
        return self:DigitsToSpeech(numberText)
    end)

    formatted = formatted:gsub("%s+", " ")
    formatted = formatted:gsub("^%s+", "")
    formatted = formatted:gsub("%s+$", "")

    return formatted
end

function NASG_RADIO_SPEECH:FormatText(text)
    return self:FormatNumberGroups(text)
end

function NASG_RADIO_SPEECH:FormatCallsign(callsign)
    local text = self:Trim(callsign)

    if text == "" then
        return "Aircraft"
    end

    text = text:gsub("([%a]+)(%d+)", function(wordPart, numberPart)
        return wordPart .. " " .. self:DigitsToSpeech(numberPart)
    end)

    return self:FormatText(text)
end

function NASG_RADIO_SPEECH:FormatFrequency(frequency)
    local value = tonumber(frequency)

    if not value then
        return self:FormatText(tostring(frequency or ""))
    end

    local text = string.format("%.3f", value)

    text = text:gsub("0+$", "")
    text = text:gsub("%.$", "")

    return self:DigitsToSpeech(text)
end

function NASG_RADIO_SPEECH:FormatRunway(runway)
    local text = self:Trim(runway)
    local numberPart = text:match("^(%d+)")
    local suffix = text:match("^%d+([LRC])$")

    if numberPart then
        local spoken = self:DigitsToSpeech(numberPart)

        if suffix == "L" then
            return spoken .. " left"
        end

        if suffix == "R" then
            return spoken .. " right"
        end

        if suffix == "C" then
            return spoken .. " center"
        end

        return spoken
    end

    return self:FormatText(text)
end

function NASG_RADIO_SPEECH:NormalizeATISLetter(value)
    local text = self:Trim(value)

    text = text:gsub("[%.%,%!%?]", "")
    text = string.upper(text)

    if self.PhoneticToLetter[text] then
        return self.PhoneticToLetter[text]
    end

    if string.len(text) == 1 and text:match("%a") then
        return text
    end

    return text
end

function NASG_RADIO_SPEECH:FormatATISLetter(value)
    local letter = self:NormalizeATISLetter(value)

    return self.LetterToPhonetic[letter] or tostring(value or "")
end

function NASG_RADIO_SPEECH:FormatHeading(heading)
    local value = tonumber(heading)

    if not value then
        return self:FormatText(heading)
    end

    local rounded = math.floor(value + 0.5)

    if rounded <= 0 then
        rounded = 360
    end

    if rounded > 360 then
        rounded = rounded % 360
    end

    return self:DigitsToSpeech(string.format("%03d", rounded))
end

function NASG_RADIO_SPEECH:FormatAltitudeFeet(altitudeFeet)
    local value = tonumber(altitudeFeet)

    if not value then
        return self:FormatText(altitudeFeet)
    end

    return self:DigitsToSpeech(tostring(math.floor(value + 0.5)))
end

function NASG_RADIO_SPEECH:FormatFlightLevel(flightLevel)
    local value = tonumber(flightLevel)

    if not value then
        return "flight level " .. self:FormatText(flightLevel)
    end

    return "flight level " .. self:DigitsToSpeech(string.format("%03d", math.floor(value + 0.5)))
end