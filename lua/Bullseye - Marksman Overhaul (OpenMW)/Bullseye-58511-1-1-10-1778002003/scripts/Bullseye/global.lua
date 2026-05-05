local world = require("openmw.world")
local types = require("openmw.types")
local storage = require("openmw.storage")

local sectionNearHit = storage.globalSection("SettingsBullseye_nearHit")

local function retrieveAmmo(eventData)
    local ammoItem = world.createObject(eventData.itemRecordId, 1)
    ---@diagnostic disable-next-line: discard-returns
    ammoItem:moveInto(eventData.actor)
end

local function arrowLanded(eventData)
    local aggroEnabled = sectionNearHit:get("nearHitAggroEnabled")
    if not aggroEnabled then return end

    local arrowPos = eventData.position
    for _, actor in ipairs(world.activeActors) do
        local distance = (actor.position - arrowPos):length()
        local isDead = actor.type.isDead(actor)
        if distance > sectionNearHit:get("aggroDistance")
            or isDead
            or not actor.isValid(actor)
            or actor.type == types.Player
        then
            goto continue
        end

        actor:sendEvent("Bullseye_modifyFight")

        ::continue::
    end
end

return {
    eventHandlers = {
        Bullseye_retrieveAmmo = retrieveAmmo,
        -- requires Arrow Stick mod to work
        ArrowStick_PlaceNewArrow = arrowLanded,
    }
}
