local bit = require('bit')
local interop = require('merz.skill_increase_gmst_fix.interop')

local prefix = '[Skill Increase GMST Fix]'

local function log(s, ...)
    mwse.log(prefix .. ' ' .. s, ...)
end

local function outOfDate()
    local msg = 'MWSE is out of date! Update to use this mod.'
    tes3.messageBox(prefix .. '\n' .. msg)
    log(msg)
end

if mwse.buildDate == nil or mwse.buildDate < 20200511 then
    event.register('initialized', outOfDate)
    return
end

-- Convert a 32-bit integer to an array of 4 bytes.
local function intToBytes(int)
    local bytes = {}
    for i = 0, 3 do
        bytes[i+1] = bit.band(bit.rshift(int, i * 8), 0xff)
    end
    return bytes
end

log('Patching game code...')
mwse.memory.writeBytes({address = 0x4a2979, bytes = intToBytes(tes3.gmst.iLevelupMinorMult)})          -- book
mwse.memory.writeBytes({address = 0x4a29ac, bytes = intToBytes(tes3.gmst.iLevelupMinorMultAttribute)}) -- book
mwse.memory.writeBytes({address = 0x4a29bc, bytes = intToBytes(tes3.gmst.iLevelupMajorMult)})          -- book
mwse.memory.writeBytes({address = 0x4a29ef, bytes = intToBytes(tes3.gmst.iLevelupMajorMultAttribute)}) -- book
mwse.memory.writeBytes({address = 0x6185e9, bytes = intToBytes(tes3.gmst.iLevelupMinorMult)})          -- training
mwse.memory.writeBytes({address = 0x61861c, bytes = intToBytes(tes3.gmst.iLevelupMinorMultAttribute)}) -- training
mwse.memory.writeBytes({address = 0x61862c, bytes = intToBytes(tes3.gmst.iLevelupMajorMult)})          -- training
mwse.memory.writeBytes({address = 0x61865f, bytes = intToBytes(tes3.gmst.iLevelupMajorMultAttribute)}) -- training
log('done.')
interop.is_patched = true