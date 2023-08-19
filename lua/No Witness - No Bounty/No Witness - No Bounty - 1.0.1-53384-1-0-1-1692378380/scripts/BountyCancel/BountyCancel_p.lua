local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local function BC_ShowMessage(message)
ui.showMessage(message)
end
local function onInit()
end
return {eventHandlers = {BC_ShowMessage = BC_ShowMessage,onInit = onInit}}