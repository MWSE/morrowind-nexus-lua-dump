local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Action")

---@class GuarWhisperer.Action.onActionParams
---@field guar GuarWhisperer.GuarCompanion | GuarWhisperer.AI.GuarCompanion
---@field target tes3reference
---@field blockCantReachMessage boolean? Default: false Set to true to block the "can't reach" message
---@field activationDistance number? default: 100
---@field playGroup string The playgroup that plays when this ability is performed. E.g "idle2"
---@field actionDuration? number How long after the action started before triggering afterAction()
---@field afterAction? fun(e: GuarWhisperer.Action.onActionParams) A function that is called after the action is performed


---@class GuarWhisperer.Action
local Action = {}

---@param e GuarWhisperer.Action.onActionParams
function Action.moveToAction(e)
    logger:debug("moveToAction()")
    local safeTarget = tes3.makeSafeObjectHandle(e.target)
    e.guar.refData.previousAiState = e.guar.ai:getAI()
    e.guar.reference.mobile.isRunning = true
    e.guar.ai:moveTo(e.target.position)
    --Start simulate event to check if close enough to the reference
    local previousGuarPosition
    local previousTargetPosition = e.target.position:copy()
    local distanceTimer
    local function checkRefDistance()
        logger:debug("checkRefDistance()")
        if not e.guar:isValid() then
            distanceTimer:cancel()
            return
        end
        --for first frames during loading
        if not e.guar:isActive() then return end
        e.guar.reference.mobile.isRunning = true
        local distance = e.activationDistance or 100
        local currentPosition = e.guar.reference.position
        local currentDist = e.guar:distanceFrom(e.target)
        --Check if target has moved and update guar target movement
        if previousTargetPosition:distance(e.target.position) > distance then
            logger:debug("- Target moved, updating guar target movement")
            e.guar.ai:moveTo(e.target.position)
            previousTargetPosition = e.target.position:copy()
            return
        end
        --Check if still fetching
        local moving = previousGuarPosition == nil or  currentPosition:distance(previousGuarPosition) > 5
        local closeEnough = currentDist < distance
        if moving and not closeEnough then
            logger:debug("- Still moving")
            previousGuarPosition = e.guar.reference.position:copy()
        else
            logger:debug("- Finished moving")
            --check target is still valid
            if not (safeTarget and safeTarget:valid()) then
                logger:warn("Target is no longer valid")
                e.guar.ai:returnTo()
            --Check if guar got all the way there
            elseif currentDist > 500 then
                logger:warn("Couldn't reach target")
                if not e.blockCantReachMessage then
                    tes3.messageBox("Не смог добраться.")
                end
                e.guar.ai:restorePreviousAI()
            else
                logger:debug("- Reached target")
                if e.playGroup then
                    timer.delayOneFrame(function()
                        if not e.guar:isValid() then return end
                        e.guar.reference.mobile.isRunning = false
                        Action.playAnimation(e)
                    end)
                end
                if e.afterAction then
                    logger:debug("- has afterAction callback, starting Timer")
                    local duration = e.actionDuration or 1
                    timer.start{
                        type = timer.simulate,
                        duration = duration,
                        callback = function()
                            if not e.guar:isValid() then return end
                            if not safeTarget:valid() then
                                logger:warn("Target is no longer valid")
                                e.guar.ai:returnTo()
                                return
                            end
                            logger:debug("- Running afterAction callback")
                            e.afterAction(e)
                        end
                    }
                end
            end
            logger:debug("- Cancelling distanceTimer")
            distanceTimer:cancel()
        end
    end
    distanceTimer = timer.start{
        type = timer.simulate,
        iterations = -1,
        duration = 0.75,
        callback = checkRefDistance
    }
end

---@param e GuarWhisperer.Action.onActionParams
function Action.playAnimation(e)
    if e.playGroup then
        logger:debug("Playing animation %s", e.playGroup)
        tes3.playAnimation{
            reference = e.guar.reference,
            group = tes3.animationGroup[e.playGroup],
            loopCount = 0,
            startFlag = tes3.animationStartFlag.immediate
        }
    end
end

return Action