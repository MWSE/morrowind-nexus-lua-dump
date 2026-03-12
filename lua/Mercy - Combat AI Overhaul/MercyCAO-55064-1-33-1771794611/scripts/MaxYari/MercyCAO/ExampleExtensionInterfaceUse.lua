mp = "scripts/MaxYari/MercyCAO/"

local I = require('openmw.interfaces')
local gutils = require(mp .. "scripts/gutils")
local omwself = require('openmw.self')

-- Checking for some common placeholder npcs and not using mercy on them
if omwself.recordId == "ab01alsonar" then return end

DebugLevel = 0

if not I.MercyCAO then error(
    "MercyCAO compatibility patches script can not detect main MercyCAO. Ensure that compatiblity patches script is in a load order BELOW MercyCAO and BELOW the mods compatibility for which is being patched.") end

if I.TakeCover then
    gutils.print("Take Cover by Mym detected - applying a compatibility patch.", 1)

    local extension = {
        name = "TakeCoverByMym_Patch",
        run = function(task, state)
            if I.TakeCover.IsFleeing() or I.TakeCover.IsHidden() then
                state.vanillaBehavior = true
                task:running()
            else
                task:fail()
            end
        end
    }

    I.MercyCAO.addExtension("Locomotion", "FIGHT", "Any", extension)
    I.MercyCAO.addExtension("Combat", "FIGHT", "Any", extension)
end
