--[[
	Mod:Sneak Beneath ( Modernized 1st Person Experience - Sneak addon )
	Author: rhjelte
	Version: 1.1.1
]]--
local data
local addonBridge
local config = {}
local this = {}
this.wasSneakingLastFrame = false
local Modernized1stPersonExperience_addonBridgeData = {}
local allowedToSendMessage = false

local function lerp(start, goal, alpha)
    return start + (goal - start)*alpha
end

-- Check above us to see if there is place to stand.
local function spaceToStand()
    -- Get the players normal (scale == 1) bounding box, and identify where the four corners would be for that.
    local playerPosition = tes3.mobilePlayer.position
    local rightDirection = tes3.player.rightDirection
    local forwardDirection = tes3.player.forwardDirection

    local leftBehind = playerPosition + rightDirection * -this.savedBoundSize.x * 0.5 + rightDirection * -config.horizontalPadding
    leftBehind = leftBehind + forwardDirection * -this.savedBoundSize.y * 0.5 + forwardDirection * -config.horizontalPadding

    local leftInfront = playerPosition + rightDirection * -this.savedBoundSize.x * 0.5 + rightDirection * -config.horizontalPadding
    leftInfront = leftInfront + forwardDirection * this.savedBoundSize.y * 0.5 + forwardDirection * config.horizontalPadding

    local rightBehind = playerPosition + rightDirection * this.savedBoundSize.x * 0.5 + rightDirection * config.horizontalPadding
    rightBehind = rightBehind + forwardDirection * -this.savedBoundSize.y * 0.5 + forwardDirection * -config.horizontalPadding

    local rightInfront = playerPosition + rightDirection * this.savedBoundSize.x * 0.5 + rightDirection * config.horizontalPadding
    rightInfront = rightInfront + forwardDirection * this.savedBoundSize.y * 0.5 + forwardDirection * config.horizontalPadding

    -- Ray cast in all four corners and the middle of the hitbox straight up
    local positions = {
        leftBehindCorner = leftBehind,
        leftInfrontCorner = leftInfront,
        rightBehindCorner = rightBehind,
        rightInfrontCorner = rightInfront,
        middle = playerPosition
    }

    for _, corner in pairs(positions) do
        local ray = tes3.rayTest({
            position = corner,
            direction = tes3.player.upDirection,
            maxDistance = this.savedBoundSize.z + config.verticalPadding,
            ignore = {
                tes3.player,
            },
            findAll = true -- We need to find all, as water is a hit, and this means wading in water would always allow us to stand up, even if there was a low bridge above.
        })
        if ray then -- Check all hits
            for _, hit in pairs(ray) do
                if hit.reference then -- Check so what we are hitting has a reference. Water surface triggers a hit without a reference, so we can't just see if hit is not nil.
                    if not hit.reference.hasNoCollision then
                        return false
                    end
                end
            end
        end
    end
    return true
end

-- This function is called from a timer to allow new messages again
-- If not on a timer, the game would fire several messages at a single frame.
local function messageCooldown()
    allowedToSendMessage = true
end

-- Messages are shown to the player when they try to stand up, but there is no space.
-- Messages for all races but Khajiit
local firstPersonMessages = {
    "Too tight. I need more space to stand up.",
    "Need to find a more open place to get up.",
    "I will hit my head if I stand up now.",
}

-- Messages for Khajiit
local firstPersonkahjiitMessages = {
    "Khajiit needs more space to stretch their legs.",
    "This one is too big to stand here."
}

-- Messages in third person for those that prefer it
local thirdPersonMessages = {
    "There is not enough space to stand up.",
    "You need to find a more open area to get up.",
    "It's to cramp to stand up.",
}

-- Send message whenever not allowed to stand up
local function sendMessage()
    math.randomseed(tes3.worldController.systemTime,tes3.player.position.x)
    if config.firstPersonMessages then
        if tes3.player.object.race == tes3.findRace("Khajiit") then
            tes3.messageBox(firstPersonkahjiitMessages[math.random(1, math.random(#firstPersonkahjiitMessages))])
        else
            tes3.messageBox(firstPersonMessages[math.random(1, math.random(#firstPersonMessages))])
        end
    else
        tes3.messageBox(thirdPersonMessages[math.random(1, math.random(#thirdPersonMessages))])
    end
    allowedToSendMessage = false
    timer.start({ duration = config.messageCooldown, callback = messageCooldown })
end

-- Check if player is pressing the switch to third person button.
-- Third person also means scaling up to full size, so if there is no place, don't allow it.
local function keyBindTestedCallback(e)
    if not e.result then
        return
    end

    if e.keybind == tes3.keybind.togglePOV --[[or e.keybind == tes3.keybind.sneak]] then -- The keybind for sneak always return FALSE in this event. Probably due to Morrowind Code Patch, so need to check for sneak in a different way.
        if tes3.mobilePlayer.isSneaking and not tes3.mobilePlayer.is3rdPerson then
            if not spaceToStand() then
                if allowedToSendMessage then
                    sendMessage()
                end
                return false
            end
        end
    end
end
event.register('keybindTested', keyBindTestedCallback)

-- Mimmick name of original mod for main function to make it easier to follow when reading both.
-- The code here should execute right after the main mod.
local function headBob(e)
    local animController = e.animationController
    
    -- Reset everything if mod is not enabled
    if not config.modEnabled or animController.is3rdPerson or animController.vanityCamera then
        tes3.player.scale = 1
        tes3.findGMST("fVanityDelay").value = this.vanityDelay
        return
    end

    -- Get needed values
    local dt = tes3.worldController.deltaTime
    if Modernized1stPersonExperience_Installed then
        Modernized1stPersonExperience_addonBridgeData = addonBridge.getValues()
    end

    -- Make sure the vanity camera play as usual unless the player is sneaking
    if tes3.mobilePlayer.isSneaking then
        tes3.findGMST("fVanityDelay").value = math.huge
    else
        tes3.findGMST("fVanityDelay").value = this.vanityDelay
    end

    -- Detect trying to stand up, check if OK, and force the player to sneak if not OK. Interacts with Modernized 1st Person Experience as a speedy bump up, then down with the camera.
    if this.wasSneakingLastFrame and not tes3.mobilePlayer.isSneaking and not tes3.mobilePlayer.is3rdPerson then
        if not spaceToStand() then
            tes3.mobilePlayer.forceSneak = true
            e.cameraTransform.translation = this.lastCameraPosition or e.cameraTransform.translation
            sendMessage()
        end
    end

    -- Everything we want to do while Modernized 1st Person Experience is installed
    if Modernized1stPersonExperience_Installed and Modernized1stPersonExperience_addonBridgeData.config.modEnabled and Modernized1stPersonExperience_addonBridgeData.config.sneakCameraSmoothingEnabled then
        if tes3.mobilePlayer.isSneaking then
            tes3.player.scale = lerp(tes3.player.scale, 1 - (Modernized1stPersonExperience_addonBridgeData.config.sneakCameraHeight * 0.01), 1 - math.exp(-dt * Modernized1stPersonExperience_addonBridgeData.config.sneakCameraSmoothing))
        else
            tes3.player.scale = lerp(tes3.player.scale, 1, 1 - math.exp(-dt * Modernized1stPersonExperience_addonBridgeData.config.sneakCameraSmoothing))
        end
    -- If Modernized 1st Person Experience is NOT installed we do this instead (light version without smooth scaling, but still as functional)
    else
        if tes3.mobilePlayer.isSneaking then
            tes3.player.scale = 1 - (tes3.findGMST(tes3.gmst.i1stPersonSneakDelta).value/100)
        else
            tes3.player.scale = 1
        end
    end
    this.wasSneakingLastFrame = tes3.mobilePlayer.isSneaking
    this.lastCameraPosition = e.cameraTransform.translation
end
event.register(tes3.event.cameraControl, headBob, {priority = 9999})

-- Get the player speed
local function calcMoveSpeedCallback(e)
    if config.modEnabled then
        if tes3.mobilePlayer.isSneaking then
            e.speed = e.speed * (1 / (e.reference.scale * e.reference.object.scale))
        end
    end
end

event.register(tes3.event.calcMoveSpeed, calcMoveSpeedCallback, {priority = -10001}) -- Priority is one after Modernized 1st Person Experience

local function loadedCallback(e)
    tes3.player.data.sneakBeneath = tes3.player.data.sneakBeneath or {}
    data = tes3.player.data.sneakBeneath

    tes3.player.scale = 1

    this.savedBoundSize = tes3.mobilePlayer.boundSize

    if data.savedWhileSneaking == true then
        tes3.mobilePlayer.forceSneak = true
        if Modernized1stPersonExperience_Installed then
            tes3.player.scale = 1 - (Modernized1stPersonExperience_addonBridgeData.config.sneakCameraHeight * 0.01)
        else
            tes3.player.scale = 1 - (tes3.findGMST(tes3.gmst.i1stPersonSneakDelta).value/100)
        end
    end
end
event.register(tes3.event.loaded, loadedCallback)

local function saveCallback(e)
    if tes3.mobilePlayer.isSneaking then
        data.savedWhileSneaking = true
    else
        data.savedWhileSneaking = false
    end
end
event.register(tes3.event.save, saveCallback)

-- Set the scale back to small if sneaking when exiting the menu
local function menuClosed(e)
    tes3.player.scale = this.playerScale or 1
end
event.register(tes3.event.menuExit, menuClosed)

-- Scale also affects the portrait in the inventory menu so set it to 1 when opening the menu
local function menuOpened(e)
    this.playerScale = tes3.player.scale
    tes3.player.scale = 1
    tes3ui.updateInventoryCharacterImage()
end
event.register(tes3.event.menuEnter, menuOpened)

-- During initialization we check if we use values from Modernized 1st Person Experience or not
event.register(tes3.event.initialized, function()
    -- If Vanity can automatically be set, we can will be moved around in place when sneaking. So we don't allow it when sneaking
    this.vanityDelay = tes3.findGMST("fVanityDelay").value
    addonBridge = include("Modernized 1st Person Experience.addonBridge")
    if not addonBridge then
        Modernized1stPersonExperience_Installed = false
        print("[Modernized 1st Person Experience - Sneak addon] Could not localize Modernized 1st Person Experience. Interop not active.")
    else
        Modernized1stPersonExperience_Installed = true
        print("[Modernized 1st Person Experience - Sneak addon] Localized Modernized 1st Person Experience. Interop active.")
    end
    print("[Modernized 1st Person Experience - Sneak addon] initialized")
end, {priority = -100001})

-- Register the MCM
event.register(tes3.event.modConfigReady, function()
    require("Modernized 1st Person Experience - Sneak addon.mcm")
	config = require("Modernized 1st Person Experience - Sneak addon.config").loaded
end)