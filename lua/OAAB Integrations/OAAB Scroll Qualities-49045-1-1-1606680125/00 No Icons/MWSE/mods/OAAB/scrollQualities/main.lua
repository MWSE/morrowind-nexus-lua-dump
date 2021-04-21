-- Replace Scroll Models and Icons --
local function qualifyScrolls()
    for book in tes3.iterateObjects(tes3.objectType.book) do
        if book.enchantment and book.mesh:lower() == "m\\text_scroll_01.nif" then
            if book.value >= 250 then
                book.mesh = "OAAB\\m\\scrollExclusive.nif"
            elseif book.value >= 150 then
                book.mesh = "OAAB\\m\\scrollQuality.nif"
            elseif book.value >= 100 then
                book.mesh = "OAAB\\m\\scrollStandard.nif"
            elseif book.value >= 50 then
                book.mesh = "OAAB\\m\\scrollCheap.nif"
            else
                book.mesh = "OAAB\\m\\scrollBargain.nif"
            end
        end
    end
end
event.register("initialized", qualifyScrolls)