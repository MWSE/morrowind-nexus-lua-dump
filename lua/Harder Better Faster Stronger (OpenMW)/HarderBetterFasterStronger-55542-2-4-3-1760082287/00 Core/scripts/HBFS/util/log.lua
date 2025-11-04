local mStore = require('scripts.HBFS.config.store')

return function(str)
    if mStore.settings.debugMode.get() then
        print("DEBUG: " .. str)
    end
end