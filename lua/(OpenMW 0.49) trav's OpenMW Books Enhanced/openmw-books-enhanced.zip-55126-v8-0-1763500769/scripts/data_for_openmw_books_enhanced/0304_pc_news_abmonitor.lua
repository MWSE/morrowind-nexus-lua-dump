local types = require('openmw.types')
local util = require('openmw.util')
local ui = require('openmw.ui')

local DocumentData = {
    name = "PcAbmonitor",
    shouldApplyTo = function(gameObject)
        return string.match(types.Book.records[gameObject.recordId].model, "pc.+pc_text_note_anv_news.nif")
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
                height = (300 - 30),
                posTopLeftCornerX = 6,
                posTopLeftCornerY = 100 + 6,
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
            "<IMG SRC=\"PC\\pc_abmonitor%.dds\" WIDTH=\"290\" HEIGHT=\"140\"><BR>",
            ""
        )
    end,
    additionalWidgetsInDocumentUi = {
        {
            type = ui.TYPE.Image,
            name = "CustomWidget001",
            props = {
                size = util.vector2(207, 100),
                position = util.vector2(256 / 2, 5),
                anchor = util.vector2(0.5, 0.0),
                resource = ui.texture { path = "bookart\\pc\\pc_abmonitor.dds" },
                visible = true,
            },
        }
    },
}
return DocumentData
