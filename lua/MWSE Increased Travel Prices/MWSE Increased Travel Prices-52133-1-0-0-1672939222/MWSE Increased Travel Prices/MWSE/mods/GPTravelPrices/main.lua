local config  = require("gptravelprices.config")
local GUI_ID_TravelMenu = tes3ui.registerID("MenuServiceTravel")

local function updatePrice(e)
    local npc = tes3ui.findMenu(GUI_ID_TravelMenu):getPropertyObject("MenuServiceTravel_Actor").reference.baseObject
    e.price = e.price * config.globalPriceMult
    if (npc.class.id == "Guild Guide") then
        e.price = e.price * config.magesGuildPriceMult
    elseif (npc.class.id == "Caravaner") then
        e.price = e.price * config.siltStriderPriceMult
    elseif (npc.class.id == "Shipmaster") then
        e.price = e.price * config.boatPriceMult
    elseif (npc.class.id == "Gondolier") then
        e.price = e.price * config.gondolaPriceMult
    elseif (npc.class.id == "PGTClass") then
        e.price = e.price * config.gondolaPriceMult
    end
    if e.companions then
        e.price = (e.price * config.companionMult) * (config.companionMult * #(e.companions))
    end
end

local function initialized()
    event.register(tes3.event.calcTravelPrice, updatePrice)
end

event.register(tes3.event.initialized, initialized)

event.register("modConfigReady", function()
    require("gptravelprices.mcm")
    config = require("gptravelprices.config")
end)