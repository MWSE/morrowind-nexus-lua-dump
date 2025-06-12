local log = require("SedrynTyros.ORLL.log")
local classImageConfig = include("classImages.config")

local this = {}

if classImageConfig then
    this.classImages = true
    classImageConfig.menuData.MenuLevelUp = {
        imageBlockName = "ORLL_ImageBlock",
        width = 0.85 * 256,
        height = 0.85 * 128,
        parentWidth = 0.85 * 256,
        parentHeight = 0.85 * 128,
    }
    log:info("Compatibilized Dynamic Class Images.")
end

return this
