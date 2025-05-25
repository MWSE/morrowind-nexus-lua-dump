local common = require("mer.darkShard.common")
local logger = common.createLogger("telescope")

local shader = require("mer.darkShard.shaders.telescope")
local Telescope = require("mer.darkShard.components.Telescope")
local Comet = require("mer.darkShard.components.Comet")
local Quest = require("mer.darkShard.components.Quest")
local ReferenceManager = require("CraftingFramework").ReferenceManager
--ReferenceManager to replace vanilla telescope with custom telescope
ReferenceManager:new{
    id = "DarkShard:Telescope",
    onActivated = function(self, reference)
        logger:debug("Replacing telescope")
        Telescope.replace(reference)
    end,
    requirements = function(self, reference)
        return reference.object.id:lower() == Telescope.vanila_id
    end
}

--Update shader zoom with mouse wheel
---@param e mouseWheelEventData
event.register("mouseWheel", function(e)
    if common.config.mcm.zoomUsingPageKeys then return end
    if not shader.enabled then return end
    local currentZoom = Telescope.getZoom()
    local newZoom = currentZoom + e.delta * Telescope.ZOOM_STEP
    newZoom = math.clamp(newZoom, Telescope.ZOOM_MIN, Telescope.ZOOM_MAX)
    Telescope.setZoom(newZoom)
end)

---@param e enterFrameEventData
local function onEnterFrameZoomUp(e)
    if not shader.enabled then
        event.unregister("enterFrame", onEnterFrameZoomUp)
        return
    end
    local currentZoom = Telescope.getZoom()
    local direction = 1
    local newZoom = currentZoom + Telescope.ZOOM_HOLD_PER_SECOND * direction * e.delta
    newZoom = math.clamp(newZoom, Telescope.ZOOM_MIN, Telescope.ZOOM_MAX)
    Telescope.setZoom(newZoom)
end

local function startZoomHoldUp()
    event.register("enterFrame", onEnterFrameZoomUp)
    local function onKeyUp(e)
        if e.keyCode == tes3.scanCode.pageUp then
            event.unregister("enterFrame", onEnterFrameZoomUp)
            event.unregister("keyUp", onKeyUp)
        end
    end
    event.register("keyUp", onKeyUp)
end

---@param e enterFrameEventData
local function onEnterFrameZoomDown(e)
    if not shader.enabled then
        event.unregister("enterFrame", onEnterFrameZoomDown)
        return
    end
    local currentZoom = Telescope.getZoom()
    local direction = -1
    local newZoom = currentZoom + Telescope.ZOOM_HOLD_PER_SECOND * direction * e.delta
    newZoom = math.clamp(newZoom, Telescope.ZOOM_MIN, Telescope.ZOOM_MAX)
    Telescope.setZoom(newZoom)
end

local function startZoomHoldDown()
    event.register("enterFrame", onEnterFrameZoomDown)
    local function onKeyUp(e)
        if e.keyCode == tes3.scanCode.pageDown then
            event.unregister("enterFrame", onEnterFrameZoomDown)
            event.unregister("keyUp", onKeyUp)
        end
    end
    event.register("keyUp", onKeyUp)
end

--Update shader zoom with page up and page down
---@param e keyDownEventData
event.register("keyDown", function(e)
    if not common.config.mcm.zoomUsingPageKeys then return end
    if not shader.enabled then return end
    if e.keyCode == tes3.scanCode.pageUp  then
        startZoomHoldUp()
    end
    if e.keyCode == tes3.scanCode.pageDown then
        startZoomHoldDown()
    end
end)

event.register("activate", function(e)
    if e.activator == tes3.player then
        local ref = e.target
        if Telescope.isObservatory(ref) then
            logger:debug("Activating telescope")
            Telescope.activate{ telescopeRef = ref, isObservatory = true }
        end
        if Telescope.isTelescope(ref) then
            logger:debug("Activating telescope")
            Telescope.openMenu{ telescopeRef = ref }
        end
    end
end)

---Exit on activate key
---@param e keyDownEventData
event.register("keyDown", function(e)
    if e.keyCode == tes3.getInputBinding(tes3.keybind.activate).code then
        if Telescope.isActive() then
            logger:debug("Deactivating telescope")
            Telescope.deactivate{ isObservatory = Telescope.getActiveTelescope() == nil }
        end
    end
end)


event.register("save", function()
    if Telescope.isActive() then
        logger:debug("Preventing save while telescope is active")
        return false
    end
end)



---Block looking down while telescope is active
---@param e simulateEventData
event.register("simulate", function(e)
    if Telescope.isActive() and not Telescope.getActiveTelescope() then
        Telescope.blockLookingDown()
    end
end)



event.register("loaded", function()
    shader.enabled = false
    timer.start{
        duration = 0.5,
        iterations = -1,
        callback = function()
            local mainQuest = Quest.quests.afq_main
            local triangulateQuest = Quest.quests.afq_up_triangle
            local cometVisible = mainQuest:isAfter(mainQuest.stages.findComet)
                and Telescope.isActive()
                and (not Telescope.getCometSeen())
                and (Telescope.getZoomLevel() > 0.5)
                and Comet.isEnabled()
                and Comet.isInView()
                and Telescope.isObservatory()

            if cometVisible then
                --lookingAtComet used to ensure player looks in that direction for half a second at least
                if common.config.tempData.lookingAtComet then
                    if Telescope.isCalibrated() then
                        Telescope.setCometSeen()
                        mainQuest:advanceToStage(mainQuest.stages.seesComet)
                        tes3.addTopic{ topic = "темный осколок", updateGUI = true }
                        if Telescope.getCometSeenCount() >= 3 then
                            triangulateQuest:advanceToStage(triangulateQuest.stages.triangulationComplete)
                        end
                        tes3.messageBox{
                            message = Telescope.getCalibrationMessage()
                        }
                    else
                        tes3.messageBox{
                            message = Telescope.getUncalibratedMessage()
                        }
                    end
                else
                    common.config.tempData.lookingAtComet = true
                end
            else
                common.config.tempData.lookingAtComet = false
            end
        end
    }
end)