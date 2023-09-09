-- This is where we define all our events. --

local eventHandler = require("tew.Happenstance Hodokinesis.eventHandler")
local dataHandler = require("tew.Happenstance Hodokinesis.dataHandler")

event.register(tes3.event.equip, eventHandler.onEquip)
event.register(tes3.event.keyDown, eventHandler.onKeyDown, { filter = tes3.scanCode.h })
event.register(tes3.event.loaded, dataHandler.initialiseData)
