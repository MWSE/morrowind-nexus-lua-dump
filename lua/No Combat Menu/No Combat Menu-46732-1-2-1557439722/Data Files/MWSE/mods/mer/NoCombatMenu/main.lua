
local configPath = "noCombatMenu"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = { 
        enable = true, 
        safeDistance = 1000
    }
end

local menuKeyCode
local substituteKeyCode = 5000
local menuInputMap
local inCombat

local function initialize()
    menuInputMap = tes3.worldController.inputController.inputMaps[19]
end

event.register(tes3.event.initialized, initialize)

local function checkInCombat(e)
    inCombat = true
    --check config
    if not config.enable then
        inCombat = false
    end
    --check menu
    if tes3.menuMode() then
        inCombat = false
    end

    --Find nearest enemy
    local minDistance = config.safeDistance
    local cell = tes3.getPlayerCell()

    local function checkHostileDistance(enemy)
        if not enemy.mobile then return end
        --Check enemy's hostile actors for the player
        local playerInHostileList
        for actor in tes3.iterate(enemy.mobile.hostileActors) do
            if actor.reference == tes3.player then
                playerInHostileList = true
                break
            end
        end
        if enemy.mobile.inCombat and playerInHostileList then
            local thisDistance = tes3.mobilePlayer.position:distance(enemy.position) 
            minDistance = minDistance < thisDistance and minDistance or thisDistance
        end
    end

    if config.enable then 
        for enemy in cell:iterateReferences(tes3.objectType.creature) do
            checkHostileDistance(enemy)
        end
        for enemy in cell:iterateReferences(tes3.objectType.npc) do
            checkHostileDistance(enemy)
        end
    end

    if minDistance >= config.safeDistance then
        inCombat = false
    end

    if inCombat then
        tes3ui.leaveMenuMode(tes3ui.registerID("MenuMulti"))
        if menuInputMap.code ~= substituteKeyCode then
            --save menu key and replace with fake code
            menuKeyCode = menuInputMap.code 
            menuInputMap.code = substituteKeyCode
        end
    else
        --enable menu out of combat
        if menuInputMap.code == substituteKeyCode then
            menuInputMap.code = menuKeyCode
            menuKeyCode = nil
        end
    end       
end

local function onLoad()
    timer.start{
        type = timer.real,
        duration = 0.5,
        iterations = -1, 
        callback = checkInCombat
    }
end
event.register("loaded", onLoad)

local function onActivate(e)
    if config.enable then
        local isContainer = e.target.object.objectType == tes3.objectType.container
        local isDead = ( 
            ( e.target.object.objectType == tes3.objectType.npc or e.target.object.objectType == tes3.objectType.creature ) and 
            e.target.mobile.health.current <= 0
        )
        if inCombat and ( isContainer or isDead ) then
            tes3.messageBox("You are in combat.")
            return false
        end
    end
end

event.register("activate", onActivate)



local function onMenuButton(e)
    if config.enable then
        local showMsg = (
            e.button == menuKeyCode and
            menuInputMap.code == substituteKeyCode and
            not tes3.menuMode()
        )
        if showMsg then
            tes3.messageBox("You are in combat.")
        end
    end
end

event.register("mouseButtonDown", onMenuButton)


------------------------------------------------------
--MCM
------------------------------------------------------
local sidebarDefault = (
    "No Combat Menu prevents you from accessing your inventory menu, " ..
    "as well as preventing looting containers/corpses, while you are in combat. \n" ..
    "Yes, this makes combat significantly more difficult. You will need to plan " ..
    "ahead and make strategic use of your quick keys, as they are your only " ..
    "way into your inventory. And no, you can not change your quick keys while " ..
    "in combat either. "
)

local function addSideBar(component)
    component.sidebar:createInfo{ text = sideBarDefault}
    component.sidebar:createHyperLink{
        text = "Made by Merlord",
        exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
        postCreate = (
            function(self)
                self.elements.outerContainer.borderAllSides = self.indent
                self.elements.outerContainer.alignY = 1.0
                self.elements.outerContainer.layoutHeightFraction = 1.0
                self.elements.info.layoutOriginFractionX = 0.5
            end
        ),
    }
end

local function makeVar(id, numbersOnly)
    return mwse.mcm.createTableVariable{
        id = id, 
        table = config,
        numbersOnly = numbersOnly
    }
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("No Combat Menu")
    template:saveOnClose(configPath, config)
    template:register()

    local page = template:createSideBarPage()
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable No Combat Menu",
        description = "Turn this mod on or off.",
        variable = makeVar("enable")
    }

    page:createSlider{
        label = "Safe Distance",
        description = "The distance from the nearest enemy at which you can access your inventory.",
        variable = makeVar("safeDistance"),
        min = 0, 
        max = 4000,
        jump = 200,
        step = 1
    }


end

event.register("modConfigReady", registerModConfig)