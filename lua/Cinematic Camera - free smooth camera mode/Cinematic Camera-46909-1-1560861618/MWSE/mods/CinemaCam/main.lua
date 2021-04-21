local cinematicMode = false

local cameraSpeed = 10
local cameraSmooth = 0.005

local cameraObj

local cameraPos = tes3vector3.new(0,0,0)
local cameraPosTarget = tes3vector3.new(0,0,0)

local cameraRot = tes3vector3.new(0,0,0)
local cameraRotTarget = tes3vector3.new(0,0,0)

local camera
local cameraParentOrig


----------------------------------
--Enter the cinamtic mode

local settingsConfig = mwse.loadConfig("CinemaCam")
if (settingsConfig == nil) then
    settingsConfig =
    {
        speed = 10,
        smooth = 0.5,
        quickEnter = false,
        savedPos =
        {
            {0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},
            {0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},
            {0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},{0,0,0,0,0,0,0,0},
            {0,0,0,0,0,0,0,0}
        }
    }
end

local weatherStatic = false

local function SettingsInitialize()
    --Initialize
    cameraSpeed = settingsConfig.speed
    cameraSmooth = settingsConfig.smooth / 1000
end

local function EnterCinematicMode()
    SettingsInitialize()

    cameraObj = mwscript.placeAtPC({object = "Collision Wall - INVISO!!", count = 1, distance = 0, direction = 0}) --Spawn object to attach camera controller to

    camera = tes3.worldController.worldCamera.camera
    cameraParentOrig = tes3.worldController.worldCamera.camera.parent

    --Initialize variables
    cameraPos = tes3vector3.new(cameraObj.position.x, cameraObj.position.y, cameraObj.position.z)
    cameraPosTarget = cameraPos:copy()
    cameraRot = tes3vector3.new(cameraObj.orientation.x, cameraObj.orientation.y, cameraObj.orientation.z)
    cameraRotTarget = cameraRot:copy()

    --attach camera
    cameraObj.sceneNode:attachChild(camera)

    --Player lock
    tes3.player.mobile.invisibility = 100
    tes3.player.mobile.waterBreathing = 100
    tes3.player.mobile.controlsDisabled = true
    tes3.player.mobile.mouseLookDisabled = true
    tes3.player.mobile.viewSwitchDisabled = true
    tes3.player.mobile.vanityDisabled = true

    --Finish
    cinematicMode = true
end

local function LeaveCinematicMode()
    cameraParentOrig:attachChild(camera)

    --Player unlock
    tes3.player.mobile.invisibility = 0
    tes3.player.mobile.waterBreathing = 0
    tes3.player.mobile.controlsDisabled = false
    tes3.player.mobile.mouseLookDisabled = false
    tes3.player.mobile.viewSwitchDisabled = false
    tes3.player.mobile.vanityDisabled = false

    --Remove side effects
    weatherStatic = false
    mwscript.getDelete({reference = cameraObj, result = true})

    --End
    cinematicMode = false
end

local function EnterCinematicModeKey(e)


    if(e.isControlDown == true) then
        if(cinematicMode == false) then
            if (settingsConfig.quickEnter == true) then
                EnterCinematicMode()
            end
        else
            LeaveCinematicMode()
        end
    end
end
event.register("keyDown", EnterCinematicModeKey, { filter = 45 }) -- X


----------------------------------


local function Lerp(a, b, t)
    return a + (b - a) * t
end


----------------------------------
--Input

local axisForward = 0
local axisLeft = 0
local axisUp = 0

local function KeyControlPressed(e)
    if(cinematicMode == false) then
        return
    end

    if(e.keyCode == 17) then axisForward = 1 end -- W
    if(e.keyCode == 31) then axisForward = -1 end -- S

    if(e.keyCode == 30) then axisLeft = 1 end -- A
    if(e.keyCode == 32) then axisLeft = -1 end -- D

    if(e.keyCode == 16) then axisUp = 1 end -- Q
    if(e.keyCode == 18) then axisUp = -1 end -- E
end
event.register("keyDown", KeyControlPressed)

local function KeyControlReleased(e)
    if(cinematicMode == false) then
        return
    end

    if(e.keyCode == 17 or e.keyCode == 31) then
        axisForward = 0
    end
    if(e.keyCode == 30 or e.keyCode == 32) then
        axisLeft = 0
    end
    if(e.keyCode == 16 or e.keyCode == 18) then
        axisUp = 0
    end

end
event.register("keyUp", KeyControlReleased)


local function CameraStop()
    cameraPosTarget = cameraPos
    cameraRotTarget = cameraRot
end
event.register("key", CameraStop,  { filter = 19 }) -- R

local function MouseLook(e)
    if(cinematicMode == false) then
        return
    end

    cameraRotTarget = tes3vector3.new(cameraRotTarget.x + e.deltaY * 0.01, cameraRotTarget.y, cameraRotTarget.z + e.deltaX * 0.01)
end
event.register("mouseAxis", MouseLook)

local function SpeedControl(e)
    if(cinematicMode == false) then
        return
    end

    if(e.isControlDown == false) then
        cameraSpeed = cameraSpeed + e.delta * 0.02
        cameraSpeed = math.clamp(cameraSpeed, 0.1, 300)
    end
    if(e.isControlDown == true) then
        cameraSmooth = cameraSmooth + e.delta * 0.00002
        cameraSmooth = math.clamp(cameraSmooth, 0.001, 1)
    end
end
event.register("mouseWheel", SpeedControl)


----------------------------------
--Camera controlling


local cameraControlsEnabled = true

local function ControlCamera()
    if(cinematicMode == false) then
        return
    end

    --cameraPosTarget = tes3vector3.new(cameraPosTarget.x + axisForward, cameraPosTarget.y + axisLeft, cameraPosTarget.z + axisUp)

    local cameraRotMatrix = cameraObj.sceneNode.worldTransform.rotation

    local cameraMovementVector = tes3vector3.new(-axisLeft * cameraSpeed, axisForward * cameraSpeed, axisUp * cameraSpeed)


    cameraPosTarget = cameraPosTarget + (cameraRotMatrix * cameraMovementVector)
    cameraPos = tes3vector3.new(Lerp(cameraPos.x, cameraPosTarget.x, cameraSmooth), Lerp(cameraPos.y, cameraPosTarget.y, cameraSmooth), Lerp(cameraPos.z, cameraPosTarget.z, cameraSmooth))

    cameraObj.position = cameraPos

    cameraRot = tes3vector3.new(Lerp(cameraRot.x, cameraRotTarget.x, cameraSmooth), Lerp(cameraRot.y, cameraRotTarget.y, cameraSmooth), Lerp(cameraRot.z, cameraRotTarget.z, cameraSmooth))

    local mx = tes3matrix33.new()
    local mz = tes3matrix33.new()
    mx:toRotationX(cameraRot.x)
    mz:toRotationZ(cameraRot.z)
    mz = mz * mx
    cameraObj.orientation = mz:toEulerXYZ()
    --cameraObj.orientation = tes3vector3.new(cameraRot.x * math.cos(cameraRot.z), cameraRot.x * -math.sin(cameraRot.z), cameraRot.z)

    tes3.player.mobile.reference.position = cameraObj.position
end
event.register("simulate", ControlCamera)


----------------------------------
--Save and load position


local positionMemory =
{
    position = tes3vector3.new(0,0,0),
    rotation = tes3vector3.new(0,0,0),
    cellX = 0,
    cellY = 0,
    assigned = false
}
for i = 0, 10, 1 do
    table.insert(positionMemory, {})
end

local function initializePositionMemory()
    for i = 1, 10, 1 do
        if(settingsConfig.savedPos[i][1] ~= 0 and settingsConfig.savedPos[i][1] ~= 0) then
            positionMemory[i].position = tes3vector3.new(settingsConfig.savedPos[i][1], settingsConfig.savedPos[i][2], settingsConfig.savedPos[i][3])
            positionMemory[i].rotation = tes3vector3.new(settingsConfig.savedPos[i][4], settingsConfig.savedPos[i][5], settingsConfig.savedPos[i][6])
            positionMemory[i].cellX = settingsConfig.savedPos[i][7]
            positionMemory[i].cellY = settingsConfig.savedPos[i][8]
            positionMemory[i].assigned = true
        end
    end
end
event.register("loaded", initializePositionMemory)

local function savePositionMemory(n)
    local cell = tes3.getPlayerCell()

    positionMemory[n].position = tes3vector3.new(cameraObj.position.x, cameraObj.position.y, cameraObj.position.z)
    positionMemory[n].rotation = tes3vector3.new(cameraObj.orientation.x, cameraObj.orientation.y, cameraObj.orientation.z)

    if(cell.isInterior == false) then
        positionMemory[n].cellX = cell.gridX
        positionMemory[n].cellY = cell.gridY
    end

    positionMemory[n].assigned = true

    settingsConfig.savedPos[n] = {positionMemory[n].position.x, positionMemory[n].position.y, positionMemory[n].position.z,
                        positionMemory[n].rotation.x, positionMemory[n].rotation.y, positionMemory[n].rotation.z,
                        positionMemory[n].cellX, positionMemory[n].cellY}
    json.savefile("config/CinemaCam", settingsConfig)
end

local function loadPositionMemory(n)
    if(positionMemory[n].assigned == false) then return end

    cameraPosTarget = positionMemory[n].position
    cameraRotTarget = positionMemory[n].rotation
end

local function jumpToPositionMemory(n)
    if(positionMemory[n].assigned == false) then return end

    cameraPosTarget = positionMemory[n].position
    cameraRotTarget = positionMemory[n].rotation
    cameraPos = positionMemory[n].position
    cameraRot = positionMemory[n].rotation

    local cell = tes3.getPlayerCell()
    if(cell.isInterior == false) then
        mwscript.positionCell{ reference = tes3.player, x = 8192 * positionMemory[n].cellX + 4096, y = 8192 * positionMemory[n].cellY + 4096, z = 0, cell = "Exterior" }
    end
end

local function saveMemoryInput(e)
    if(e.pressed) then
        if(e.isControlDown == true) then
            if(e.keyCode > 1 and e.keyCode < 12) then -- number keys
                savePositionMemory(e.keyCode - 1)
            end
        end
    end
end
event.register("key", saveMemoryInput)

local function loadMemoryInput(e)

    if(e.pressed) then
        if(positionMemory[e.keyCode - 1].assigned == true) then
            if(e.isControlDown == false) then
                if(e.isShiftDown == false) then
                    if(e.keyCode > 1 and e.keyCode < 12) then -- number keys
                        loadPositionMemory(e.keyCode - 1)
                    end
                else
                    if(e.keyCode > 1 and e.keyCode < 12) then -- number keys
                        jumpToPositionMemory(e.keyCode - 1)
                    end
                end
            end
        end
    end
end
event.register("key", loadMemoryInput)


----------------------------------
--Weather locking


local weatherCurrent

local function WeatherPause()
    if(cinematicMode == false) then
        return
    end

    if(weatherStatic == false) then
        weatherStatic = true
        weatherCurrent = tes3.getCurrentWeather()
        mwse.log("[CinemaCam] Weather paused.")
        return
    end
    if(weatherStatic == true) then
        weatherStatic = false
        mwse.log("[CinemaCam] Weather resumed.")
        return
    end
end
event.register("keyDown", WeatherPause,  { filter = 25 }) -- P

local function WeatherTransition(e)
    if(weatherStatic == true) then
        tes3.getWorldController().weatherController:switchTransition(weatherCurrent)
    end
end
event.register("weatherTransitionStarted", WeatherTransition)
event.register("weatherChangedImmediate", WeatherTransition)
event.register("weatherCycled", WeatherTransition)


----------------------------------
--Security

local function onSave()
    if(cinematicMode == true) then
        return false
    end
end
event.register("save", onSave)

----------------------------------
--MCM


local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")

    local template = EasyMCM.createTemplate
    {
        name = "Cinematic Camera Mode",
        headerImagePath = "textures/cinemacam.dds"
    }

    local page = template:createPage()

    local information = page:createCategory("Information")

    information:createInfo
    {
        text = "WASD - move camera\n" ..
        "QE - move camera up and down\n" ..
        "mouse scrolls - change speed\n" ..
        "ctrl + mouse scroll - change smoothing\n" ..
        "r - pause camera moving\n" ..
        "p - pause the weather\n" ..
        "ctrl + number key 0 to 9 - save current position\n" ..
        "number key - smooth go to position\n" ..
        "shift + number key - instantly load position\n" ..
        "ctrl + x - leave cinematic mode/enter mode when Quick Enter enabled"
    }

    local category = page:createCategory("Settings")

    category:createButton
    ({
        buttonText = "Enter Cinematic Mode",
        inGameOnly = true,
        callback = function()
            EnterCinematicMode()
        end
    })

    category:createSlider
    {
        label = "Camera default speed",
        min = 0.1,
        max = 300,
        variable = EasyMCM.createTableVariable{
            id = "speed",
            table = settingsConfig
        }
    }

    category:createSlider
    {
        label = "Camera default smoothing",
        min = 0.1,
        max = 100,
        variable = EasyMCM.createTableVariable{
            id = "smooth",
            table = settingsConfig
        }
    }

    category:createOnOffButton
    ({
        label = "Quick enter",
        description = "Enter cinematic mode by pressing ctrl + X in game.",
        variable = EasyMCM.createTableVariable{
            id = "quickEnter",
            table = settingsConfig
        }
    })

    template:saveOnClose("CinemaCam", settingsConfig)

    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)