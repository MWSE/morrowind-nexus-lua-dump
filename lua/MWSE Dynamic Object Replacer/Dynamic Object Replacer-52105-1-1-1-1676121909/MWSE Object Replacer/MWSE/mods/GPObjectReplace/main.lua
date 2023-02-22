local OR = require("DOR.GPObjectReplacer")

local function initialized()
    event.register(tes3.event.referenceActivated, OR.onReferenceActivated)
    OR.loadORFiles()
    -- Remove the "--" from the beginning of the next line to dump the contents of mergedObjects to MWSE.log at startup. Useful for debugging.
    --OR.printObjects()
    mwse.log("[Object Replacer] OR initialized")
end

event.register(tes3.event.initialized, initialized)