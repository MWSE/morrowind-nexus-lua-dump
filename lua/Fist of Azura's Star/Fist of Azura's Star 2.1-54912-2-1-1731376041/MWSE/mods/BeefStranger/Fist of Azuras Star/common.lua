local cfg = require("BeefStranger.Fist of Azuras Star.config")
---@class bsFistOfAzuraCommon
local bs = {}
local Azura

--- @param e loadedEventData
local function initData(e)
    tes3.player.data.bsFistOfAzura = tes3.player.data.bsFistOfAzura or {}

    Azura = tes3.player.data.bsFistOfAzura
end
event.register(tes3.event.loaded, initData)

---@param scanCode tes3.scanCode
function bs.isKeyDown(scanCode)
    return tes3.worldController.inputController:isKeyDown(scanCode)
end


---Enables Perk and Marks point as spent
---@param perk string The Perk key
function bs.enablePerk(perk)
    Azura.perks[perk] = true
    Azura.spentPoints = Azura.spentPoints + 1
end

---Returns the Value of GMST provided
---@param id tes3.gmst
---@return string|number tes3gamesetting.value
function bs.GMST(id)
    return tes3.findGMST(id).value
end

function bs.inspect(table)
    local inspect = require("inspect").inspect
    mwse.log("%s", inspect(table))
end

---bs.functions
---@param base any The starting value
---@param max any The value it ends at
---@param progressCap any When the value of data hits this max will be the value
---@param data any Where progressCap gets its data
---@return number
function bs.lerp(base, max, progressCap, data)
    local slope = (max - base) / progressCap
    local result = (slope * data + base)
    return math.min(result, max)
end

bs.h2h = {}
function bs.h2h:get() return tes3.mobilePlayer.handToHand end
function bs.h2h:current() return self:get().current end
function bs.h2h:base() return self:get().base end

bs.will = {}
function bs.will:get() return tes3.mobilePlayer.willpower end
function bs.will:current() return self:get().current end
function bs.will:base() return self:get().base end

---Returns Available Perk Points to Spend
---@return integer availablePerks
function bs.perkPoints() return tes3.player.data.bsFistOfAzura.perkPoints - tes3.player.data.bsFistOfAzura.spentPoints end
function bs.hasPerk(perk) return tes3.player.data.bsFistOfAzura.perks[perk] end


---Target Checks
---@param target tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function bs.isCorprus(target) return target.object.name:lower():find("corprus") end
---@param target tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function bs.isUndead(target) return target.object.type and target.object.type == tes3.creatureType.undead or bs.isCorprus(target) end
---@param reference tes3reference
function bs.isTribunal(reference) return bs.SANCTIFY.TRIBUNAL[reference.baseObject.id] end
---@param target tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function bs.isDaedra(target) return target.object.type and target.object.type == tes3.creatureType.daedra end
---@param target tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function bs.isDunmer(target) return target.object.race and target.object.race.name == bs.race.darkElf end
---@param target tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function bs.isTemple(target) return target.object.faction and target.object.faction.id == "Temple" end
---@param target tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function bs.isSixthHouse(target) return target.object.faction and target.object.faction.id == "Sixth House" end
---@param target tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function bs.isAshlander(target) return target.object.faction and target.object.faction.id == "Ashlanders" end
---@return number RNG
function bs.roll() return math.random(100) end
---Quick check if player has their fists raised
---@return boolean fistsRaised
function bs.fistsRaised() return tes3.mobilePlayer.weaponDrawn and not tes3.mobilePlayer.readiedWeapon end
---@param e damagedEventData|damagedHandToHandEventData
function bs.blockStun(e) e.mobile:hitStun { cancel = true } end
---@return boolean isHunkered
function bs.combatSneak() return tes3.mobilePlayer.isSneaking and tes3.mobilePlayer.inCombat end


---@class bsAzuraPerks
bs.perkList = {
    acrobat = false,
    astral = false,        ---Ranged Punch
    crushing = false,      ---Might not work well
    deflect = false,       ---Defensive Stance, can block
    fatigueAbsorb = false, ---Absorb small amounts of fatigue on hit
    flowingFist = false,   ---Faster Attacks, less dmg done/dealt, faster move, higher swing%
    healthAbsorb = false,  ---Absorb small amounts of health on hit
    hunkerDown = false,    ---Hunker Down and increase defense/stability
    magickaAbsorb = false, ---Absorb small amounts of fatigue on hit
    sanctifier = false,    ---Sanctify undead
    stealth = false,
    sticky = false,        ---Steal
}

---Perk Constants
---@class bsAzuraHunker
bs.HUNKER = {
    ATTACK_SPEED_MULT = 0.90,
    BLOCK_STUN_CHANCE = 85,
    BLOCK_STUN_ENEMY_CHANCE = 35,
    DMG_DEAL_MULT = 0.85,
    DMG_TAKE_FATIGUE_MULT = 0.65,
    DMG_TAKE_MULT = 0.75,
    ENEMY_HITCHANCE_MULT = 1.15,
}
---@class bsAzuraAbsorb
bs.ABSORB = {
    FATIGUE_DIV = 5,
    FATIGUE_MULT = 0.80,
    HEALTH_MULT = 0.10,
    MAGICKA_MULT = 0.20,
    DMG_DEAL_MULT = 0.85
}
---@class bsAzuraFlowing
bs.FLOWING = {
    ATTACK_SPEED_MULT = 1.25,
    DMG_DEAL_MULT = 0.90,
    DMG_DEAL_FATIGUE_MULT = 0.80,
    DMG_TAKE_MULT = 1.10,
    MOVE_MULT = 1.20,
    SWING_BONUS = 0.20,
    REACH_MULT = 2,
    BLOCK_STUN_ENEMY_CHANCE = 50,
}

---@class bsAzuraSanctify
bs.SANCTIFY = {
    DMG_DUNMER = 0.85,
    DMG_ASHLANDER = 0.75,
    DMG_TEMPLE = 1.15,
    DMG_SIXTH = 1.25,
    FLAME_UNDEAD_MAG = 0.5,
    FLAME_UNDEAD_DUR = 1.5,
    FLAME_CORPRUS = 1.25,
    FLAME_CORPRUS_DUR = 3,
    FLAME_TRIBUNAL = 2,
    FLAME_TRIBUNAL_DUR = 3.75,
    DMG_TAKE_TRIBUNAL = 0.85,
    KNOCKDOWN_CHANCE = 5,
    SOUL_ABSORB_MOD = 4,
    TRIBUNAL = { ["vivec_god"] = true, ["Almalexia_warrior"] = true, ["almalexia"] = true }
}

---@class bsAzuraTurtle
bs.DEFLECT = {
    BLOCK_MULT = 1.25,
    DMG_REFLECT_MULT = 0.50,
    DMG_REFLECT_FATIGUE_MULT = 5,
    BLOCK_XP_MULT = 0.75,
    BLOCK_FAIL_XP_MULT = 0.10,
    MOVE_MULT = 0.95,
}

---@class bsAzuraCrushing
bs.CRUSH = {
    DMG_NO_ARMOR_MULT = 1.15,
    DMG_ARMOR_MULT = 2
}

---@class bsAzuraAstral
bs.ASTRAL = {
    REACH_MULT = 1.2,
    ANGLE_DIST_MAX = 1000,
    ANGLE_MAX = 45,
    ANGLE_MIN = 5,
    ANGLE_XY_MULT = 0.90,
    ANGLE_Z_MULT = 0.80,
    ATTACKSPEED_MULT = 0.95,
    REACH_CAP = 14,
    DMG_DIST_FULL = 15,            ---Range Where Max Damage is Dealt
    DMG_DEAL_MIN_MULT = 0.25,      ---Min dmg = dmg * MIN_MULT
    DMG_REDUCTION_RATE = 0.01,     ---How much dmg modifier goes down by
    DMG_DEAL_FATIGUE_MULT = 0.5,
}

---@class bsAzuraSticky
bs.STICKY = {
    STEAL_CHANCE_MULTI = 0.40,
    DMG_DEAL_MULT = 0.85,
    DMG_DEAL_FATIGUE_MULT = 0.65,
    MAX_ATTEMPTS = 3,
}

---@class bsAzuraStealth
bs.STEALTH = {
    MOVE_MULT = 2,
    HIDE_H2H_MULT = 0.25,
    HIDE_SNEAK_MULT = 0.50,
    DMG_HEALTH_MULT = 0.50,
    DMG_DETECTED_MULT = 0.70
}

---@class bsAzuraAcrobat
bs.ACROBAT = {
    MAX_JUMPS = 2,
    XY_MULT = 3,
    Z_MULT = 1.2
}

bs.perkDesc = {
    -- sanctifier    = [[Sanctifier:
    -- +5% Chance to Knockdown Undead/Corprus
    -- +Stacking Sanctified Flame effect on Undead[0.5]/Corprus[1.25]
    -- +Absorb Undead/Corprus Soul / 4 as Magicka on Kill
    -- +Deal 15% More Damage to Members of the Temple
    -- +Deal 25% More Damage to Members of the Sixth House
    -- -Deal 15% Less Damage to the Dunmeri
    -- -Deal 25% Less Damage to Ashlanders]],
    -- healthAbsorb  = [[Siphon Health:
    -- +Absorb 10% of Damage Dealt as Magicka on Strike (Before Damage Reduction)
    -- +Absorb 10% of (Fatigue Damage / 5) as Magicka on Strike (Before Damage Reduction)
    -- -Deal 15% Less Damage

-- [Note: Damage Modifiers Stack with other Siphon Perks] ]],

    -- fatigueAbsorb = [[Siphon Fatigue:
    -- +Absorb 20% of Damage Dealt as Fatigue on Strike (Before Damage Reduction)
    -- +Absorb 20% of (Fatigue Damage / 5) as Fatigue on Strike (Before Damage Reduction)
    -- -Deal 15% Less Damage

-- [Note: Damage Modifiers Stack with other Siphon Perks] ]],

    -- magickaAbsorb = [[Siphon Magicka:
    -- +Absorb 20% of Damage Dealt as Magicka on Strike (Before Damage Reduction)
    -- +Absorb 20% of (Fatigue Damage / 5) as Magicka on Strike (Before Damage Reduction)
    -- -Deal 15% Less Damage

-- [Note: Damage Modifiers Stack with other Siphon Perks] ]],

    hunkerDown    = [[Hunker Down:
When Crouched in Combat:
    +Take 25% Less Damage
    +Take 35% Less Fatigue Damage
    +85% Chance to block Hit Stun
    -Can't Move
    -10% Slower Attack Speed
    -Deal 15% Less Damage
    -15% Easier to Hit]],

    flowingFist   = [[Flowing Fist:
    +Run 20% Faster when Fists are Raised
    +Attack 25% Faster on Top of Normal Bonus
    +15% Bonus to Minimum Attack Pullback
    -Deal 10% Less Health Damage
    -Deal 20% Less Fatigue Damage
    -Take 10% More Damage
    -Attacks Cost More Fatigue: Extra 0.5 Fatigue Per Strike]],

    deflect       = [[Deflecting Stance:
    +Can Block while Unarmed
    +Reflect 50% of Damage When Attack Blocked
    +Rewards Block XP On Block
    -Run 5% Slower when Fists are Raised

[Note: Blocking uses similiar Formula to vanilla blocking,
and has the same Min/Max Chance to Block (10/50 By Default)] ]],

    crushing      = [[Crushing Strike:
    +]],

    astral        = [[Astral Strike:
    +Raises Punch Range to a Cap of 14x: Scales with Hand-to-Hand Level
    -Damage Reduces the Farther Out You are to a Cap of -75%
    -Attack 5% Slower
    -Attacks Require More Precision: Hit Cone Angle Scales With Distance
    -25% Chance for an Enemies Hit Stun to be Negated]],

    sticky = [[Sticky Fingers:
    +(Hand to Hand Level * 0.40)% Chance to Steal an Item on Strike: Up to 3 Times
    -Deal 15% Less Health Damage
    -Deal 35% Less Fatigue Damage

[Note: Stealing Rewards (Value / 5 * Count) Sneak Experience] ]]
}

bs.perkButtons = {
    { perk = "sanctifier",    name = "Sanctifier" },
    { perk = "flowingFist",   name = "Flowing Fist" },
    { perk = "acrobat",   name = "Acrobat" },
    { perk = "healthAbsorb",  name = "Siphon Health" },
    { perk = "magickaAbsorb", name = "Siphon Magicka" },
    { perk = "fatigueAbsorb", name = "Siphon Fatigue" },
    { perk = "hunkerDown",    name = "Hunker Down" },
    { perk = "deflect",       name = "Deflecting Stance" },
    { perk = "astral",        name = "Astral Fist" },
    { perk = "sticky",        name = "Sticky Fingers" },
    -- { perk = "crushing",      name = "Crushing Strike" }, --- Not Sure About Keeping
    -- { perk = "fatigueBoost",  name = "Draining Fists" }, --- Doesnt really fit anymore
    -- { perk = "healthBoost",   name = "Hammer Fists" },--- Doesnt really fit anymore
}

bs.race = {
    argonian = "Argonian",
    breton = "Breton",
    darkElf = "Dark Elf",
    highElf = "High Elf",
    imperial = "Imperial",
    khajiit = "Khajiit",
    nord = "Nord",
    orc = "Orc",
    redguard = "Redguard",
    woodElf = "Wood Elf",
}


bs.rgb = {
    bsPrettyBlue = { 0.235, 0.616, 0.949 },
    bsNiceRed = { 0.941, 0.38, 0.38 },
    bsPrettyGreen = { 0.38, 0.941, 0.525 },
    bsLightGrey = { 0.839, 0.839, 0.839 },
    bsRoyalPurple = { 0.714, 0.039, 0.902 },
    activeColor = { 0.37647062540054, 0.43921571969986, 0.79215693473816 },
    activeOverColor = { 0.6235294342041, 0.66274511814117, 0.87450987100601 },
    activePressedColor = { 0.87450987100601, 0.88627457618713, 0.95686280727386 },
    answerColor = { 0.58823531866074, 0.19607844948769, 0.11764706671238 },
    answerOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    answerPressedColor = { 0.95294123888016, 0.92941182851791, 0.8666667342186 },
    backgroundColor = { 0, 0, 0 },
    bigAnswerColor = { 0.58823531866074, 0.19607844948769, 0.11764706671238 },
    bigAnswerOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    bigAnswerPressedColor = { 0.95294123888016, 0.92941182851791, 0.086274512112141 },
    bigHeaderColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    bigLinkColor = { 0.43921571969986, 0.49411767721176, 0.8117647767067 },
    bigLinkOverColor = { 0.56078433990479, 0.60784316062927, 0.85490202903748 },
    bigLinkPressedColor = { 0.68627452850342, 0.72156864404678, 0.89411771297455 },
    bigNormalColor = { 0.79215693473816, 0.64705884456635, 0.37647062540054 },
    bigNormalOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    bigNormalPressedColor = { 0.95294123888016, 0.92941182851791, 0.8666667342186 },
    bigNotifyColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    blackColor = { 0, 0, 0 },
    countColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    disabledColor = { 0.70196080207825, 0.65882354974747, 0.52941179275513 },
    disabledOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    disabledPressedColor = { 0.95294123888016, 0.92941182851791, 0.8666667342186 },
    fatigueColor = { 0, 0.58823531866074, 0.23529413342476 },
    focusColor = { 0.3137255012989, 0.3137255012989, 0.3137255012989 },
    headerColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    healthColor = { 0.78431379795074, 0.23529413342476, 0.11764706671238 },
    healthNpcColor = { 1, 0.7294117808342, 0 },
    journalFinishedQuestColor = { 0.23529413342476, 0.23529413342476, 0.23529413342476 },
    journalFinishedQuestOverColor = { 0.39215689897537, 0.39215689897537, 0.39215689897537 },
    journalFinishedQuestPressedColor = { 0.86274516582489, 0.86274516582489, 0.86274516582489 },
    journalLinkColor = { 0.14509804546833, 0.19215688109398, 0.43921571969986 },
    journalLinkOverColor = { 0.22745099663734, 0.30196079611778, 0.68627452850342 },
    journalLinkPressedColor = { 0.43921571969986, 0.49411767721176, 0.8117647767067 },
    journalTopicColor = { 0, 0, 0 },
    journalTopicOverColor = { 0.22745099663734, 0.30196079611778, 0.68627452850342 },
    journalTopicPressedColor = { 0.43921571969986, 0.49411767721176, 0.8117647767067 },
    linkColor = { 0.43921571969986, 0.49411767721176, 0.8117647767067 },
    linkOverColor = { 0.56078433990479, 0.60784316062927, 0.85490202903748 },
    linkPressedColor = { 0.68627452850342, 0.72156864404678, 0.89411771297455 },
    magicColor = { 0.20784315466881, 0.27058824896812, 0.6235294342041 },
    magicFillColor = { 0.78431379795074, 0.23529413342476, 0.11764706671238 },
    miscColor = { 0, 0.80392163991928, 0.80392163991928 },
    negativeColor = { 0.78431379795074, 0.23529413342476, 0.11764706671238 },
    normalColor = { 0.79215693473816, 0.64705884456635, 0.37647062540054 },
    normalOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    normalPressedColor = { 0.95294123888016, 0.92941182851791, 0.8666667342186 },
    notifyColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    positiveColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
    weaponFillColor = { 0.78431379795074, 0.23529413342476, 0.11764706671238 },
    whiteColor = { 1, 1, 1 }
}

bs.vfx = {
    absorb = "VFX_Absorb",
    alterationArea = "VFX_AlterationArea",
    alterationCast = "VFX_AlterationCast",
    alterationHit = "VFX_AlterationHit",
    conjureArea = "VFX_ConjureArea",
    conjureCast = "VFX_ConjureCast",
    corprusHit = "VFX_CorprusHit",
    cureHit = "VFX_CureHit",
    defaultArea = "VFX_DefaultArea",
    defaultCast = "VFX_DefaultCast",
    defaultHit = "VFX_DefaultHit",
    destructArea = "VFX_DestructArea",
    destructCast = "VFX_DestructCast",
    destructHit = "VFX_DestructHit",
    drain = "VFX_Drain",
    fireShield = "VFX_FireShield",
    fortifyCast = "VFX_FortifyCast",
    frostArea = "VFX_FrostArea",
    frostCast = "VFX_FrostCast",
    frostHit = "VFX_FrostHit",
    frostShield = "VFX_FrostShield",
    hands = "VFX_Hands",
    illusionArea = "VFX_IllusionArea",
    illusionCast = "VFX_IllusionCast",
    illusionHit = "VFX_IllusionHit",
    levitateCast = "VFX_LevitateCast",
    levitateHit = "VFX_LevitateHit",
    lightningArea = "VFX_LightningArea",
    lightningCast = "VFX_LightningCast",
    lightningHit = "VFX_LightningHit",
    lightningShield = "VFX_LightningShield",
    mysticismArea = "VFX_MysticismArea",
    mysticismCast = "VFX_MysticismCast",
    mysticismHit = "VFX_MysticismHit",
    poisonArea = "VFX_PoisonArea",
    poisonCast = "VFX_PoisonCast",
    poisonHit = "VFX_PoisonHit",
    reflect = "VFX_Reflect",
    restorationArea = "VFX_RestorationArea",
    restorationCast = "VFX_RestorationCast",
    restorationHit = "VFX_RestorationHit",
    shieldCast = "VFX_ShieldCast",
    shieldHit = "VFX_ShieldHit",
    soulTrap = "VFX_Soul_Trap",
    soulTrapHit = "VFX_SoulTrapHit",
    summonEnd = "VFX_Summon_end",
    summonStart = "VFX_Summon_Start",
}

return bs
