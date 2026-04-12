local log = mwse.Logger.new()

local config = require("sa.atm.config")

local CH = {}

local crosshair = {}
local function createCrosshair()
    if tes3ui.menuMode() then return end
	if crosshair.parent == nil then
        log:debug("No crosshair parent found, aborting crosshair creation.")
		return
	end

    local existing = crosshair.parent:findChild("SA_ATM_block")
    if existing then
        log:debug("Existing crosshair block found, destroying it.")
        existing:destroy()
    end

	crosshair.main = crosshair.parent:createBlock{
        id = "SA_ATM_block"
    }
	crosshair.main.layoutOriginFractionX = 0.5
	crosshair.main.layoutOriginFractionY = 0.5
	crosshair.main.autoWidth = true
	crosshair.main.autoHeight = true

	local redTex = "textures/red_crosshair.dds"
    local success = tes3.getFileExists(redTex)
    log:debug("Checking for red crosshair texture: %s (exists: %s)", redTex, tostring(success))
    if success then
        crosshair.red = crosshair.main:createImage({ path = redTex })
        crosshair.red.visible = false
        crosshair.red.scaleMode = true
        crosshair.red.width = 32
        crosshair.red.height = 32
        crosshair.red.alpha = 0
        log:debug("Red crosshair image created.")
    else
        crosshair.red = nil
        log:warn("Red crosshair texture not found: %s", redTex)
    end

    local blueTex = "textures/blue_crosshair.dds"
    success = tes3.getFileExists(blueTex)
    log:debug("Checking for blue crosshair texture: %s (exists: %s)", blueTex, tostring(success))
    if success then
        crosshair.blue = crosshair.main:createImage({ path = blueTex })
        crosshair.blue.visible = false
        crosshair.blue.scaleMode = true
        crosshair.blue.width = 32
        crosshair.blue.height = 32
        crosshair.blue.alpha = 0
        log:debug("Blue crosshair image created.")
    else
        crosshair.blue = nil
        log:warn("Blue crosshair texture not found: %s", blueTex)
    end

	crosshair.main:updateLayout()
    log:debug("Crosshair layout updated.")

end

local function onMenuMultiCreated(e)
    if not tes3.player then return end
	if not e.newlyCreated then
        log:debug("MenuMulti not newly created, skipping crosshair setup.")
		return
	end
    log:debug("MenuMulti created, setting up crosshair.")
	crosshair = {}
	crosshair.parent = e.element
	createCrosshair()
end
event.register(tes3.event.uiActivated, onMenuMultiCreated, { filter = "MenuMulti" })

-- Shows a modified crosshair for 1 second, fading in and out
local timerHandle_ATM = nil
function CH.showModifiedCrosshair(modifier)
    if not crosshair or not crosshair.red or not crosshair.blue then
        log:warn("Crosshair images not initialized, cannot show modified crosshair.")
        return
    end
    modifier = modifier and math.round(modifier,1) or 1
    local icon
    if modifier > 1 then
        icon = crosshair.red
        crosshair.blue.visible = false
        log:debug("Showing red crosshair for modifier %.2f", modifier)
    elseif modifier < 1 then
        icon = crosshair.blue
        crosshair.red.visible = false
        log:debug("Showing blue crosshair for modifier %.2f", modifier)
    else
        log:debug("Modifier is 1, not showing any crosshair feedback.")
        return
    end

    icon.visible = true
    icon.alpha = 0.0
    if timerHandle_ATM then
        timerHandle_ATM:cancel()
        crosshair.red.alpha = 0
        crosshair.blue.alpha = 0
        log:debug("Previous crosshair timer cancelled.")
    end

    -- Fade in fast, then fade out over slower
    local duration = 0.6
    local steps = 20
    local stepTime = duration / steps

    local currentStep = 0
    timerHandle_ATM = timer.start{
        type = timer.real,
        duration = stepTime,
        iterations = steps,
        callback = function()
            currentStep = currentStep + 1
            if currentStep <= steps / 16 then
                -- Fade in
                icon.alpha = currentStep / (steps / 16)
            else
                -- Fade out
                icon.alpha = 1.0 - ((currentStep - steps / 2) / (steps / 2))
            end
            if currentStep == steps then
                icon.alpha = 0
                log:debug("Crosshair feedback finished.")
            end
        end
    }
    log:debug("Started crosshair feedback timer.")
end
-- Copied from essential indicators
local function onLoaded(e)
	-- Hide the crosshair.We hide the niTriShape instead of the main niNode,
	-- because Bethesda appCull the main node to hide it in the menu.
    log:debug("Game loaded, creating crosshair.")
	createCrosshair()
end
event.register(tes3.event.loaded, onLoaded)


return CH
