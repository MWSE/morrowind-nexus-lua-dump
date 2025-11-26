local types = require('openmw.types')
local util = require('openmw.util')
local ui = require('openmw.ui')

local DocumentData = {
    name = "TrCanyonEcho",
    shouldApplyTo = function(gameObject)
        return string.match(types.Book.records[gameObject.recordId].model, "tr.+m.+tr_text_note_nar_news.nif")
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
            "<IMG SRC=\"TR\\tr_echo_512_256%.dds\" WIDTH=\"348\" HEIGHT=\"168\"><BR>",
            ""
        )
    end,
    additionalWidgetsInDocumentUi = {
        {
            type = ui.TYPE.Image,
            name = "CustomWidget001",
            props = {
                size = util.vector2(207, 100),
                position = util.vector2(256 / 2, 15),
                anchor = util.vector2(0.5, 0.0),
                resource = ui.texture { path = "bookart\\TR\\TR_echo_512_256.dds" },
                visible = true,
            },
        }
    },
}
return DocumentData
