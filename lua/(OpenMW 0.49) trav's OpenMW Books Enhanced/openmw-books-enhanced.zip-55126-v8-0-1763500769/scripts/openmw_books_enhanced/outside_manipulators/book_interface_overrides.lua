local util = require('openmw.util')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local l10n = require('openmw.core').l10n("openmw_books_enhanced")
local constants = require("scripts.openmw_books_enhanced.ui_layout.ui_constants")
local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")

local UN = {}

function UN.wasBookUiOverridenBySomething()
    for _, activeUiMode in pairs(I.UI.modes) do
        if activeUiMode == I.UI.MODE.Book or activeUiMode == I.UI.MODE.Scroll then
            return false
        end
    end
    return true
end

return UN
