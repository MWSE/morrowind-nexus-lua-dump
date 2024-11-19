-- if true then return end
local cfg = require("BeefStranger.Fist of Azuras Star.config")
local metadata = tes3.getLuaModMetadata("BeefStranger.Fist of Azuras Star")
local bs = require("BeefStranger.Fist of Azuras Star.common")
local ui = require("BeefStranger.Fist of Azuras Star.ui")
local absorb = require("BeefStranger.Fist of Azuras Star.Perks.absorb")
local acrobat = require("BeefStranger.Fist of Azuras Star.Perks.acrobat")
local astral = require("BeefStranger.Fist of Azuras Star.Perks.astralFist")
local deflect = require("BeefStranger.Fist of Azuras Star.Perks.deflect")
local flowing = require("BeefStranger.Fist of Azuras Star.Perks.flowingFist")
local hunker = require("BeefStranger.Fist of Azuras Star.Perks.hunkerDown")
local sanctify = require("BeefStranger.Fist of Azuras Star.Perks.sanctifier")
local stealth = require("BeefStranger.Fist of Azuras Star.Perks.stealth")
local sticky = require("BeefStranger.Fist of Azuras Star.Perks.stickyFingers")
local HUNKER = bs.HUNKER
local Azura
local Perk---@type bsAzuraPerks


---@class bsAzuraMain
local this = {}

event.register("initialized", function()
    local version = ""
    if metadata then version = metadata.package.version end
    print("[MWSE:Fist of Azuras Star] initialized ".. version)
end)

--- @param e loadedEventData
function this.initPlayerData(e)
    tes3.player.data.bsFistOfAzura = tes3.player.data.bsFistOfAzura or {}

    Azura = tes3.player.data.bsFistOfAzura
    Azura.perkPoints = Azura.perkPoints or 0
    Azura.spentPoints = Azura.spentPoints or 0
    Azura.perkPoints = math.min(math.floor(bs.h2h:base() / cfg.perkLevel), cfg.perkMax)
    Azura.perks = Azura.perks or {}

    debug.log(bs.h2h:base())
    debug.log(cfg.perkLevel)
    debug.log(cfg.perkMax)
    debug.log(Azura.perkPoints)
    

    for perkName, _ in pairs(bs.perkList) do
        if Azura.perks[perkName] == nil then
            Azura.perks[perkName] = bs.perkList[perkName]
        end
    end
    ---@type bsAzuraPerks
    Perk = Azura.perks

    bs.inspect(Perk)

end
event.register(tes3.event.loaded, this.initPlayerData)

---==========================================
---=================On Damage================
---==========================================

---@param e damageEventData|damageHandToHandEventData
function this.damageHandler(e)
    if e.source ~= tes3.damageSource.attack then return end
    if not bs.fistsRaised() then return end
    local dmg = e.damage or e.fatigueDamage
    local absorbAmount = e.damage or (e.fatigueDamage / 5)
    local target = e.mobile

    ---If Player Attacking
    if e.attacker == tes3.mobilePlayer then
        if Perk.sticky then dmg = sticky.onDmg(e) end
        if Perk.astral then dmg = astral.onDmg(e) end
        if Perk.sanctifier then dmg, absorbAmount = sanctify.onDmg(e, dmg, absorbAmount) end

        if Perk.hunkerDown then dmg = hunker.onDmg(dmg) end

        if Perk.healthAbsorb then dmg = absorb.stat(absorbAmount, "health", target) end
        if Perk.magickaAbsorb then dmg = absorb.stat(absorbAmount, "magicka", target) end
        if Perk.fatigueAbsorb then dmg = absorb.stat(absorbAmount, "fatigue", target) end
    end

    ---If Player Damaged
    if target == tes3.mobilePlayer then

        if Perk.hunkerDown then dmg = hunker.playerDmg(e, dmg) end

        if Perk.flowingFist then dmg = flowing.playerDmg(dmg) end
        if Perk.deflect then dmg = deflect.playerDmg(e, dmg) end
        if Perk.sanctifier then dmg = sanctify.playerDmg(e, dmg) end
    end

    e.damage = dmg
    e.fatigueDamage = dmg
end
event.register(tes3.event.damage, this.damageHandler)
event.register(tes3.event.damageHandToHand, this.damageHandler)

---==========================================
---========Attack Speed/Fatigue Drain========
---==========================================

---Attack Speed/Extra Stamina Drain
---@param e attackStartEventData
function this.attackStart(e)
    if e.reference == tes3.player then
        if bs.fistsRaised() then
            -- if Perks:flowingFist() then
            if Perk.flowingFist and tes3.mobilePlayer.fatigue.current > 5 then
                flowing.fatigueDrain()
            end
            -- debug.log(e.attackSpeed)
            e.attackSpeed = this.attackSpeedMod()
        end
    end
end
event.register(tes3.event.attackStart, this.attackStart)

---Modify attackSpeed
---@return number attackSpeed
function this.attackSpeedMod()
    ---Considering forcing speed to be base. Lot easier to balance if it is
    local speed = (cfg.base and tes3.mobilePlayer.speed.base) or tes3.mobilePlayer.speed.current

    local h2hMod = bs.lerp(cfg.h2hMin, cfg.h2hMax, cfg.h2hCap, bs.h2h:current())
    local speedMod = (cfg.useSpeed and bs.lerp(.01, cfg.speedMax, cfg.speedCap, speed)) or 0

    if Perk.hunkerDown then h2hMod = h2hMod * HUNKER.ATTACK_SPEED_MULT end
    if Perk.flowingFist then h2hMod = flowing.attackSpeed(h2hMod) end
    if Perk.astral then h2hMod = astral.attackSpeed(h2hMod) end

    local attackSpeed = math.round(h2hMod + speedMod, 2)
    Azura.attackSpeed = attackSpeed ---Log attackSpeed to show it in menu later

    return attackSpeed
end

---==========================================
---==================Movement================
---==========================================

--- @param e calcMoveSpeedEventData
function this.moveSpeed(e)
    local speed = e.speed
    if e.mobile == tes3.mobilePlayer then
        if bs.fistsRaised() then
            if Perk.flowingFist then speed = flowing.moveSpeed(speed) end
            if Perk.deflect then speed = deflect.moveSpeed(speed) end

            if Perk.stealth then
                stealth.chameleon()
                speed = stealth.moveSpeed(speed)
            end
    
            if Perk.hunkerDown then
                speed = hunker.moveSpeed(speed)
            end
        end

        e.speed = speed
    end
end
event.register(tes3.event.calcMoveSpeed, this.moveSpeed)

--- @param e keyDownEventData
local function onSpace(e)
    if not tes3ui.menuMode() and not tes3.onMainMenu() then
        if Perk.acrobat then
            acrobat.doubleJump()
        end
    end
end
event.register(tes3.event.keyDown, onSpace, { filter = tes3.scanCode.space })


--- @param e jumpEventData
local function jumpCallback(e)
    if Perk.acrobat then
        acrobat.onJump(e)
    end
end
event.register(tes3.event.jump, jumpCallback)

---==========================================
---===============HitCone/Reach==============
---==========================================

--- @param e calcHitDetectionConeEventData
function this.hitCone(e)
    if e.attackerMobile == tes3.mobilePlayer and bs.fistsRaised() then
        -- if Perk.flowingFist then e.reach = flowing.reach(e) end ---Probably Removing
        if Perk.astral then
            e.angleXY, e.angleZ = astral.hitConeAngle(e)
            e.reach = astral.reach(e)
        end
    end
end
event.register(tes3.event.calcHitDetectionCone, this.hitCone)

---==========================================
---===========HitChance/AttackSwing==========
---==========================================

--- @param e calcHitChanceEventData
function this.hitChance(e)
    ---Player Attacking
    if e.attackerMobile == tes3.mobilePlayer then
        local attackSwing = e.attackerMobile.actionData.attackSwing
        e.attackerMobile.actionData.attackSwing = math.max(attackSwing, this.attackSwingMod())
    end

    ---Player Damaged
    if e.targetMobile == tes3.mobilePlayer then
        if Perk.hunkerDown then e.hitChance = hunker.hitChance(e) end
    end
end
event.register(tes3.event.calcHitChance, this.hitChance)

---Leaving here incase I add new perks that also effect attackSwing
function this.attackSwingMod()
    local h2hBoost = bs.lerp(0, 0.85, 100, bs.h2h:current())
    if Perk.flowingFist then h2hBoost = flowing.attackSwing(h2hBoost) end
    return h2hBoost
end

---==========================================
---================On Level Up===============
---==========================================
-- tes3.mobilePlayer:exerciseSkill(tes3.skill.handToHand, 1)
--- @param e skillRaisedEventData
function this.h2hLevel(e)
    Azura.perkPoints = math.min(math.floor(bs.h2h:base() / cfg.perkLevel), cfg.perkMax)
end
event.register(tes3.event.skillRaised, this.h2hLevel, { skill = tes3.skill.handToHand })

---==========================================
---================Post Damage===============
---==========================================

--- @param e damagedEventData
local function postDamage(e)
    ---Player Attacked
    if e.attacker == tes3.mobilePlayer then
        if Perk.astral then
            if bs.roll() < 25 then bs.blockStun(e) end
        end
        if e.killingBlow then
            if Perk.sanctifier then sanctify.onKill(e) end
        end

        if e.killingBlow then
            e.reference.tempData.bsStickyCount = 0
            -- bs.inspect(e.reference.tempData)
        end
    end

    ---Player Damaged
    if e.mobile == tes3.mobilePlayer then
        if Perk.hunkerDown then
            hunker.postPlayerDamage(e)
        end
    end
end
event.register(tes3.event.damaged, postDamage)


--- @param e damagedHandToHandEventData
local function h2hDamageDone(e)
    ---Player Attack
    if e.attacker == tes3.mobilePlayer then
        if Perk.hunkerDown then
            hunker.postPlayerAttack(e)
        end

        if Perk.flowingFist then
            flowing.postPlayerAttack(e)
        end
    end

    ---Player Damaged
    if e.mobile == tes3.mobilePlayer then
        if Perk.hunkerDown then
           hunker.postPlayerDamage(e)
        end
    end

end
event.register(tes3.event.damagedHandToHand, h2hDamageDone)