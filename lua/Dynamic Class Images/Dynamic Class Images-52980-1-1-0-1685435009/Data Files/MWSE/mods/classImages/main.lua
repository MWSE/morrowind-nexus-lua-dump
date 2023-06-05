
local config = require("classImages.config")
local common = require("classImages.common")
local ImagePiece = require("classImages.components.ImagePiece")
local service = require("classImages.classImageService")

for _, e in ipairs(config.imagePieces) do
    ImagePiece.register(e)
end

event.register("uiActivated", service.updateClassImage)
event.register("uiActivated", service.doClassTooltip, { filter = "MenuStat", priority = -50 })
event.register("uiActivated", service.doClassTooltip, { filter = "MenuStatReview", priority = -50 })
event.register("uiActivated", service.doCreateClassMenu, { filter = "MenuCreateClass", priority = -50 })
event.register("uiActivated", service.updateCreateClassMenuOnButtonClose)