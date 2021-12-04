local core = require('openmw.core')
local input = require('openmw.input')

local function onKeyPress(key)
    -- Until a MCM is possible, you can change the keybinding here! For more options see the below link.
    -- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/openmw_input.html
    if key.symbol == 'q' and key.withAlt then
        core.quit()
    end
end

return {
    engineHandlers = {
        onKeyPress = onKeyPress
    },
}