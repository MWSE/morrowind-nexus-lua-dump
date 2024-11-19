local constants = require("scripts.openmw_books_enhanced.ui_layout.ui_constants")
local ui = require('openmw.ui')
local util = require('openmw.util')

local T = {
    journalPageText = {
        type = ui.TYPE.Flex,
        props = {
            size = util.vector2(0, 0),
            horizontal = false,
            relativeSize = util.vector2(1.0, 1.0)
        }
    },
    journalTextNormal = {
        type = ui.TYPE.Text,
        props = {
            textSize = constants.textDocumentNormalSize,
            textColor = util.color.rgb(1,1,1) --constants.fontColorJournalNormalText
        }
    },
    journalPageNumberText = {
        type = ui.TYPE.Text,
        props = {
            multiline = false,
            wordWrap = false,
            autoSize = true,
            anchor = util.vector2(0.5, 0.5),
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            textSize = constants.textDocumentPageNumberSize,
            textColor = util.color.rgb(1,1,1), --constants.textJournalPageNumberColor
        }
    },
    journalTextButtonIdle = {
        type = ui.TYPE.Text,
        props = {
            multiline = false,
            wordWrap = false,
            autoSize = true,
            anchor = util.vector2(0.5, 0.5),
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center,
            textSize = constants.textDocumentButtonSize,
            textColor = util.color.rgb(1,1,1), --constants.fontColorJournalButtonIdle,
            textShadow = true,
            textShadowColor = constants.fontColorJournalButtonShadow,
        }
    },
    journalButtonUnderline = {
        type = ui.TYPE.Image,
        props = {
            size = util.vector2(0, 1),
            relativeSize = util.vector2(1, 0),
            relativePosition = util.vector2(0, 0.9),
            resource = constants.whiteTexture,
            color = util.color.rgb(1,1,1), --constants.fontColorJournalButtonIdle
        }
    },
    journalTextDaedricContainer = {
        type = ui.TYPE.Flex,
        props = {
            autoSize = true,
            horizontal = true,
        },
    },
}

return T
