local I = require('openmw.interfaces')

function GetLeader()
    local leader
    I.AI.forEachPackage(function(pkg)
        if (pkg.type == "Follow" or pkg.type == "Escort") and pkg.target and pkg.target:isValid() then
            leader = pkg.target
            return
        end
    end)
    return leader
end
