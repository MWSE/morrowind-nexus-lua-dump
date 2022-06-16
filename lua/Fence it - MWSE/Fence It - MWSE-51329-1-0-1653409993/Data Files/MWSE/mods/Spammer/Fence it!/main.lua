local mod = require("Spammer\\Fence it!\\mod")

--[[event.register("postInfoResponse", )]]
--event.register("modConfigReady", mod.registerModConfig)

event.register("initialized", function()
    event.register("enterFrame", mod.postInfoResponse)
event.register("infoGetText", mod.onInfoGetText)
print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end, {priority = -1000})