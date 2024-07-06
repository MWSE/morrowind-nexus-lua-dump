local config = require("BeefStranger.CombatLog.config")
local bs = require("BeefStranger.CombatLog.common")
-- local rgb, log = bs.rgb, bs.log
local log = bs.log
local color = config.color
local cl = {}
local sf = string.format


local combatLog = tes3ui.registerID("bsCombatLog")
local scroll         ---@type tes3uiElement The ScrollPane
local clog           ---@type tes3uiElement The Block inside of scroll
local manual = false ---@type boolean ManualOverride

local damageTimer  ---@type mwseTimer|nil  Timer to delay display of magic dmg until effect finishes
local reflectTimer ---@type mwseTimer|nil Timer to delay display of reflect until effect finishes
local autoTimer    ---@type mwseTimer The Timer for autoShow

local hitChance = 0     --Hit chance variable
local magicDamage = 0   --Counter for magic damage done
local reflectDamage = 0 --Counter for magic reflected
------------------------------------------------------
local block = "block"
local miss = "miss"
local hit = "hit"
local reflect = "reflect"
local magic = "magic"
------------------------------------------------------

---Returns combatLog top level menu
local function getMenu()
    return tes3ui.findMenu(combatLog)
end

---Updates menu and ScrollBar
local function updateList()
    local menu = getMenu()
    menu:updateLayout()                                    ---Update Layout
    scroll.widget.positionY = scroll.widget.positionY + 25 ---Scroll down 25
    scroll.widget:contentsChanged()                        ---Update actual scrollPane
end

---Creation of the log
local function combatlog(visible)
    -- log("combatLog started")
    local cMenu = tes3ui.createMenu{id = combatLog, dragFrame = true, fixedFrame = false}
        cMenu.text = "Combat log"
        cMenu.width = 300
        cMenu.height = 200
        cMenu.positionX = -845
        cMenu.positionY = -135
        cMenu.alpha = config.alpha
        cMenu:loadMenuPosition()

    ---Have to do this or menu will not load visibly the first time
    if not cMenu.visible  then
        cMenu.width = 300
        cMenu.height = 200
        cMenu:loadMenuPosition()
        -- cMenu.positionX = -845
        -- cMenu.positionY = -135
        cMenu.visible = true --Menu wont show without manually making it
    end

    scroll = cMenu:createVerticalScrollPane { id = "scroll" }
    clog = scroll:createBlock { id = "clog" }
    bs.autoSize(clog)
    clog.flowDirection = tes3.flowDirection.topToBottom

    if not visible then
        cMenu.visible = false
    end

    cMenu:updateLayout()
end


-------------Get hitChance to add to log--------------
--- @param e calcHitChanceEventData
local function hitChanceCalc(e)
    hitChance = e.hitChance
end event.register(tes3.event.calcHitChance, hitChanceCalc)

--------------AutoTimer--------------
---Auto Show timer
function cl.autoShow()
    local menu = getMenu() or (combatlog() and getMenu()) ---Shouldnt be necessary anymore but leaving just in case
    if menu then
        menu.visible = true
        if autoTimer and autoTimer.state ~= 2 then
            autoTimer:reset()
        else
            autoTimer = timer.start {
                duration = config.autoDuration,
                callback = function(e)
                    if menu.visible then
                        menu.visible = false
                    end
                end
            }
        end
    else
        log("Combat Log not Found")
    end
end

---@param parent tes3uiElement
---@param id string
---@param text string
---@param colors string|table
local function createLabel(parent, id, text, colors)
    local label = parent:createLabel{id = id, text = text}
    label.color = colors
    updateList()
end


--- @param e damagedEventData
local function damagedCallback(e)
    if not config.enableMagic then
        log("Magic Logging Disabled")
        return
    end
    if e.source ~= tes3.damageSource.magic or not e.attacker then
        return
    end

    local menu = getMenu() or (combatlog() and getMenu())
    local attacker = e.attacker.object.name or "Unknown"            --Name of Attacker
    local playerIsAttacker = e.attacker == tes3.mobilePlayer        --If player is Attacking
    local playerIsTarget = e.mobile == tes3.mobilePlayer            --If player is the Target
    local wasReflected = e.attacker == e.mobile
    local eName = e.magicEffect.object.name                         --Name of effect
    local eText = string.find(eName:lower(), "damage") and eName or
        "(" .. eName .. " Damage)"                                  --Corrected Name of Effect
    local you = not config.showPlayerName and "You" or attacker     --Set you to various options


    if not wasReflected then
        magicDamage = magicDamage + math.abs(e.damage)

        if damageTimer and damageTimer.state ~= 2 then     --Reset timer if effect is still active
            damageTimer:reset()
        else                                               --Normal damage timer
            damageTimer = timer.start({
                duration = 0.10,
                callback = function()
                    if menu and magicDamage > 0 and (playerIsAttacker or playerIsTarget) then
                        if config.autoShow and not manual then
                            cl.autoShow()
                        end
                        local hitText = sf(
                            "%s Dealt %.2f %s",
                            (playerIsAttacker and you or attacker),
                            math.ceil(magicDamage),
                            (config.showEffectName and eText) or "Damage"
                        )

                        createLabel(clog, magic, hitText, (playerIsAttacker and color.playerMagic) or color.enemyMagic)
                    end
                    magicDamage = 0
                    damageTimer = nil
                end
            })
        end
    end

    if wasReflected then
        reflectDamage = reflectDamage + math.abs(e.damage)

        if reflectTimer and reflectTimer.state ~= 2 then
            -- log("wasReflected, timer running resetting")
            reflectTimer:reset()
        else     --Reflected Timer
            reflectTimer = timer.start({
                duration = 0.10,
                callback = function()
                    log("wasReflected, starting timer")
                    if menu and reflectDamage > 0 then
                        if config.autoShow and not manual then
                            cl.autoShow()
                        end
                        ---On Damage Reflected

                        local reflectText = sf(
                            "%s took %.2f Reflected %s",
                            (playerIsAttacker and you or attacker),
                            math.ceil(reflectDamage),
                            (config.showEffectName and eText) or "Damage"
                        )

                        createLabel(clog, reflect, reflectText, color.reflect)

                        if config.autoShow then
                            menu.visible = true
                        end
                    end
                    reflectDamage = 0
                    reflectTimer = nil
                    log("reflectDamage set to 0, timer set to nil")
                end
            })
        end
    end
end
event.register(tes3.event.damaged, damagedCallback)

--- @param e attackHitEventData
local function onAttackHitCallback(e)
    if not config.enableCombat then
        log("Combat Logging Disabled")
        debug.log(config.enableCombat)
        return
    end

    ---Could be using cMenu instead of finding menu but dont feel like updating it all
    ---WRONG ^^^ cMenu gets replaced with MenuMulti_bottom_row_right on reload, and breaks the mod/crashes

    local menu = getMenu() or (config.autoShow and combatlog() and getMenu())                    --The CombatLog Menu or create and then get it
    local attacker = e.reference and e.reference.object and e.reference.object.name or "Unknown" --Name of attacker
    local damage = e.mobile and e.mobile.actionData and e.mobile.actionData.physicalDamage or 0  --Damage dealt to target
    local playerAttack = e.reference == tes3.player                                              --Checks if attack was from the player
    local playerIsTarget = e.targetReference == tes3.player                                      --Checks if player is the target
    local validTarget = e.targetReference ~= nil                                                 --Checks for Valid Target
    local target = e.targetReference and e.targetReference.object.name or "Unknown"              --Who got attacked when blocking
    local blocked = e.targetMobile and e.targetMobile.actionData.blockingState ~= 0              --Checks if attack was blocked
    local you = (not config.showPlayerName and "You") or attacker                                --"You" or attacker name toggle

    local hitChanceText = (config.showChance and sf(" (%d%%)", hitChance)) or ""                                 --Hit chance text toggle
    local missedText = sf("%s Missed%s", (playerAttack and you) or attacker, hitChanceText)                      --"You" or attacker name
    local hitText = sf("%s Hit for %d%s", (playerAttack and you) or attacker, math.ceil(damage), hitChanceText)  --Hit Text
    local blockText = sf("%s Blocked!", (playerIsTarget and you) or target)                                      --Block Text

    ---Checks | Abort
    if not menu then log("%s not found", combatLog) return end
    -- if not validTarget then --[[ log("No Target") ]] return end
    if not validTarget or (not playerAttack and not playerIsTarget) then return end

    if config.autoShow and not manual then cl.autoShow() end --autoShow override check

    
    if damage <= 0 then      --If Attacker Missed
        createLabel(clog, miss, missedText, (playerAttack and color.playerMiss) or color.enemyMiss)
    elseif not blocked then  --If Attacker Hit
        createLabel(clog, hit, hitText, (playerAttack and color.playerHit) or color.enemyHit)
    elseif blocked then      --If Target Blocked
        createLabel(clog, block, blockText, color.blocked)
    end

    ---Only save 100 messages
    if #clog.children > config.maxSaved then
        for i = 1, #clog.children - config.maxSaved do
            clog.children[i]:destroy() ---Destroy First message under max
        end
        updateList()
    end

    menu:saveMenuPosition()
end

event.register(tes3.event.attackHit, onAttackHitCallback)

---@param e keyUpEventData
local function onKeyUp(e)
    if not tes3.onMainMenu() and e.keyCode == config.keycode.keyCode and tes3.isCharGenFinished() then
        -- if tes3ui.menuMode() then return end
        -- log("getMenu %s | cMenu %s", getMenu(), cMenu)
        local menu = getMenu()

        if config.autoShow and menu then
            manual = not manual
            tes3.messageBox("CombatLog Manual Override %s", manual and "Enabled" or "Disabled")
            menu.visible = manual
            
            ---If manual mode is true disable it and hide menu on KeyPress
            -- if manual then
            --     -- log("manual true | vis %s", menu.visible)
            --     manual = false
            --     tes3.messageBox("CombatLog Manual Override %s", manual or "Disabled")
            --     menu.visible = false
            -- else
            --     -- log("manual nil or false | vis %s", menu.visible)
            --     manual = true
            --     tes3.messageBox("CombatLog Manual Override %s", manual and "Enabled")
            --     menu.visible = true
            -- end
        else
            if menu then
                menu.visible = not menu.visible
                menu:updateLayout()
            else
                combatlog()
            end

            -- if menu then
            --     ---Toggle visible
            --     -- log("menu found toggle visiblity|current %s", menu.visible)
            --     menu.visible = not menu.visible
            --     ---Update just incase, probably not needed
            --     menu:updateLayout()
            -- else
            --     combatlog() --Create the log if its not done
            -- end
        end
    end
end     event.register(tes3.event.keyUp, onKeyUp)

---Create the log on load so first attacks properly show
event.register("loaded", function (e)
    local menu = getMenu()
    if menu then
        menu.visible = false
    else
        combatlog()
    end
    -- debug.log(menu)
end)

---To update and show the log in the MCM with examples
local showMenu = "combatLog:showMenu"
event.register(showMenu, function (e)
    local menu = tes3ui.findMenu("bsCombatLog")

    --All the options for the example labels
    local labels = {
        blocked = {id = "blocked", text = "Fargoth Blocked", color = color.blocked},
        playerHit = {id = "playerHit", text = "You hit for 12 Damage", color = color.playerHit},
        enemyHit = {id = "enemyHit", text = "Fargoth hit for 12 Damage", color = color.enemyHit},
        reflect = {id = "reflect", text = "You took 69 Reflected Damage", color = color.reflect},
        playerMiss = {id = "playerMiss", text = "You Missed", color = color.playerMiss},
        enemyMiss = {id = "enemyMiss", text = "Fargoth Missed", color = color.enemyMiss},
        playerMagic = {id = "playerMagic", text = "You Dealt 21 Damage", color = color.playerMagic},
        enemyMagic = {id = "enemyMagic", text = "Fargoth Dealt 21 Damage", color = color.enemyMagic}
    }

    --Where the example elements are made
    local function makeExample()
        for id, text in pairs(labels) do
            local label = clog:createLabel(text)
            label.color = color[id]
        end
    end

    if menu then
        -- log("menu %s", menu)
        clog:destroyChildren()
        if e.visible == true then
            makeExample()
        end

        menu.alpha = config.alpha
        menu.visible = e.visible
        debug.log(e.resetPos)
        if e.resetPos then
            menu.width = 300
            menu.height = 200
            menu.positionX = -845
            menu.positionY = -135
        end
        updateList()
    else
        log("Creating log")
        combatlog()
        if e.visible == true then
            event.trigger("combatLog:showMenu", {visible = true, resetPos = e.resetPos})
        elseif e.visible == false then
            event.trigger("combatLog:showMenu", {visible = false, resetPos = e.resetPos})
        end
    end
end)

event.register("initialized", function()
    print("[MWSE:Combat log] initialized")
end)