local mS = require('scripts.NCGDMW.settings')

return function(str)
    if mS.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end

