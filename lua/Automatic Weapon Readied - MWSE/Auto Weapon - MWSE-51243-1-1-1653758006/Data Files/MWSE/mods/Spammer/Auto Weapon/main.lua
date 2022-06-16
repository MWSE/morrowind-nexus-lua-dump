local mod = {
    name = "Auto Weapon/Magic",
    ver = "1.1",
    cf = {onOff = true, key = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}, dropDown = 1, dropDown2 = 0, slider = 5, sliderpercent = 50, blocked = {}, npcs = {},}
            }
local cf = mwse.loadConfig("auto_weapon", mod.cf)

----------------------------------------------------------------------------------------------------------
local state = nil
local function rayCast()
    if cf.dropDown2 == 1 then return end
        local hitResult = tes3.rayTest({position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}, maxDistance = cf.sliderpercent})
        local hitReference = hitResult and hitResult.reference
        local type = hitReference and hitReference.object and hitReference.object.objectType
        local mobile = hitReference and hitReference.mobile
    if cf.dropDown == 0 then
        return
    elseif cf.dropDown == 1 then
        if ((type == tes3.objectType.creature) or (type == tes3.objectType.npc)) then
            if ((not mobile.isDead) and ((mobile.fight > 70) or mobile.inCombat)) then
                tes3.mobilePlayer.weaponReady = true
                state = true
            else
                if state then
                    tes3.mobilePlayer.weaponReady = false
                    state = nil
                end
            end
        end
    else
        if ((type == tes3.objectType.creature) or (type == tes3.objectType.npc)) then
            if ((not mobile.isDead) and ((mobile.fight > 70) or mobile.inCombat)) then
                tes3.mobilePlayer.castReady = true
                state = true
            else
                if state then
                    tes3.mobilePlayer.castReady = false
                    state = nil
                end
            end
        end
    end
end event.register("simulate", rayCast)


local function rayCast2()
    if cf.dropDown2 == 0 then return end
        local hitResult = tes3.rayTest({position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}, maxDistance = cf.sliderpercent})
        local hitReference = hitResult and hitResult.reference
        local type = hitReference and hitReference.object and hitReference.object.objectType
        local mobile = hitReference and hitReference.mobile
    if cf.dropDown == 0 then
        return
    elseif cf.dropDown == 1 then
        if ((type == tes3.objectType.creature) or (type == tes3.objectType.npc)) then
            if ((not mobile.isDead) and ((mobile.fight > 70) or mobile.inCombat)) then
                tes3.mobilePlayer.weaponReady = true
                state = true
            else
                if state then
                    tes3.mobilePlayer.weaponReady = false
                    state = nil
                end
            end
        end
    else
        if ((type == tes3.objectType.creature) or (type == tes3.objectType.npc)) then
            if ((not mobile.isDead) and ((mobile.fight > 70) or mobile.inCombat)) then
                tes3.mobilePlayer.castReady = true
                state = true
            else
                if state then
                    tes3.mobilePlayer.castReady = false
                    state = nil
                end
            end
        end
    end
end event.register(tes3.event.mouseButtonDown, rayCast2)


local function registerModConfig()
    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose("auto_weapon", cf)
    template:register()

    local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
    page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Spammer."}
    page.sidebar:createHyperLink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

    local category1 = page:createCategory("Mod Config")
    local elementGroup = category1:createCategory("")
    elementGroup:createDropdown { description = "Choose whether your weapon or your magic will be automatically readied when facing an ennemy.",
        options  = {
            { label = "Mod Off", value = 0 },
            { label = "Auto Combat Mode", value = 1 },
            { label = "Auto Magic Mode", value = 2 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown",
            table = cf
        }
    }
    elementGroup:createDropdown { description = "Choose whether it will be automatically readied when facing the ennemy or if you'll need a mouse click for it.",
        options  = {
            { label = "View", value = 0 },
            { label = "MouseClick", value = 1 },
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown2",
            table = cf
        }
    }

    elementGroup:createSlider{label = "Activation Distance", description = "Sets the minimum distance to the target to ready your weapon.", min = 0, max = 10000, step = 10, jump = 1000, variable = mwse.mcm.createTableVariable{id = "sliderpercent", table = cf}}
end event.register("modConfigReady", registerModConfig)

local function initialized()
    print("["..mod.name..", by Spammer] "..mod.ver.." Initialized!")
end event.register("initialized", initialized, {priority = -1000})




