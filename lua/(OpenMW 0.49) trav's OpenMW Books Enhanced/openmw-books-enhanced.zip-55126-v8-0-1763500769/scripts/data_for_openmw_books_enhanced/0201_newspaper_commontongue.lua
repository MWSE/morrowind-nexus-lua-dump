local types = require('openmw.types')
local util = require('openmw.util')
local ui = require('openmw.ui')

local DocumentData = {
    name = "MournholdCommonTongue",
    shouldApplyTo = function(gameObject)
        return (string.match(gameObject.recordId, "bk_commontongue"))
    end,
    texture = {
        path = "textures/openmw_books_enhanced/tx_travbook_newspaper.dds",
        width = 256,
        height = 400,
        colorable = false,
    },
    pagesTextArrangement = {
        page1 = {
            textArea = {
                width = (256 - (2 * 6)),
                height = (350 - 30),
                posTopLeftCornerX = 6,
                posTopLeftCornerY = 50 + 6,
                isScrollableVertically = false,
            },
            pageNumber = {
                posCenterX = 256 / 2,
                posCenterY = 400 - 13,
            }
        },
        page2 = nil,
    },
    takeButton = {
        posCenterX = 35,
        posCenterY = 20,
    },
    prevButton = {
        posCenterX = 40,
        posCenterY = 400 - 13,
    },
    nextButton = {
        posCenterX = 256 - 40,
        posCenterY = 400 - 13,
    },
    closeButton = {
        posCenterX = 256 - 35,
        posCenterY = 20,
    },
    modifyTextBeforeApplying = function(text)
        return string.gsub(
            text,
            "THE COMMON TONGUE<BR>",
            ""
        )
    end,
    additionalWidgetsInDocumentUi = {
        {
            type = ui.TYPE.Text,
            name = "CustomWidget001",
            props = {
                multiline = false,
                wordWrap = false,
                autoSize = true,
                size = util.vector2(207, 100),
                position = util.vector2(256 / 2, 35),
                anchor = util.vector2(0.5, 0.0),
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                textSize = 25,
                text = "THE COMMON TONGUE",
                visible = true,
            },
        },
        {
            type = ui.TYPE.Text,
            name = "CustomWidget001b",
            props = {
                multiline = false,
                wordWrap = false,
                autoSize = true,
                size = util.vector2(207, 100),
                position = util.vector2(256 / 2, 35),
                anchor = util.vector2(0.5, 0.0),
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                textSize = 25,
                text = "THE COMMON TONGUE",
                visible = true,
            },
        },
        {
            type = ui.TYPE.Image,
            name = "CustomWidget002",
            props = {
                size = util.vector2((256 - (2 * 10)), 1),
                position = util.vector2(256 / 2, 35 + 15),
                anchor = util.vector2(0.5, 0.0),
                resource = ui.texture { path = "white" },
                color = util.color.rgb(0, 0, 0),
                visible = true,
            },
        }
    },
}
return DocumentData
