local types = require('openmw.types')

local DocumentData = {
    name = "TrCard",
    shouldApplyTo = function(gameObject)
        return string.match(types.Book.records[gameObject.recordId].model, "pc.+m.+pc_misc_card_07.nif")
    end,
    texture = {
        path = "textures/openmw_books_enhanced/tx_travbook_card.dds",
        width = 360,
        height = 360,
        colorable = false,
    },
    pagesTextArrangement = {
        page1 = {
            textArea = {
                width = 265,
                height = 154,
                posTopLeftCornerX = 53,
                posTopLeftCornerY = 103,
                isScrollableVertically = true,
            },
            pageNumber = {
                posCenterX = 53 + (254 / 2),
                posCenterY = 103 + 154 + 10,
            }
        },
        page2 = nil,
    },
    takeButton = {
        posCenterX = 53 + 20,
        posCenterY = 103 + 154 + 9,
    },
    prevButton = {
        posCenterX = (53 + (254 / 2)) - 71,
        posCenterY = 103 + 154 + 9,
    },
    nextButton = {
        posCenterX = (53 + (254 / 2)) + 71,
        posCenterY = 103 + 154 + 9,
    },
    closeButton = {
        posCenterX = 53 + 254 - 20,
        posCenterY = 103 + 154 + 9,
    },

}
return DocumentData
