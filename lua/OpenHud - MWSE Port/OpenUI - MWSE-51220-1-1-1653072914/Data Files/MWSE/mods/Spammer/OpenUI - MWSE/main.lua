local mod = require("Spammer\\OpenUi - MWSE\\mod")

local seph = include("seph.hudCustomizer.interop")
if seph then
	seph:registerElement("Spa_replica", "OpenUI for MWSE", { positionX = 0.02, positionY = 0.02}, {position = true})
    seph:registerElement("Spa_lung", "OpenUI Breathing Bar", { positionX = 0.5, positionY = 0.05}, {position = true})
end



event.register(tes3.event.initialized, function ()
event.register(tes3.event.uiActivated, mod.loaded, {filter = "MenuMulti"})
event.register(tes3.event.simulate, mod.simulate, {priority = -1000})
--event.register(tes3.event.keyUp, mod.simulate)
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end)

