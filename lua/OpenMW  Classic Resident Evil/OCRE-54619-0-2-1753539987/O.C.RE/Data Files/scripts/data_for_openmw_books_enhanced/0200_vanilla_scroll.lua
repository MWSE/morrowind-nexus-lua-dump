local types = require('openmw.types')

local DocumentData = {
    name = "VanillaScroll",
    shouldApplyTo = function(gameObject)
        return gameObject.type == types.Book and types.Book.records[gameObject.recordId].isScroll
    end,
    texture = {
        path = "textures/BlackScreen.png",
        width = 512,
        height = 372,
        colorable = false,
    },
    pagesTextArrangement = {
        page1 = {
            textArea = {
                width = 420,
                height = 235,
                posTopLeftCornerX = 50,
                posTopLeftCornerY = 84,
                isScrollableVertically = true,
            },
            pageNumber = {
                posCenterX = 50 + (420 / 2),
                posCenterY = 84 + 235 + 15,
            }
        },
        page2 = nil,
    },
    takeButton = {
        posCenterX = 35,
        posCenterY = 22,
    },
    prevButton = {
        posCenterX = (50 + (420 / 2)) - 71,
        posCenterY = 84 + 235 + 15,
    },
    nextButton = {
        posCenterX = (50 + (420 / 2)) + 71,
        posCenterY = 84 + 235 + 15,
    },
    closeButton = {
        posCenterX = 479,
        posCenterY = 25,
    },

}
return DocumentData
