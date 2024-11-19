local util = require('openmw.util')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local l10n = require('openmw.core').l10n("openmw_books_enhanced")
local constants = require("scripts.openmw_books_enhanced.ui_layout.ui_constants")
local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")

local UN = {}

function UN.createWindowForSituationsWhenBookDidntLoadDueToQuickKeyUsage()
    return ui.create({
        layer = 'Windows',
        name = content_name.unsupportedWarning,
        template = I.MWUI.templates.boxSolid,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content({
            {
                type = ui.TYPE.Text,
                props = {
                    size = util.vector2(
                        ui.screenSize().x / 2,
                        ui.screenSize().y / 4
                    ),
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                    autoSize = false,
                    wordWrap = true,
                    multiline = true,
                    textSize = constants.textDocumentNormalSize,
                    textColor = constants.paperLikeColor,
                    text = "[" .. l10n("TravOpenmwBooksEnhancedModName") ..
                        "]\n\n" .. l10n("TravOpenmwBooksEnhancedQuickKeysUnsupported")
                }
            }
        })
    })
end

function UN.wasBookUiOverridenBySomething()
    for _, activeUiMode in pairs(I.UI.modes) do
        if activeUiMode == I.UI.MODE.Book or activeUiMode == I.UI.MODE.Scroll then
            return false
        end
    end
    return true
end

return UN
