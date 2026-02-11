local ui = require('openmw.ui')
local util = require('openmw.util')

return function (x, y)
    return {
        Type = ui.TYPE.Widget,
        props = {
            size = util.vector2(x or 2, y or 2),
        },
    }
end