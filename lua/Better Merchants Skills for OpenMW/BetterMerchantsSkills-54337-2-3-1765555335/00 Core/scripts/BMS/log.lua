local S = require('scripts.BMS.settings')

return function(str)
    if S.globalStorage:get("debugMode") then
        print("DEBUG: " .. str)
    end
end