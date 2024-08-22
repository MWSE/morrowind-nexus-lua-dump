local constants = require("scripts.openmw_books_enhanced.ui_layout.ui_constants")
local ui_clickable = require("scripts.openmw_books_enhanced.ui_layout.ui_clickable")
local templates = require("scripts.openmw_books_enhanced.ui_layout.ui_templates")

local JB = {}

function JB.createJournalButton(onClickCallback, updateJournalWindow)
    local result = ui_clickable.createClickableWidget(onClickCallback, updateJournalWindow)
    result.template = templates.journalTextButtonIdle
    result.userData.textColorIdle = constants.fontColorJournalButtonIdle
    result.userData.textColorOver = constants.fontColorJournalButtonOver
    result.userData.textColorPressed = constants.fontColorJournalButtonPressed

    return result
end

return JB
