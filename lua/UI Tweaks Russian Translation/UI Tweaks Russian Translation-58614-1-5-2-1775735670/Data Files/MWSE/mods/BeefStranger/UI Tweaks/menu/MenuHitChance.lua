local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local startTime = os.clock()
local HIT_CHANCE_ID = tes3ui.registerID("BS_MenuHitChance")

---@class BS_MenuHitChance
local Menu = {}
function Menu:get() return tes3ui.findHelpLayerMenu(HIT_CHANCE_ID) end
function Menu:child(child) return self:get() and self:get():findChild(child) end
function Menu:Chance() return self:child("Chance") end

function Menu:hide()
    if self:get() then
        self:get().visible = false
        self:get().disabled = true
    end
end
function Menu:show()
    if self:get() then

        self:get().visible = true
        self:get().disabled = false
    end
end
function Menu:toggle()
    self:get().visible = not (self:get().visible)
    self:get().disabled = not (self:get().disabled)
end


---@return number|boolean hitChance
local function getHitChance()
    local rayTarget = tes3.rayTest({
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = {tes3.player},
        maxDistance = bs.GMST(tes3.gmst.iMaxActivateDist)
    })
    local defender = rayTarget and rayTarget.reference and rayTarget.reference.mobile
    if defender and not defender.isDead then
        local fCombatInvisoMult = bs.GMST(tes3.gmst.fCombatInvisoMult)
        local attacker = tes3.mobilePlayer
        local weapon = attacker.readiedWeapon
        local skill = weapon and attacker:getSkillValue(weapon.object.skillId) or attacker.handToHand.current --- Default to Hand-to-Hand

        -- if weapon then
        --     skill = attacker:getSkillValue(weapon.object.skillId)
        -- end

        local attackTerm = ((skill + 0.2 * attacker.agility.current + 0.1 * attacker.luck.current) * attacker:getFatigueTerm())
        attackTerm = attackTerm + attacker.attackBonus - attacker.blind

        local defenseTerm = 0

        if defender and defender.fatigue.current >= 0 then
            local unaware = (not defender.inCombat) and (not defender.isPlayerDetected)

            if not (defender.isKnockedDown or defender.isParalyzed or unaware) then
                defenseTerm = ((0.2 * defender.agility.current + 0.1 * defender.luck.current) * defender:getFatigueTerm())
                defenseTerm = defenseTerm + math.min(100, defender.sanctuary)
            end

            defenseTerm = defenseTerm + math.min(100, fCombatInvisoMult * defender.chameleon)
            defenseTerm = defenseTerm + math.min(100, fCombatInvisoMult * defender.invisibility)
        end
        local x = math.round(attackTerm - defenseTerm)

        return x
    else
        Menu:hide() ---Hide if theres no target
        return false
    end
end

---@param e tes3uiEventData
function Menu:onUpdate(e)
    if getHitChance() then
        local main = e.source:getTopLevelMenu()
        Menu:show()
        e.source.text = "Шанс попадания: ".. tostring(getHitChance()) .. "%"
        ---Update Pos/RGBA
        local color, alpha = bs.color(cfg.hitChance.color)
        main.color = color
        main.alpha = alpha
        main.absolutePosAlignX = cfg.hitChance.posX
        main.absolutePosAlignY = cfg.hitChance.posY

        main:updateLayout()
    else
        Menu:hide()
    end
end

local function createHitChance() --- onLoadEvent
    local help = tes3ui.createHelpLayerMenu({id = HIT_CHANCE_ID})
    help.width = 50
    help.height = 50
    help.visible = false
    help.absolutePosAlignX = cfg.hitChance.posX
    help.absolutePosAlignY = cfg.hitChance.posY
    local chance = help:createLabel({ id = "Chance", text = "Шанс попадания: " .. tostring(getHitChance()) .. "%" })
    chance:register(tes3.uiEvent.update, function (e) Menu:onUpdate(e) end)
    help:updateLayout()
end

--- @param e activationTargetChangedEventData
local function activationTargetChangedCallback(e)
    if not cfg.hitChance.enable then return end
    if e.current and e.current.mobile and not e.current.isDead and tes3.mobilePlayer.weaponReady then
        if not Menu:get() then
            createHitChance()
        else
            Menu:Chance():triggerEvent(tes3.uiEvent.update)
        end
    else
        if Menu:get() then
            Menu:hide()
        end
    end
end
event.register(tes3.event.activationTargetChanged, activationTargetChangedCallback)

---@param e simulatedEventData
local function simulated(e)
    if not cfg.hitChance.enable then return end
    if os.clock() - startTime >= cfg.hitChance.updateRate then
        startTime = os.clock()
        if tes3.mobilePlayer and tes3.mobilePlayer.weaponReady then
            if Menu:get() and getHitChance() then
                Menu:Chance():triggerEvent(tes3.uiEvent.update)
            end
        else
            Menu:hide()
        end
    end
end
event.register(tes3.event.simulated, simulated)

---@param e menuEnterEventData
local function menuEnter(e)
    if e.menuMode then
        if not Menu:get() then
            createHitChance()
        end
        Menu:hide()
    end
end
event.register(tes3.event.menuEnter, menuEnter)

return Menu
