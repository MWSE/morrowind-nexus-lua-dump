local readable_space_shifter = require("scripts.openmw_books_enhanced.outside_manipulators.readable_space_shifter")
local content_name = require("scripts.openmw_books_enhanced.window.content_element_names")

local MW = {}

function MW.manipulateDocumentWindowBasedOnMouseWheelTurn(documentWindow, x)
    if x > 0 then --up
        if documentWindow.layout.content:indexOf(content_name.leftPage.pageScrollbarDownButton_BORDER) ~= nil then
            readable_space_shifter.shiftSpaceUp(documentWindow)
        else
            readable_space_shifter.shiftToPrevPage(documentWindow)
        end
    elseif x < 0 then -- down
        if documentWindow.layout.content:indexOf(content_name.leftPage.pageScrollbarDownButton_BORDER) ~= nil then
            readable_space_shifter.shiftSpaceDown(documentWindow)
        else
            readable_space_shifter.shiftToNextPage(documentWindow)
        end
    end
end

return MW
