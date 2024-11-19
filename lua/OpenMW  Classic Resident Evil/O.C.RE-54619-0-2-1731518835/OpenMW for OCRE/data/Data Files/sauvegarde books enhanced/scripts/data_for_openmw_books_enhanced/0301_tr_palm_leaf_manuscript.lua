local types = require('openmw.types')

local DocumentData = {
    name = "TrPalmLeafManuscript",
    shouldApplyTo = function(gameObject)
        local palmModels = {
            "meshes\\pi\\m\\pi_sc_palm_01.nif",
            "meshes\\pi\\m\\pi_sc_palm_blank_01.nif",
            "meshes\\pi\\m\\pi_sc_palm_closed_01.nif",
        }
        local searchedModel = types.Book.records[gameObject.recordId].model
        for _, model in pairs(palmModels) do
            if searchedModel == model then
                return true
            end
        end
        return false
    end,
    texture = {
        path = "textures/openmw_books_enhanced/tx_travbook_palmleafmanuscript.dds",
        width = 716,
        height = 358,
        colorable = false,
    },
    pagesTextArrangement = {
        page1 = {
            textArea = {
                width = 284,
                height = 62,
                posTopLeftCornerX = 58,
                posTopLeftCornerY = 147,
                isScrollableVertically = false,
            },
            pageNumber = {
                posCenterX = 41,
                posCenterY = 155,
            }
        },
        page2 = {
            textArea = {
                posTopLeftCornerX = 376,
                posTopLeftCornerY = 147,
            },
            pageNumber = {
                posCenterX = 676,
                posCenterY = 202,
            }
        },
    },
    takeButton = {
        posCenterX = 86,
        posCenterY = 218,
    },
    prevButton = {
        posCenterX = (58 + (284 / 2)) + 71,
        posCenterY = 218,
    },
    nextButton = {
        posCenterX = (376 + (284 / 2)) - 71,
        posCenterY = 218,
    },
    closeButton = {
        posCenterX = 630,
        posCenterY = 218,
    },
}
return DocumentData
