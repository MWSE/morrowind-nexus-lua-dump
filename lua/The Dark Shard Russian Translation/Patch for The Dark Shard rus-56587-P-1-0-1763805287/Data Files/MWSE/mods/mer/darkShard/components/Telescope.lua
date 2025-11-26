local common = require("mer.darkShard.common")
local logger = common.createLogger("Telescope")
local TelescopeShader = require("mer.darkShard.shaders.telescope")
local Sky = require("mer.darkShard.components.Sky")
local SpellMaker = require("mer.darkShard.components.SpellMaker")
local CraftingFramework = require("CraftingFramework")
local Positioner = CraftingFramework.Positioner

---@class DarkShard.Telescope
local Telescope = {
    registeredObservatories = {},
    registeredTelescopes = {},

    vanila_id = "in_dwrv_scope00",
    object_id = "afq_dwrv_scope00",
    ZOOM_MIN = 1.2,
    ZOOM_MAX = 4.0,
    ZOOM_STEP = 0.0015,
    ZOOM_HOLD_PER_SECOND = 1.5,
    MENU_ID = "afq_dwrv_scope_menu",
    TELEPORT_HEIGHT = 20000
}

function Telescope.registerObservatory(id)
    Telescope.registeredObservatories[id:lower()] = true
end

function Telescope.registerTelescope(id)
    Telescope.registeredTelescopes[id:lower()] = true
end

function Telescope.isObservatory(ref)
    ref = ref or Telescope.getNearbyTelescope()
    return Telescope.registeredObservatories[ref.object.id:lower()]
end

function Telescope.isTelescope(ref)
    return Telescope.registeredTelescopes[ref.object.id:lower()]
end

function Telescope.getOrCreateLevitationAbility()
    return SpellMaker.createSpell{
        id = "afq_dwrv_scope_levitate",
        name = "Двемерский телескоп",
        castType = tes3.spellType.ability,
        effects = {
            {
                id = tes3.effect.levitate,
                rangeType = tes3.effectRange.self,
                min = 1,
                max = 1
            }
        }
    }
end

function Telescope.levitate()
    logger:debug("Levitating")
    tes3.addSpell{ reference = tes3.player, spell = Telescope.getOrCreateLevitationAbility() }
end

function Telescope.unlevitate()
    logger:debug("Unlevitating")
    tes3.removeSpell{ reference = tes3.player, spell = Telescope.getOrCreateLevitationAbility() }
end

---@return DarkShard.Resonator.Calibration
function Telescope.getTargetCalibration()
    local telescopeRef = Telescope.getNearbyTelescope()
    if not telescopeRef then
        logger:error("Failed to find nearby telescope")
        return { red = 1, green = 1, blue = 1 }
    end
    return telescopeRef.data.afq_telescopeTargetCalibration
        or { red = 1, green = 1, blue = 1 }
end

---@param calibration DarkShard.Resonator.Calibration
function Telescope.initTargetCalibration(calibration)
    local telescopeRef = Telescope.getNearbyTelescope()
    if not telescopeRef then
        logger:error("Failed to find nearby telescope")
        return
    end
    if not telescopeRef.data.afq_telescopeTargetCalibration then
        telescopeRef.data.afq_telescopeTargetCalibration = calibration
        telescopeRef.modified = true
        logger:debug("Target Calibration: red %s, green %s, blue %s",
            telescopeRef.data.afq_telescopeTargetCalibration.red,
            telescopeRef.data.afq_telescopeTargetCalibration.green,
            telescopeRef.data.afq_telescopeTargetCalibration.blue)
    end
end


---@param vanillaRef tes3reference? #The vanilla telescope reference. If not provided, the nearest telescope in the cell will be used
---@return tes3reference? #The new telescope reference
function Telescope.replace(vanillaRef)
    vanillaRef = vanillaRef or common.findInCell(Telescope.vanila_id, tes3.player.cell)
    if not vanillaRef then
        logger:error("Failed to find vanilla telescope reference")
        return
    end
    local newTelescopeReference = tes3.createReference{
        object = Telescope.object_id,
        position = vanillaRef.position:copy(),
        orientation = vanillaRef.orientation:copy(),
        cell = vanillaRef.cell
    }
    table.copy(vanillaRef.data, newTelescopeReference.data)
    vanillaRef:disable()
    return newTelescopeReference
end

---@param offsets DarkShard.Resonator.Calibration
function Telescope.setOffsets(offsets)
    TelescopeShader.RedOffset = offsets.red
    TelescopeShader.GreenOffset = offsets.green
    TelescopeShader.BlueOffset = offsets.blue
end

function Telescope.getOffsets()
    return {
        red = TelescopeShader.RedOffset,
        green = TelescopeShader.GreenOffset,
        blue = TelescopeShader.BlueOffset
    }
end

function Telescope.isCalibrated()
    return TelescopeShader.RedOffset == 0
    and TelescopeShader.GreenOffset == 0
    and TelescopeShader.BlueOffset == 0
end

---@return number
function Telescope.getCalibration()
    return 1 - (TelescopeShader.RedOffset +
    TelescopeShader.GreenOffset +
    TelescopeShader.BlueOffset) / 3
end

function Telescope.showMenu()
    local menu = tes3ui.createMenu{ id = Telescope.MENU_ID, fixedFrame = true }
    menu.absolutePosAlignX = 0.5
    menu.absolutePosAlignY = 0.01
    local block = menu:createBlock{ id = tes3ui.registerID("afq_dwrv_scope_menu_block") }
    block.flowDirection = "top_to_bottom"
    block.autoWidth = true
    block.autoHeight = true
    block.childAlignX = 0.5
    local header = block:createLabel{ text = "Двемерский телескоп" }
    header.color = tes3ui.getPalette("header_color")
    local isObservatory = (Telescope.getActiveTelescope() == nil)
    if isObservatory then
        local calibrationText = string.format("Калибровка: %d%%", Telescope.getCalibration() * 100)
        local calibrationLabel = block:createLabel{ text = calibrationText }
        calibrationLabel.color = tes3ui.getPalette("normal_color")
    end
    local zoomLabel = "- Вращайте колесо для масштабирования"
    if common.config.mcm.zoomUsingPageKeys then
        zoomLabel = "- Нажмите Page Up/Down для масштабирования"
    end
    block:createLabel{ text = zoomLabel }
    local activateCode = tes3.getInputBinding(tes3.keybind.activate).code
    ---@type string
    local activateText = table.find(tes3.scanCode, activateCode)
    block:createLabel{ text = string.format("- Нажмите %s для выхода", activateText:upper())}
end

function Telescope.hideMenu()
    local menu = tes3ui.findMenu(Telescope.MENU_ID)
    if menu then
        menu:destroy()
    end
end

---@param offsets DarkShard.Resonator.Calibration
function Telescope.updateOffsetData(offsets)
    logger:debug("Updating telescope offsets")
    local telescope = Telescope.getNearbyTelescope()
    if telescope then
        logger:debug("Found nearby telescope: %s", telescope)
        telescope.data.afq_telescopeOffsets = offsets
        telescope.modified = true
    else
        logger:error("Failed to find nearby telescope")
    end
end

function Telescope.getActiveTelescope()
    return tes3.player.tempData.afq_activeTelescope
        and tes3.player.tempData.afq_activeTelescope:valid()
        and tes3.player.tempData.afq_activeTelescope:getObject()
end

function Telescope.setActiveTelescope(ref)
    tes3.player.tempData.afq_activeTelescope = tes3.makeSafeObjectHandle(ref)
end

function Telescope.clearActiveTelescope()
    tes3.player.tempData.afq_activeTelescope = nil
end

---@param e { telescopeRef: tes3reference, isObservatory: boolean}
function Telescope.activate(e)
    logger:debug("Activating telescope: %s", e.telescopeRef)
    if Telescope.isActive() then
        logger:debug("Telescope already active")
        return
    end

    local offsets = e.telescopeRef.data.afq_telescopeOffsets

    if offsets then
        Telescope.setOffsets(offsets)
    elseif e.isObservatory then
        tes3.messageBox("Кажется, телескоп не работает.")
        return
    else
        Telescope.setOffsets({ red = 0, green = 0, blue = 0 })
    end

    common.config.tempData.telescopeActive = true

    tes3.setPlayerControlState{enabled = false }

    TelescopeShader.enabled = true
    TelescopeShader.HideGround = (e.isObservatory == true)

    common.config.tempData.previousZoomEnable = mge.camera.zoomEnable
    mge.camera.zoomEnable = true
    common.config.tempData.previousZoom = mge.camera.zoom
    Telescope.setZoom(Telescope.ZOOM_MIN)

    --Additional setup for Observatory Scopes
    if e.isObservatory then
        Sky.enable()
        common.config.tempData.activeTelescopeType = "observatory"
        common.config.tempData.activateTelescope_previousPosition = tes3.player.position:copy()
        common.config.tempData.activateTelescope_previousOrientation = tes3.player.orientation:copy()
        tes3.worldController.weatherController:switchImmediate(tes3.weather.clear)
        Telescope.levitate()
        tes3.positionCell{
            cell = tes3.player.cell,
            position = {
                tes3.player.position.x,
                tes3.player.position.y,
                tes3.player.position.z + Telescope.TELEPORT_HEIGHT
            },
            orientation = common.config.tempData.activateTelescope_previousTelescopeOrientation
                or tes3.player.orientation,
            reference = tes3.player
        }
        tes3.playSound{
            reference = tes3.player,
            sound = "Power Light",
            loop = true
        }
    else
        common.config.tempData.activeTelescopeType = "telescope"
        e.telescopeRef.sceneNode.appCulled = true
        Telescope.setActiveTelescope(e.telescopeRef)
    end
    event.trigger("DarkShard:EnableOrDisableComet")
    Telescope.showMenu()
end


---@param e { isObservatory?: boolean }
function Telescope.deactivate(e)
    TelescopeShader.enabled = false
    common.config.tempData.telescopeActive = false
    common.config.tempData.activateTelescope_previousTelescopeOrientation = tes3.player.orientation:copy()
    Telescope.hideMenu()
    tes3.setPlayerControlState{enabled = true }
    if e.isObservatory then
        Sky.disable()
        tes3.player.mobile.isFalling = false
        logger:debug("Restoring player position to (%s, %s, %s)", common.config.tempData.activateTelescope_previousPosition.x, common.config.tempData.activateTelescope_previousPosition.y, common.config.tempData.activateTelescope_previousPosition.z)
        tes3.positionCell{
            cell = tes3.player.cell,
            position = common.config.tempData.activateTelescope_previousPosition:copy(),
            orientation = common.config.tempData.activateTelescope_previousOrientation:copy(),
            reference = tes3.player,
            forceCellChange = true
        }
        logger:debug("Position: (%s, %s, %s)", tes3.player.position.x, tes3.player.position.y, tes3.player.position.z)

        Telescope.unlevitate()
        tes3.removeSound{
            reference = tes3.player,
            sound = "Power Light"
        }
        --If all offsets are 0, trigger TelescopeCalibrated event
        if Telescope.isCalibrated() then
            event.trigger("DarkShard:TelescopeCalibrated")
        end
    else
        local activeScope = Telescope.getActiveTelescope()
        if activeScope then
            activeScope.sceneNode.appCulled = false
        end
    end
    Telescope.clearActiveTelescope()
    if common.config.tempData.previousZoomEnable then
        mge.camera.zoomEnable = common.config.tempData.previousZoomEnable
    end
    if common.config.tempData.previousZoom then
        mge.camera.zoom = common.config.tempData.previousZoom
    end
    event.trigger("DarkShard:EnableOrDisableComet")
end

---@param e { telescopeRef: tes3reference }
function Telescope.openMenu(e)
    tes3ui.showMessageMenu{
        message = "Телескоп",
        buttons = {
            {
                text = "Использовать",
                callback = function()
                    logger:debug("Opening telescope menu")
                    local safeRef = tes3.makeSafeObjectHandle(e.telescopeRef)
                    timer.delayOneFrame(function()
                        if safeRef and safeRef:valid() then
                            Telescope.activate{ telescopeRef = safeRef:getObject(), isObservatory = false }
                        end
                    end)
                end
            },
            {
                text = "Переместить",
                callback = function()
                    Positioner.startPositioning{
                        target = e.telescopeRef,
                        nonCrafted = true,
                        placementSetting = "ground"
                    }
                end
            },
            {
                text = "Убрать",
                callback = function()
                    tes3.addItem{
                        reference = tes3.player,
                        item = e.telescopeRef.data.afq_Telescope_miscId,
                        count = 1
                    }
                    e.telescopeRef:delete()
                end
            }
        },
        cancels = true
    }
end


---@return boolean #True if the player is looking through the telescope
function Telescope.isActive()
    return common.config.tempData.telescopeActive
end


function Telescope.blockLookingDown()
    local euler = tes3.mobilePlayer.animationController.verticalRotation:toEulerZYX()
    local clampedPitch = math.clamp(euler.x, -math.pi/2, math.rad(-20))
    local rotX = tes3matrix33.new()
    rotX:toRotationX(clampedPitch)
    tes3.mobilePlayer.animationController.verticalRotation = rotX
end

function Telescope.getNearbyTelescope()
    local closestTelescope
    local closestDistance
    for ref in tes3.player.cell:iterateReferences() do
        if Telescope.registeredObservatories[ref.object.id:lower()] then
            if not closestTelescope then
                closestTelescope = ref
                closestDistance = tes3.player.position:distance(ref.position)
            else
                local newDistance = tes3.player.position:distance(ref.position)
                if newDistance < closestDistance then
                    closestTelescope = ref
                    closestDistance = newDistance
                end
            end
        end
    end
    return closestTelescope
end

--Get zoom as a value between 0 and 1
function Telescope.getZoomLevel()
    return mge.camera.zoom / Telescope.ZOOM_MAX
end

--Get raw zoom level
function Telescope.getZoom()
    return mge.camera.zoom
end

function Telescope.setZoom(newZoom)
    mge.camera.zoom = newZoom
end

--One view per telescope
--Keep track of which telescopes have triangulated
--and how many times
function Telescope.setCometSeen()
    local telescope = Telescope.getNearbyTelescope()
    if telescope then
        if not telescope.data.afq_cometSeen then
            telescope.data.afq_cometSeen = true
            common.config.persistent.cometsSeen = common.config.persistent.cometsSeen + 1
        end
        telescope.modified = true
    end
end

function Telescope.getCometSeen()
    local telescope = Telescope.getNearbyTelescope()
    return telescope and telescope.data.afq_cometSeen
end

function Telescope.getCometSeenCount()
    return common.config.persistent.cometsSeen
end

function Telescope.getCalibrationMessage()
    local hours = math.random(0, 23)
    local minutes = math.random(0, 59)
    local seconds = math.random(0, 59)
    local degrees = math.random(-90, 90)
    local arcminutes = math.random(0, 59)
    local arcseconds = math.random(0, 59)

    --RA: 13h 24m 17.6s, Dec: -07d 16m 44.2s
    return string.format("ЗАРЕГИСТРИРОВАНЫ НЕБЕСНЫЕ КООРДИНАТЫ\n{RA: %dh %dm %ds | Dec: %dd %dm %ds}",
        hours, minutes, seconds, degrees, arcminutes, arcseconds)
end

function Telescope.getUncalibratedMessage()
    return string.format("НЕВОЗМОЖНО УТОЧНИТЬ КООРДИНАТЫ\nКАЛИБРОВКА %d%%",
        Telescope.getCalibration() * 100)
end

return Telescope