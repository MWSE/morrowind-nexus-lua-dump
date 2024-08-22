local core = require("openmw.core")

if core.API_REVISION < 62 then
    error("This mod requires OpenMW 0.49.0 or newer.")
end