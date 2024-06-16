local PaperMold = require("mer.joyOfPainting.items.PaperMold")

local paperMolds = {
    {
        id = "jop_paper_mold",
        hoursToDry = 4,
        paperId = "sc_paper plain",
        paperPerPulp = 5,
    }
}
local paperPulps = {
    { id = "jop_paper_pulp" }
}
event.register(tes3.event.initialized, function()
    for _, paperMold in ipairs(paperMolds) do
        PaperMold.registerPaperMold(paperMold)
    end

    for _, paperPulp in ipairs(paperPulps) do
        PaperMold.registerPaperPulp(paperPulp)
    end
end)