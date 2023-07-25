local common = require ("mer.Fishing.common")
local logger = common.createLogger("fishing")
local config = require("mer.fishing.config")
local FishingStateManager = require("mer.fishing.Fishing.FishingStateManager")
local FishingService = require("mer.fishing.Fishing.FishingService")
local FishingRod = require("mer.fishing.FishingRod.FishingRod")
local FishingSkill = require("mer.fishing.FishingSkill")

---Cast line if player attacks with a fishing rod
---@param e attackEventData
event.register("attackHit", function(e)
    if e.reference ~= tes3.player then return end
    logger:debug("Swing strength = %s",tes3.player.mobile.actionData.attackSwing)
    local fishingRod = FishingRod.getEquipped()
    if fishingRod then
        logger:debug("Player released attack with fishing rod")
        FishingService.release()
    end
end)

-- event.register("attackStart", function(e)
--     if e.reference ~= tes3.player then return end
--     local fishingRod = getFishingRod()
--     if fishingRod then
--         logger:debug("Player started attack with fishing rod")
--         fishingRod:startSwing()
--     end
-- end)

---Event if activate is mapped to mouse
---@param e mouseButtonUpEventData
event.register("mouseButtonDown", function(e)
    if not tes3.player then return end
    if tes3ui.menuMode() then return end
    if e.button == 0 then
        if not tes3.player.mobile.controlsDisabled then
            FishingService.startSwing()
        end
    end
end)

local swishSounds = {
    ["swishl"] = true,
    ["swishm"] = true,
    ["swishs"] = true,
    ["weapon swish"] = true,
    ["miss"] = true,
}
---Block vanilla weapon swish sounds when casting fishing line
---@param e addSoundEventData
event.register("addSound", function(e)
    local doBlockSound = e.reference == tes3.player
        and FishingStateManager.isState("CASTING")
        and swishSounds[e.sound.id:lower()]
    if doBlockSound then
        logger:debug("Blocking vanilla weapon swish sound")
        return false
    end
end, { priority = 500})



event.register("loaded", function()
    --fish bite timer
    local startFishBiteTimer
    ---comment
    ---@param interval number #The number of seconds between bites
    startFishBiteTimer = function(interval)
        timer.start{
            duration = interval,
            iterations = 1,
            callback = function()
                logger:trace("Fish bite timer finished")
                FishingService.triggerFish()
                startFishBiteTimer(FishingService.generateBiteInterval())
            end
        }
    end
    startFishBiteTimer(FishingService.generateBiteInterval())

    --Check any interim states and cancel
    local state = FishingStateManager.getCurrentState()

    local lure = FishingStateManager.getLure()
    if lure ~= nil or state ~= "IDLE" then
        logger:debug("Loaded while fishing - cancel")
        common.enablePlayerControls()
        FishingStateManager.endFishing()
    end

    for _, vfx in pairs(tes3.worldController.vfxManager.data) do
        if vfx.effectObject.id:lower() == "mer_lure_particle" then
            logger:debug("Deleting lure particle with maxAge: %s", vfx.maxAge)
            vfx.expired = true
        end
    end

end, { priority = -10} )

local blockMove = false
local function dontMove(e)
    if blockMove then
        if e.reference == tes3.player then
            if not FishingStateManager.isState("IDLE") then
                e.speed = 1e-5
            end
        end
    end
end
event.register(tes3.event.calcMoveSpeed, dontMove, { priority = -10000})

local blockActivate = true
local function dontActivate(e)
    if blockActivate then
        if e.activator == tes3.player then
            if not FishingStateManager.isState("IDLE") then
                logger:debug("Blocking activate while fishing")
                return false
            end
        end
    end
end
event.register(tes3.event.activate, dontActivate, { priority = 10000})

local cancelInMenu = false
event.register("menuEnter", function(e)
    if cancelInMenu then
        if not FishingStateManager.isState("IDLE") then
            logger:debug("Menu opened while fishing - cancel")
            FishingStateManager.endFishing()
        end
    end
end)

local function onChangeWeapon()
    if not FishingRod.isEquipped() then
        if not FishingStateManager.isState("IDLE") then
            logger:debug("Unequipped fishing rod while fishing - cancel")
            FishingStateManager.endFishing()
        end
    end
end
event.register("equipped", onChangeWeapon)
event.register("unequipped", onChangeWeapon)

event.register("simulate", function()
    local swimming = tes3.player.mobile.isSwimming
    local sheathed = not tes3.mobilePlayer.weaponReady
    if swimming or sheathed then
        local idleStates = {
            IDLE = true,
            BLOCKED = true
        }
        if not idleStates[FishingStateManager.getCurrentState()] then
            logger:debug("- CANCEL")
            FishingStateManager.endFishing()
            event.trigger("Fishing:Cancel")
        end
    end
end)
