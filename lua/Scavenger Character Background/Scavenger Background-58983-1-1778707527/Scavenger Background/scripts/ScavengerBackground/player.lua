local I = require("openmw.interfaces")
local self = require("openmw.self")
local core = require("openmw.core")
local time = require("openmw_aux.time")
local async = require("openmw.async")

local deps = require("scripts.ScavengerBackground.dependencies")

deps.checkAll("Scavenger Background", { {
    plugin = "CharacterTraitsFramework.omwscripts", 
    interface = I.CharacterTraits,
} })

local period = 2 * time.minute
local timerStarted = false
local minDelay = 1 * time.hour
local maxDelay = 1 * time.day

local getScavengerItem = async:registerTimerCallback( 
    "getScavengerItem",
    function()
        core.sendGlobalEvent("scavengerItemSpawned", self)
        timerStarted = false
        self:sendEvent(
            "ShowMessage",
            { message = "Oh, shiny!" })
    end
)


local function canGetItem() 
    if timerStarted then return end
    async:newGameTimer(
        math.random(minDelay, maxDelay),
        getScavengerItem
    )
    timerStarted = true
end

I.CharacterTraits.addTrait {
    id = "scavenger",
    type = "background",
    name = "Scavenger",
    description = (
        "For as long as you remember you had this allure for picking up misplaced things." ..
        " Is this a blessing or a curse?" ..
        " Perhaps it's the Daedra meddling with you life?" ..
        " It's not for you to know, for who cares, when there's a new shiny thing on the ground ripe for taking?\n" ..
        "\n" ..
        ">From time to time you will acquire small trinkets you find on the ground\n"
    ),   
    onLoad = function()
        time.runRepeatedly(canGetItem, period)
    end
}

local function onSave()
    return {
        lootTimerStarted = timerStarted,
    }
end

local function onLoad(data)
    if not data then return end
    timerStarted = data.lootTimerStarted or timerStarted
end

return {
    engineHandlers = {
        onSave = onSave,
        onLoad = onLoad
    }
}