local types = require('openmw.types')
local util = require('openmw.util')
local ui = require('openmw.ui')

local DocumentData = {
    name = "TrEbonheartBellman",
    shouldApplyTo = function(gameObject)
        return types.Book.records[gameObject.recordId].model == "meshes\\tr\\m\\tr_note_oe_news.nif"
            and (string.match(gameObject.recordId, "t_news_bellman") or string.match(gameObject.recordId, "t_note_oe_newspaper"))
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
        posCenterY = 22,
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
        posCenterY = 22,
    },
    modifyTextBeforeApplying = function(text)
        return string.gsub(
            text,
            "<IMG SRC=\"TR\\TR_bellman_512_256%.dds\" WIDTH=\"290\" HEIGHT=\"140\"><BR>",
            ""
        )
    end,
    additionalWidgetsInDocumentUi = {
        {
            type = ui.TYPE.Image,
            name = "CustomWidget001",
            props = {
                size = util.vector2(207, 100),
                position = util.vector2(256 / 2, 6),
                anchor = util.vector2(0.5, 0.0),
                resource = ui.texture { path = "bookart\\TR\\TR_bellman_512_256.dds" },
                visible = true,
            },
        }
    },
}
return DocumentData
