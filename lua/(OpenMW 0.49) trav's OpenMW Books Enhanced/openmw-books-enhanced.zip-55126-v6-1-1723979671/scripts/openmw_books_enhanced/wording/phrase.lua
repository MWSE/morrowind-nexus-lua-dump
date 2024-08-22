local ui_text = require("scripts.openmw_books_enhanced.ui_layout.ui_text")
local html_tag_setting = require("scripts.openmw_books_enhanced.wording.html_tag_setting")
local util = require('openmw.util')

local K = {}

function K.createPhrase(text, phraseType, formattingSettings, characterSizingTable)
    local result = nil
    if formattingSettings and formattingSettings.newFontFace == "daedric" then
        result = ui_text.createDaedricTextWidget(text, formattingSettings)
    else
        result = ui_text.createNormalTextWidget(text)
        if characterSizingTable then
            result.userData.width = characterSizingTable.getSize(text)
        else
            result.userData.width = 0
        end
        if formattingSettings then
            if formattingSettings.newFontColor and formattingSettings.newFontColor ~= html_tag_setting.RESETSETTING then
                result.props.textColor = util.color.hex(formattingSettings.newFontColor)
            end
            if formattingSettings.newTextSize and formattingSettings.newTextSize ~= html_tag_setting.RESETSETTING then
                -- probably won't touch it
            end
        end
    end
    result.userData.type = phraseType
    return result
end

return K
