local ui = require('openmw.ui')
local util = require('openmw.util')

return {
    textNormalSize = 16,
    textHeaderSize = 18,
    headerColor = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
    normalColor = util.color.rgb(34 / 255, 175 / 255, 251 / 255),
    border = 2,
    thickBorder = 4,
    padding = 2,
    whiteTexture = ui.texture { path = 'white' },
}
