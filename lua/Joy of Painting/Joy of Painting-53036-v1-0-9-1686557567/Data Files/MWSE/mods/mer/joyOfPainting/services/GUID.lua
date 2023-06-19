local GUID = {}

function GUID.generate()
    math.randomseed(os.time())
    -- generate a random number in hexadecimal format
    local guid = string.format("%x", math.random(0xfffff))
    -- add some randomness to the generated number
    guid = guid .. string.format("%x", math.random(0xffff))
    guid = guid .. string.format("%x", math.random(0xffff))
    -- return the generated GUID
    return guid
end

return GUID
