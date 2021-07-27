--[[
    Mod: Weather Adjuster
    Author: Hrnchamd
    Version: 2.0
]]--

local this = {}

function this.patchCloudVertexColours()
    -- Set cloud vertex colour to fog colour, instead of using fog blended with another colour.
    -- Allows cloud colour to be adjusted near full black.
    mwse.memory.writeBytes{address = 0x43EE81, bytes = {
        0x8D, 0x86, 0x9C, 0, 0, 0,      -- lea eax, [esi+fogCol]
        0x50,                           -- push eax
        0x8D, 0x4C, 0x24, 0x20,         -- lea eax, [esp+finalCol]
        0xEB, 0x20                      -- jmp $+0x20
    }}
end

return this