local common = require("seph.common")

local mathExtensions = {}

--- Returns the result of a basic time based sine wave function.
--- @param amplitude number The peak deviation of the function from zero.
--- @param frequency number The number of cycles that occur each second.
--- @param phase? number Optional. Default: 0. The offset of the waveform in time. This is specified in radians.
--- @return number
function mathExtensions.sineWave(amplitude, frequency, phase)
    return amplitude * math.sin(frequency * common.getTime() + (phase or 0))
end

return mathExtensions