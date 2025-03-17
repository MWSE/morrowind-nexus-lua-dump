local S = require('scripts.NCGDMW.settings')

return function(str)
    if S.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end

