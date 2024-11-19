local templates = require("scripts.openmw_books_enhanced.ui_layout.ui_templates")
local settings = require("scripts.openmw_books_enhanced.settings")
local daedric_text_creator = require("scripts.openmw_books_enhanced.ui_layout.daedric_text_creator")
local ui = require('openmw.ui')

local TXT = {}

function TXT.createNormalTextWidget(text)
    return {
        template = templates.journalTextNormal,
        props = {
            text = text,
            textSize = settings.SettingsTravOpenmwBooksEnhanced_textDocumentNormalSize()
        },
        userData = {},
    }
end

function TXT.createDaedricTextWidget(text, formattingSettings)
    local daedricTextResults = daedric_text_creator.makeDaedricPhraseContents(text, formattingSettings)

    return {
        template = templates.journalTextDaedricContainer,
        props = {
            text = text,
        },
        userData = {
            width = daedricTextResults.width,
            height = daedricTextResults.height,
        },
        content = ui.content(daedricTextResults.content)
    }
end

return TXT
