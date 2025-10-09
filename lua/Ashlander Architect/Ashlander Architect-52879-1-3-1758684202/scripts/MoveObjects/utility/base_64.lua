


local base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local base64_char_to_byte = {}

-- Precompute a lookup table for decoding
for i = 1, #base64_chars do
    base64_char_to_byte[string.sub(base64_chars, i, i)] = i - 1
end
local function decode_base64(encoded)
    local result = {}
    local len = string.len(encoded)
    local index = 1

    local function char_to_byte(c)
        return base64_char_to_byte[c] or 0
    end

    local function lshift(num, bits)
        return num * (2 ^ bits)
    end

    while index <= len do
        local enc1 = char_to_byte(string.sub(encoded, index, index))
        index = index + 1
        local enc2 = char_to_byte(string.sub(encoded, index, index))
        index = index + 1
        local enc3 = char_to_byte(string.sub(encoded, index, index)) or 64
        index = index + 1
        local enc4 = char_to_byte(string.sub(encoded, index, index)) or 64
        index = index + 1

        local byte1 = lshift(enc1, 2) + math.floor(enc2 / 16)
        local byte2 = lshift(enc2 % 16, 4) + math.floor(enc3 / 4)
        local byte3 = lshift(enc3 % 4, 6) + enc4

        result[#result + 1] = string.char(byte1)
        if enc3 < 64 then
            result[#result + 1] = string.char(byte2)
        end
        if enc4 < 64 then
            result[#result + 1] = string.char(byte3)
        end
    end

    return table.concat(result)
end
local function rshift(num, bits)
    return math.floor(num / (2 ^ bits))
end

local function lshift(num, bits)
    return num * (2 ^ bits)
end


local function band(num, mask)
    return num % (mask + 1)
end

local function encode_base64(text)
    local result = {}
    local len = #text
    local index = 1

    local function char_to_byte(c)
        return string.byte(c) or 0
    end

    while index <= len do
        local char1 = char_to_byte(string.sub(text, index, index))
        index = index + 1
        local char2 = char_to_byte(string.sub(text, index, index))
        index = index + 1
        local char3 = char_to_byte(string.sub(text, index, index))
        index = index + 1

        local enc1 = rshift(char1, 2)
        local enc2 = lshift(band(char1, 0x03), 4) + rshift(char2 or 0, 4)
        local enc3 = lshift(band(char2 or 0, 0x0F), 2) + rshift(char3 or 0, 6)
        local enc4 = band(char3 or 0, 0x3F)

        if not char2 then
            enc3, enc4 = 64, 64
        elseif not char3 then
            enc4 = 64
        end

        result[#result + 1] = string.sub(base64_chars, enc1 + 1, enc1 + 1)
        result[#result + 1] = string.sub(base64_chars, enc2 + 1, enc2 + 1)
        result[#result + 1] = enc3 == 64 and "=" or string.sub(base64_chars, enc3 + 1, enc3 + 1)
        result[#result + 1] = enc4 == 64 and "=" or string.sub(base64_chars, enc4 + 1, enc4 + 1)
    end

    return table.concat(result)
end


return {
    decode_base64 = decode_base64,
    encode_base64  = encode_base64,
}