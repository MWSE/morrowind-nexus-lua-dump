local mod = {
    name = "Walking Experience",
    ver = "1.0",
    cf = {onOff = false, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {}, textfield = "hello", switch = false}
            }
local cf = mwse.loadConfig(mod.name, mod.cf)


---comment
---@param e table|calcWalkSpeedEventData
event.register("calcWalkSpeed", function(e)
    if not e.mobile then return end
    if e.mobile ~= tes3.mobilePlayer then return end
    if not e.mobile.isWalking then return end
    if e.mobile.isSwimming then return end
    tes3.mobilePlayer:exerciseSkill(tes3.skill.athletics, 0.00001*cf.sliderpercent*(tes3.mobilePlayer.encumbrance.normalized))
    if cf.onOff then
        tes3.messageBox{message = string.format("Skill Progress : %s", tes3.mobilePlayer.skillProgress[9])}
    end
end)

local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category0 = page:createCategory(" ")
    category0:createOnOffButton{label = "Debugging", description = "Use for debugging purpose", variable = mwse.mcm.createTableVariable{id = "onOff", table = cf}}

    local category2 = page:createCategory(" ")
    local subcat = category2:createCategory(" ")

    subcat:createSlider{label = "Experience Gained".."%s%%", description = "Percent of percent", min = 0, max = 10000, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}
end event.register("modConfigReady", registerModConfig)

local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})

