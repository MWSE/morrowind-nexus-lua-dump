local core    = require('openmw.core')
local types   = require('openmw.types')
local input   = require('openmw.input')
local anim    = require('openmw.animation')
local self    = require('openmw.self')
local async   = require('openmw.async')
local camera  = require('openmw.camera')
local util    = require('openmw.util')
local ui      = require('openmw.ui')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')
local I       = require('openmw.interfaces')
local debug   = require('openmw.debug')
local nearby  = require('openmw.nearby')

local function debugLog(msg)
    local section = storage.playerSection('SettingsOSSC_General')
    if section and section:get('DebugMode') then
        print("[OSSC] " .. tostring(msg))
    end
end

-- ── State ─────────────────────────────────────────────────────────────────
local isCasting           = false
local hasFiredThisCast    = false
local pendingLaunches     = {}
local currentSpell        = nil
local hasQueuedLaunch     = false
local spellvfx            = false
local isGlowActive        = false
local castStartTime       = 0
local currentCastId       = 0
local currentAnimGroup    = nil
local currentAnimPriority = anim.PRIORITY.Scripted
local prevTriggerValue    = 0.0
local currentFinalSpeed   = 1.0

-- ── NEW — grimoire idle state ──────────────────────────────────────────────
local isGrimoireIdlePlaying = false
local OSSC_PowerCooldowns = {}

local MAGIC_SKILLS = {
    alteration  = { attribute = 'willpower',    specialization = 'magic', name = 'Alteration' },
    conjuration = { attribute = 'intelligence', specialization = 'magic', name = 'Conjuration' },
    destruction = { attribute = 'willpower',    specialization = 'magic', name = 'Destruction' },
    illusion    = { attribute = 'personality',  specialization = 'magic', name = 'Illusion' },
    mysticism   = { attribute = 'willpower',    specialization = 'magic', name = 'Mysticism' },
    restoration = { attribute = 'willpower',    specialization = 'magic', name = 'Restoration' },
    enchant     = { attribute = 'intelligence', specialization = 'magic', name = 'Enchant' }
}

local SCHOOL_STRS = {
    [0]="alteration",[1]="conjuration",[2]="destruction",
    [3]="illusion",[4]="mysticism",[5]="restoration"
}

local INCAPACITATED_GROUPS = {
    "knockdown","knockout","swimknockout","swimknockdown","spellcast",
}

local function levelUpSkill(skillId, newBaseValue)
    local skill = types.NPC.stats.skills[skillId](self)
    skill.base = newBaseValue
    local skillData = MAGIC_SKILLS[skillId]
    local displayName = skillData and skillData.name or skillId
    local skillNameGMST = core.getGMST('sSkill' .. displayName) or displayName
    local skillUpMsg = core.getGMST('sSkillUp') or "Your %s skill has increased to %d."
    ui.showMessage(string.format(skillUpMsg, skillNameGMST, newBaseValue))
    core.sound.playSound3d("skillraise", self)
    local levelStats = types.Player.stats.level(self)
    if levelStats then
        levelStats.progress = (levelStats.progress or 0) + 1
        if skillData then
            local attr = skillData.attribute
            levelStats.skillIncreasesForAttribute[attr] =
                (levelStats.skillIncreasesForAttribute[attr] or 0) + 1
            local spec = skillData.specialization
            levelStats.skillIncreasesForSpecialization[spec] =
                (levelStats.skillIncreasesForSpecialization[spec] or 0) + 1
        end
    end
end

local function getPenaltyScale(rawValue)
    if rawValue == nil then return 1.0 end
    local n = tonumber(rawValue)
    if n == 1 then return 0.75 end
    if n == 2 then return 0.50 end
    if n == 0 then return 1.0 end
    local v = tostring(rawValue):lower():gsub('^%s+',''):gsub('%s+$','')
    if v == "off" or v == "disabled" or v == "" then return 1.0 end
    if v == "reduce_25" or v == "25%" or v == "25" or v == "-25%" then return 0.75 end
    if v == "reduce_50" or v == "50%" or v == "50" or v == "-50%" then return 0.50 end
    if v == "ossc_penalty_off" then return 1.0 end
    if v == "ossc_penalty_25" then return 0.75 end
    if v == "ossc_penalty_50" then return 0.50 end
    return 1.0
end

local function isParalyzedOrSilenced(caster)
    local paralyze = 0
    local silence = 0
    pcall(function()
        local activeEffects = types.Actor.activeEffects(caster)
        if activeEffects then
            local parEffect = activeEffects:getEffect("paralyze")
            local silEffect = activeEffects:getEffect("silence")
            if parEffect then paralyze = parEffect.magnitude or 0 end
            if silEffect then silence = silEffect.magnitude or 0 end
        end
    end)
    return (paralyze > 0) or (silence > 0)
end

local function getDominantSkillSchool(spell)
    if not (spell and spell.effects) then return nil end
    local totals = {}
    for _, eff in ipairs(spell.effects) do
        local mgef = core.magic.effects.records[eff.id]
        if mgef and mgef.school then
            local school = (type(mgef.school)=="string") and mgef.school:lower() or SCHOOL_STRS[mgef.school]
            if school then
                local mag = ((eff.magnitudeMin or 0)+(eff.magnitudeMax or eff.magnitudeMin or 0))*0.5
                local dur = math.max(1, eff.duration or 1)
                local areaFactor = 1+((eff.area or 0)/100)
                local weight = math.max(1,mag)*dur*areaFactor
                totals[school] = (totals[school] or 0)+weight
            end
        end
    end
    local bestSchool, bestWeight = nil, -1
    for school, weight in pairs(totals) do
        if weight > bestWeight then bestWeight=weight; bestSchool=school end
    end
    return bestSchool
end

local function getCastChance(spell, caster)
    if spell.item then return 100 end
    local spellRec = core.magic.spells.records[spell.id]
    if spellRec and spellRec.type == core.magic.SPELL_TYPE.Power then return 100 end
    if not spell.effects or #spell.effects == 0 then return 100 end
    local function getEffectMagnitude(effectId)
        local magnitude = 0
        pcall(function()
            local activeEffects = types.Actor.activeEffects(caster)
            if activeEffects then
                local eff = activeEffects:getEffect(effectId)
                if eff and eff.magnitude then magnitude = eff.magnitude end
            end
        end)
        return magnitude
    end
    if getEffectMagnitude("silence") > 0 then return 0 end
    local magicEffectRecord = core.magic.effects.records[spell.effects[1].id]
    local schoolId = magicEffectRecord and magicEffectRecord.school
    local skillVal = 0
    if schoolId and types.NPC.stats.skills[schoolId] then
        local sk = types.NPC.stats.skills[schoolId]
        if sk then skillVal = sk(caster).modified end
    end
    local willpower = types.Actor.stats.attributes.willpower(caster).modified
    local luck      = types.Actor.stats.attributes.luck(caster).modified
    local cost      = spell.cost or 0
    local soundLevel = getEffectMagnitude("sound")
    local fatigue   = types.Actor.stats.dynamic.fatigue(caster)
    local fatigueTerm = 1.0
    local sec = storage.playerSection('SettingsOSSC_General')
    if sec and sec:get('UseFatigue') and fatigue.base > 0 then
        fatigueTerm = 0.75 + 0.5*(fatigue.current/fatigue.base)
    end
    local baseChance = (skillVal*2)+(willpower/5)+(luck/10)-cost
    local chance = (baseChance-soundLevel)*fatigueTerm
    chance = math.max(0, math.min(100, math.floor(chance+0.5)))
    local chanceScale = getPenaltyScale(sec and sec:get('QuickCastChancePenalty'))
    chance = math.max(0, math.min(100, math.floor((chance*chanceScale)+0.5)))
    return chance
end

local function enableCombatBlock()
    if not I.Controls or not I.Controls.overrideCombatControls then return end
    I.Controls.overrideCombatControls(true)
end

local function disableCombatBlock()
    if not I.Controls or not I.Controls.overrideCombatControls then return end
    I.Controls.overrideCombatControls(false)
end

local function handleCastCosts(spell)
    if debug.isGodMode() then return true end
    if spell.item then return true end
    local canAfford = true
    if I.MagExp_Player and I.MagExp_Player.consumeSpellCost then
        canAfford = I.MagExp_Player.consumeSpellCost(spell.id, nil)
    end
    local sec = storage.playerSection('SettingsOSSC_General')
    if canAfford and sec and sec:get('UseFatigue') then
        local fatigue   = types.Actor.stats.dynamic.fatigue(self)
        local fBase     = core.getGMST('fFatigueSpellBase') or 0
        local fMult     = core.getGMST('fFatigueSpellMult') or 0
        local fCostMult = core.getGMST('fFatigueSpellCostMult') or 1
        local fatigueCost = (fBase + (fMult  *(spell.cost or 0)))*  fCostMult
        if fatigueCost > 0 then
            fatigue.current = math.max(0, fatigue.current - fatigueCost)
        end
    end
    return canAfford
end

-- ── VFX ───────────────────────────────────────────────────────────────────
local function add_cast_static_vfx(bone, vfx_id)
    local spell = currentSpell
    if not spell or not spell.effects or not spell.effects[1] then return end
    local mgef = core.magic.effects.records[spell.effects[1].id]
    if not mgef then return end
    local castStaticId = mgef.castStatic
    local static = castStaticId and types.Static.records[castStaticId]
    if not (static and static.model) then return end
    local opts = { loop=true, vfxId=vfx_id }
    if bone and bone ~= "" then opts.boneName = bone end
    pcall(function() anim.addVfx(self, static.model, opts) end)
end

local function add_particle_swirl_vfx(bone, vfx_id)
    local spell = currentSpell
    if not spell or not spell.effects or not spell.effects[1] then return end
    local mgef = core.magic.effects.records[spell.effects[1].id]
    if not mgef then return end
    local texture = "vfx_starglow.tga"
    if mgef.particle and mgef.particle ~= "" and not mgef.particle:find("blank") then
        texture = mgef.particle
    end
    local opts = { loop=true, vfxId=vfx_id, particleTextureOverride=texture }
    if bone and bone ~= "" then opts.boneName = bone end
    pcall(function() anim.addVfx(self, "meshes/magichand/spellvfx.nif", opts) end)
end

local function add_hand_glow_vfx()
    local spell = currentSpell
    if not (spell and spell.effects and spell.effects[1]) then return end
    local mgef = core.magic.effects.records[spell.effects[1].id]
    if not mgef then return end
    local castGlowOn = storage.playerSection('SettingsOSSC_Keys'):get('EnableCastGlow')
    if not castGlowOn then return end
    pcall(function()
        local castStaticId = mgef.castStatic
        local static = castStaticId and types.Static.records[castStaticId]
        if static and static.model then
            anim.addVfx(self, static.model,
                { loop=true, vfxId="OSSC_HandGlow", boneName="Bip01 L Hand" })
        end
    end)
end

local function add_spell_vfx()
    local settings = storage.playerSection('SettingsOSSC_Keys')
    if settings:get('EnablePlayerSwirls') then add_cast_static_vfx(nil, "OSSC_PlayerSwirl") end
    if settings:get('EnableHandSwirls') then add_particle_swirl_vfx("Bip01 L Hand", "OSSC_HandSwirl") end
    spellvfx = true
end

local function stop_all_vfx()
    anim.removeVfx(self, "OSSC_PlayerSwirl")
    anim.removeVfx(self, "OSSC_HandSwirl")
    anim.removeVfx(self, "OSSC_HandGlow")
    spellvfx     = false
    isGlowActive = false
end

-- ── Cleanup phases ────────────────────────────────────────────────────────
local function launchCleanup(reason)
    debugLog("LaunchCleanup: " .. (reason or ""))
    stop_all_vfx()
    currentSpell    = nil
    hasQueuedLaunch = false
    pendingLaunches = {}
end

local function animUnlock(reason)
    if not isCasting then return end
    debugLog("AnimUnlock: " .. (reason or ""))
    isCasting        = false
    currentAnimGroup = nil
    disableCombatBlock()
end

local function fullCleanup(reason)
    debugLog("FullCleanup: " .. (reason or ""))
    launchCleanup(reason)
    animUnlock(reason)
end

-- ── NEW — Eternal Grimoire helpers ─────────────────────────────────────────
--
-- Returns true when 'eternal_grimoire' is in the CarriedLeft (shield/light) slot.
local function hasEternalGrimoire()
    local equipment = types.Actor.equipment(self)
    if not equipment then return false end
    local item = equipment[types.Actor.EQUIPMENT_SLOT.CarriedLeft]
    if not item or not item:isValid() then return false end
    local rid = nil
    pcall(function() rid = item.recordId end)
    return rid ~= nil and rid:lower() == "eternal_grimoire"
end

-- Returns true when the player is currently in Spell stance.
local function isInSpellStance()
    local stance = nil
    pcall(function() stance = types.Actor.getStance(self) end)
    return stance == types.Actor.STANCE.Spell
end

-- Combined gate used by both the idle loop and the cast override.
local function grimoireConditionMet()
    return hasEternalGrimoire() and not isInSpellStance()
end

-- Starts the egidle2 loop at Default priority (so any Scripted cast
-- will visually override it without cancelling the underlying cycle).
local function startGrimoireIdle()
    if isGrimoireIdlePlaying then return end
    isGrimoireIdlePlaying = true
    debugLog("Grimoire idle: starting egidle2 loop")
    pcall(function()
        I.AnimationController.playBlendedAnimation('egidle2', {
            priority  = {
                [anim.BONE_GROUP.LeftArm]   = anim.PRIORITY.Default,
                [anim.BONE_GROUP.Torso]     = anim.PRIORITY.Default,
                [anim.BONE_GROUP.RightArm]  = anim.PRIORITY.Default,
                [anim.BONE_GROUP.LowerBody] = anim.PRIORITY.Default,
            },
            startKey  = 'loop start',
            stopKey   = 'loop stop',
            blendMask = anim.BLEND_MASK.LeftArm  + anim.BLEND_MASK.Torso +
                        anim.BLEND_MASK.RightArm + anim.BLEND_MASK.LowerBody,
            speed     = 1.0,
        })
    end)
end

-- Immediately cancels the egidle2 loop.
local function stopGrimoireIdle()
    if not isGrimoireIdlePlaying then return end
    isGrimoireIdlePlaying = false
    debugLog("Grimoire idle: stopping egidle2 loop")
    pcall(function() anim.cancel(self, 'egidle2') end)
end

-- ── END NEW ────────────────────────────────────────────────────────────────

-- ── Shared cast startup function ──────────────────────────────────────────
local function triggerQuickCast()
    local uiMode = (ui and ui.activeMode)
    if not uiMode and I.UI and I.UI.getMode then uiMode = I.UI.getMode() end
    if uiMode ~= nil or core.isWorldPaused() or isCasting then
        if isCasting then
            debugLog("Input rejected — cast in progress (currentAnimGroup=" ..
                tostring(currentAnimGroup) .. ")")
        end
        return
    end
    if isParalyzedOrSilenced(self) then
        debugLog("Cast blocked — paralyzed or silenced")
        return
    end

    local function abortCast(msg)
        fullCleanup(msg or "aborted")
    end

    for _, groupName in ipairs(INCAPACITATED_GROUPS) do
        if anim.isPlaying(self, groupName) then return abortCast("incapacitated") end
    end

    -- ── Resolve spell / enchanted item ────────────────────────────────────
    local activeSpell = nil
    local selectedItem = nil
    pcall(function() selectedItem = types.Actor.getSelectedEnchantedItem(self) end)
    if selectedItem and selectedItem:isValid() then
        local rec = nil
        pcall(function()
            if selectedItem.type == types.Weapon   then rec = types.Weapon.record(selectedItem)
            elseif selectedItem.type == types.Armor   then rec = types.Armor.record(selectedItem)
            elseif selectedItem.type == types.Clothing then rec = types.Clothing.record(selectedItem)
            elseif selectedItem.type == types.Book     then rec = types.Book.record(selectedItem)
            elseif selectedItem.type == types.MiscItem then rec = types.MiscItem.record(selectedItem)
            end
        end)
        if rec and rec.enchant then
            local enchRec = core.magic.enchantments.records[rec.enchant]
            if enchRec then
                activeSpell = {
                    id=rec.enchant, item=selectedItem, enchantment=enchRec,
                    effects=enchRec.effects or {}, cost=enchRec.cost or 1
                }
            end
        end
    end

    local activeSpellResult = nil
    if not activeSpell then
        pcall(function() activeSpellResult = core.magic.getSelectedSpell() end)
        if not activeSpellResult then
            pcall(function() activeSpellResult = types.Actor.getSelectedSpell(self) end)
        end
        if not activeSpellResult then
            pcall(function() activeSpellResult = types.Player.getSelectedSpell(self) end)
        end
        if not activeSpellResult or activeSpellResult == "" then
            return abortCast("nothing selected")
        end
        if type(activeSpellResult) == "table" then
            activeSpell = activeSpellResult
        elseif type(activeSpellResult) == "userdata" then
            local isObject = false
            pcall(function() if activeSpellResult.recordId then isObject=true end end)
            if isObject then
                local item = activeSpellResult
                local rec  = nil
                pcall(function()
                    if item.type == types.Weapon   then rec = types.Weapon.record(item)
                    elseif item.type == types.Armor   then rec = types.Armor.record(item)
                    elseif item.type == types.Clothing then rec = types.Clothing.record(item)
                    elseif item.type == types.Book     then rec = types.Book.record(item)
                    elseif item.type == types.MiscItem then rec = types.MiscItem.record(item)
                    end
                end)
                if rec and rec.enchant then
                    local enchRec = core.magic.enchantments.records[rec.enchant]
                    activeSpell = {
                        id=rec.enchant, item=item, enchantment=enchRec,
                        effects=enchRec and enchRec.effects or {},
                        cost=enchRec and enchRec.cost or 1
                    }
                end
            else
                activeSpell = {
                    id=activeSpellResult.id, effects=activeSpellResult.effects,
                    cost=activeSpellResult.cost or 0, type=activeSpellResult.type
                }
            end
        else
            activeSpell = { id = activeSpellResult }
        end
    end

    if not (activeSpell and activeSpell.id) then return abortCast("could not resolve spell") end
    local spellId  = activeSpell.id
    local spellRec = core.magic.spells.records[spellId]
    if not spellRec and activeSpell.enchantment then spellRec = activeSpell.enchantment end
    if not spellRec then return abortCast("no spell record") end
    if spellRec.type == core.magic.SPELL_TYPE.Power then
        ui.showMessage("You need bigger focus to cast powers. Use spell stance.")
        return abortCast("power blocked")
    end

    currentSpell = activeSpell
    print("[OSSC] Casting: "..tostring(spellId))
    core.sendGlobalEvent('MagExp_BreakInvisibility', { actor = self })

    -- ── Choose animation group ─────────────────────────────────────────────
    local range = core.magic.RANGE.Target
    if activeSpell.effects and activeSpell.effects[1] then
        range = activeSpell.effects[1].range or core.magic.RANGE.Target
    end
    local schoolStr = "destruction"
    if activeSpell.effects and activeSpell.effects[1] then
        local mgef = core.magic.effects.records[activeSpell.effects[1].id]
        if mgef and mgef.school then
            local S = {
                [0]="alteration",[1]="conjuration",[2]="destruction",
                [3]="illusion",[4]="mysticism",[5]="restoration"
            }
            schoolStr = (type(mgef.school)=="string") and mgef.school:lower()
                or S[mgef.school] or "destruction"
        end
    end
    if activeSpell.item then
        schoolStr = getDominantSkillSchool(activeSpell) or "destruction"
    end

    local camMode     = camera.getMode()
    local perspSuffix = (camMode == camera.MODE.FirstPerson) and '1st' or '3rd'
    local rangeStr = 'Target'
    if range == core.magic.RANGE.Self  then rangeStr = 'Self'
    elseif range == core.magic.RANGE.Touch then rangeStr = 'Touch' end
    local schoolKey     = schoolStr:sub(1,1):upper() .. schoolStr:sub(2)
    local animSection   = storage.playerSection('SettingsOSSC_Animations')
    local animLookupKey = 'Anim_' .. schoolKey .. '_' .. rangeStr .. '_' .. perspSuffix
    local animGroup     = animSection:get(animLookupKey) or 'quickcast'
    debugLog("AnimGroup resolved: key=" .. animLookupKey .. " → " .. animGroup)

    -- ── CHANGED — grimoire cast override ──────────────────────────────────
    if grimoireConditionMet() then
        animGroup = 'eqcastr'
        debugLog("Grimoire equipped, not in spell stance — overriding animGroup with 'eqcastr'")
    end
    -- ── END CHANGED ────────────────────────────────────────────────────────

    local groupSpeedKey = {
        ['quickcast'] = 'AnimSpeed_Quickcast',
        ['quickbuff'] = 'AnimSpeed_Quickbuff',
        ['qcconj']    = 'AnimSpeed_Qcconj',
        ['qctouch']   = 'AnimSpeed_Qctouch',
        ['qcalt']     = 'AnimSpeed_Qcalt',
        ['qcalts']    = 'AnimSpeed_Qcalts',
        ['qcill']     = 'AnimSpeed_Qcill',
        ['qcsnap']    = 'AnimSpeed_Qcsnap',
        ['qcdrain']   = 'AnimSpeed_Qcdrain',
        ['qcskrow']   = 'AnimSpeed_Qcskrow',
        ['eqcastr']   = 'AnimSpeed_Quickcast',
    }
    local animSpeedSection = storage.playerSection('SettingsOSSC_AnimSpeeds')
    local speedKey   = groupSpeedKey[animGroup] or 'AnimSpeed_Quickcast'
    local baseSpeed  = animSpeedSection and animSpeedSection:get(speedKey) or 1.00
    local finalSpeed = baseSpeed * (animSpeedSection and animSpeedSection:get('AnimSpeedScale') or 1.0)
    if finalSpeed <= 0 then finalSpeed = 1.0 end
    currentFinalSpeed = finalSpeed

    local safetyUnlockDelay = 1.0
    if animSpeedSection then
        safetyUnlockDelay = animSpeedSection:get('SafetyUnlockTimer') or 1.0
    end
    if safetyUnlockDelay <= 0 then safetyUnlockDelay = 1.0 end
    local scaledSafetyUnlockDelay = (safetyUnlockDelay + 1.0) / finalSpeed

    local now = core.getSimulationTime()
    isCasting        = true
    hasFiredThisCast = false
    hasQueuedLaunch  = false
    pendingLaunches  = {}
    currentCastId = currentCastId + 1
    castStartTime = now
    enableCombatBlock()

    local safetyUnlockCastId = currentCastId
    async:newUnsavableSimulationTimer(scaledSafetyUnlockDelay, function()
        if not isCasting then return end
        if currentCastId ~= safetyUnlockCastId then return end
        local isIncapacitated = false
        for _, incapGroup in ipairs({'knockdown','knockout','swimknockdown','swimknockout'}) do
            if anim.isPlaying(self, incapGroup) then
                isIncapacitated = true
                debugLog("Safety unlock blocked — incapacitated in " .. incapGroup)
                break
            end
        end
        if not isIncapacitated then
            debugLog("Safety unlock timer fired ("..scaledSafetyUnlockDelay.."s) — forcing full cleanup")
            fullCleanup("safety unlock timer")
        end
    end)

    currentAnimGroup = animGroup
    pcall(function()
        I.AnimationController.playBlendedAnimation(animGroup, {
            priority = {
                [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
                [anim.BONE_GROUP.Torso]   = anim.PRIORITY.Scripted,
            },
            startKey  = 'start',
            stopKey   = 'stop',
            blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso +
                        anim.BLEND_MASK.RightArm + anim.BLEND_MASK.LowerBody,
            speed     = finalSpeed
        })
    end)

    local fallbackCastId = currentCastId
    async:newUnsavableSimulationTimer(0.01, function()
        if not isCasting or currentCastId ~= fallbackCastId then return end
        if not anim.isPlaying(self, animGroup) then
            local fallback
            if grimoireConditionMet() then
                fallback = 'eqcastr'
            else
                fallback = (range == core.magic.RANGE.Self) and 'quickbuff' or 'quickcast'
            end
            debugLog("Fallback: " .. animGroup .. " → " .. fallback)
            currentAnimGroup = fallback
            pcall(function()
                I.AnimationController.playBlendedAnimation(fallback, {
                    priority  = anim.PRIORITY.Scripted,
                    startKey  = 'start',
                    stopKey   = 'stop',
                    speed     = finalSpeed,
                    blendMask = 15
                })
            end)
        end
    end)
end

-- ── onUpdate ──────────────────────────────────────────────────────────────
local function onUpdate(dt)
    local keysSection   = storage.playerSection('SettingsOSSC_Keys')
    local triggerChoice = keysSection and keysSection:get('QuickCastTrigger') or 'none'
    if triggerChoice ~= 'none' then
        local threshold = (keysSection and keysSection:get('QuickCastTriggerThreshold')) or 0.60
        local axisId = nil
        if triggerChoice == 'l2' then
            axisId = input.CONTROLLER_AXIS.TriggerLeft
        elseif triggerChoice == 'r2' then
            axisId = input.CONTROLLER_AXIS.TriggerRight
        end
        if axisId then
            local currentValue = 0.0
            pcall(function()
                currentValue = input.getAxisValue(axisId) or 0.0
            end)
            local wasPressed = prevTriggerValue >= threshold
            local isPressed  = currentValue     >= threshold
            if isPressed and not wasPressed then
                debugLog("Trigger rising edge: " .. tostring(triggerChoice) ..
                    " value=" .. tostring(currentValue))
                triggerQuickCast()
            end
            prevTriggerValue = currentValue
        end
    else
        prevTriggerValue = 0.0
    end

    do
        local condMet = grimoireConditionMet()
        if condMet and not isGrimoireIdlePlaying and not isCasting then
            startGrimoireIdle()
        elseif not condMet and isGrimoireIdlePlaying then
            stopGrimoireIdle()
        end
    end

    if #pendingLaunches == 0 then return end
    local currentTime = core.getSimulationTime()
    for i = #pendingLaunches, 1, -1 do
        local pl = pendingLaunches[i]
        if pl.castId ~= currentCastId then
            table.remove(pendingLaunches, i)
        elseif currentTime >= pl.timeToFire then
            table.remove(pendingLaunches, i)
            local spell = pl.spell
            if spell then
                local chance = getCastChance(spell, self)
                if debug.isGodMode() then chance = 100 end
                chance = math.max(0, math.min(100, chance))
                local okCast = debug.isGodMode() or chance >= 100
                if not okCast then okCast = math.random(0,99) < chance end
                local isItem = spell.item ~= nil
                debugLog("Casting "..tostring(spell.id).." chance="..chance.." ok="..tostring(okCast))
                if okCast then
                    local resourcesPaid = handleCastCosts(spell)
                    if resourcesPaid then
                        local pitch     = -(camera.getPitch()+camera.getExtraPitch())
                        local yaw       =   camera.getYaw()+camera.getExtraYaw()
                        local cosPitch  = math.cos(pitch)
                        local cameraDir = util.vector3(
                            cosPitch*math.sin(yaw),
                            cosPitch*math.cos(yaw),
                            math.sin(pitch))
                        local flatForward = util.vector3(cameraDir.x, cameraDir.y, 0):normalize()
                        local leftDir     = util.vector3(-flatForward.y, flatForward.x, 0)
                        local startPos
                        if camera.getMode() == camera.MODE.FirstPerson then
                            startPos = camera.getPosition()
                                + flatForward * 40
                                - util.vector3(0,0,8)
                                + leftDir * 35
                        else
                            startPos = self.position
                                + flatForward * 40
                                + util.vector3(0,0,115)
                                + leftDir * 25
                        end
                        local cameraPos = camera.getPosition()
                        local endPos    = cameraPos + cameraDir * 10000
                        local ray = nearby.castRay(cameraPos, endPos, { ignore = self })
                        debugLog(string.format("Raycast: hit=%s hitObject=%s", tostring(ray.hit), tostring(ray.hitObject and ray.hitObject.recordId or "nil")))
                        local range = core.magic.RANGE.Target
                        local spellRec = core.magic.spells.records[spell.id] or spell.enchantment
                        local hasTouchEffects = false
                        if spellRec and spellRec.effects then
                            for _, eff in ipairs(spellRec.effects) do
                                if eff.range == core.magic.RANGE.Touch then
                                    hasTouchEffects = true
                                    break
                                end
                            end
                            if spellRec.effects[1] then
                                range = spellRec.effects[1].range
                            end
                        end
                        local hitObject = nil
                        if range == core.magic.RANGE.Touch and (not ray.hit or not ray.hitObject) then
                            local rightDir = leftDir * -1
                            local upDir    = cameraDir:cross(rightDir):normalize()
                            local offsets = {
                                leftDir*10+upDir*10, leftDir*10-upDir*10,
                                leftDir*-10+upDir*10, leftDir*-10-upDir*10
                            }
                            for _, offset in ipairs(offsets) do
                                local altEnd = endPos+offset
                                local altRay = nearby.castRay(cameraPos, altEnd, { ignore = self })
                                if altRay.hit and altRay.hitObject then
                                    local t = altRay.hitObject.type
                                    if (t==types.NPC or t==types.Creature) and
                                       not types.Actor.isDead(altRay.hitObject) then
                                        ray = altRay; break
                                    elseif t ~= types.NPC and t ~= types.Creature then
                                        ray = altRay; break
                                    end
                                end
                            end
                        end
                        if range ~= core.magic.RANGE.Self or hasTouchEffects then
                            local candidateHit = ray.hit and ray.hitObject or nil
                            if candidateHit then
                                local hitValid = false
                                local hitType  = nil
                                pcall(function()
                                    hitType  = candidateHit.type
                                    hitValid = (hitType ~= nil)
                                end)
                                if hitValid and candidateHit ~= self then
                                    if hitType == types.NPC or hitType == types.Creature then
                                        if not types.Actor.isDead(candidateHit) then
                                            hitObject = candidateHit
                                        end
                                    else
                                        hitObject = candidateHit
                                    end
                                end
                            end
                        end
                        local aimPoint       = ray.hit and ray.hitPos or endPos
                        local distFromPlayer = (aimPoint - self.position):length()
                        local skewedDir      = (aimPoint - startPos):normalize()
                        if range == core.magic.RANGE.Touch and hitObject then
                            local fMaxActivateDist = core.getGMST('fMaxActivateDist') or 150
                            local maxDist = fMaxActivateDist + camera.getThirdPersonDistance() + 25
                            local telekinesis = types.Actor.activeEffects(self)
                                 :getEffect(core.magic.EFFECT_TYPE.Telekinesis)
                             if telekinesis then maxDist = maxDist + telekinesis.magnitude*22 end
                             local distFromEye = (aimPoint - cameraPos):length()
                             if distFromEye > maxDist then hitObject = nil end
                         end
                         local spawnOffset = 80
                         if hitObject and distFromPlayer < 200 then spawnOffset = 10 end
                        local kineticSpells = { kinetic_bolt = true, kinetic_expl = true }
                        local sentCastRequest = false
                        if not kineticSpells[spell.id] then
                            local general = storage.playerSection('SettingsOSSC_General')
                            local effectScale = getPenaltyScale(
                                general and general:get('QuickCastEffectPenalty'))
                            local usesPrepaidResource =
                                (I.MagExp_Player and I.MagExp_Player.consumeSpellCost) ~= nil
                            local isEnchantment = spell.item ~= nil
                            debugLog(string.format("Sending CastRequest: spell=%s range=%d hitObject=%s attacker=%s",
                                tostring(spell.id), range,
                                tostring(hitObject and hitObject.recordId or "nil"),
                                tostring((range == core.magic.RANGE.Self) and "nil (self cast)" or (self and self.recordId or "nil"))))
                            
                            local showAll = true
                            local sMagExp = storage.playerSection('SettingsMagExp_General')
                            if sMagExp then
                                local val = sMagExp:get('ShowAllCastVfx')
                                if val ~= nil then showAll = val end
                            end

                            core.sendGlobalEvent('MagExp_CastRequest', {
                                attacker     = (range == core.magic.RANGE.Self) and nil or self,
                                spellId      = spell.id,
                                startPos     = startPos,
                                direction    = skewedDir,
                                area         = spell.area,
                                isFree       = (not isEnchantment) and usesPrepaidResource or false,
                                item         = spell.item,
                                itemRecordId = spell.item and spell.item.recordId or nil,
                                hitObject    = hitObject,
                                spawnOffset  = spawnOffset,
                                isGodMode    = debug.isGodMode(),
                                effectScale  = effectScale,
                                showAllCastVfx = showAll,
                            })
                            sentCastRequest = true
                        end
                        local generalSection = storage.playerSection('SettingsOSSC_General')
                        local keySection     = storage.playerSection('SettingsOSSC_Keys')
                        local xpGain   = generalSection:get('SkillExperience') or 0
                        local susCompat = keySection and keySection:get('SkillUsesScaledCompatibility')
                        local function awardSkillXP(skillId)
                            local skill = types.NPC.stats.skills[skillId](self)
                            if not skill or skill.base >= 100 then return end
                            local prog = skill.progress + (xpGain*0.01)
                            local base = skill.base
                            while prog >= 1.00 and base < 100 do
                                base = base+1; prog = prog-1.00
                                levelUpSkill(skillId, base)
                            end
                            skill.progress = math.max(0, prog)
                        end
                        if sentCastRequest then
                            local function resolveMagicSchool()
                                local sr = core.magic.spells.records[spell.id]
                                local school = nil
                                if sr and sr.school then
                                    school = (type(sr.school)=="string") and sr.school:lower()
                                        or SCHOOL_STRS[sr.school]
                                end
                                return school or getDominantSkillSchool(spell)
                            end
                            if isItem then
                                awardSkillXP('enchant')
                            elseif susCompat and I.SkillProgression and I.SkillProgression.skillUsed then
                                local school = resolveMagicSchool()
                                if school and MAGIC_SKILLS[school] then
                                    local spellForSus = core.magic.spells.records[spell.id]
                                    if not spellForSus and spell.effects and type(spell.cost)=="number" then
                                        spellForSus = spell
                                    end
                                    local dtSus, prevSpell = nil, nil
                                    for _, path in ipairs({
                                        'scripts.Skill_Uses_Scaled.data',
                                        'scripts.skill_uses_scaled.data',
                                    }) do
                                        local ok, m = pcall(require, path)
                                        if ok and m and m.pc then dtSus=m; break end
                                    end
                                    if dtSus and spellForSus then
                                        prevSpell = dtSus.pc.spell
                                        dtSus.pc.spell = spellForSus
                                    end
                                    local useType = 0
                                    pcall(function()
                                        useType = I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success
                                    end)
                                    local opts = (xpGain > 0)
                                        and { useType=useType, skillGain=xpGain*0.01 }
                                        or  { useType=useType }
                                    local okUsed = pcall(function()
                                        I.SkillProgression.skillUsed(school, opts)
                                    end)
                                    if dtSus then dtSus.pc.spell = prevSpell end
                                    if not okUsed and xpGain > 0 then awardSkillXP(school) end
                                end
                            else
                                local school = resolveMagicSchool()
                                if school and MAGIC_SKILLS[school] then awardSkillXP(school) end
                            end
                        end
                    else
                        pcall(function() core.sound.playSound3d("spell failure illusion", self) end)
                    end
                else
                    handleCastCosts(spell)
                    ui.showMessage("You failed casting the spell.")
                    pcall(function() core.sound.playSound3d("spell failure illusion", self) end)
                end
            end
            launchCleanup("launch resolved")
            break
        end
    end
end

-- ── onTextKey ─────────────────────────────────────────────────────────────
local function onTextKey(groupname, key)
    if not isCasting then return end
    if groupname ~= currentAnimGroup then return end
    local lowerKey = tostring(key):lower()
    debugLog("TextKey ["..groupname.."] '"..lowerKey.."'")
    if lowerKey == 'start' or lowerKey == 'equip start' then
        if hasQueuedLaunch then return end
        hasQueuedLaunch = true
        local spell = currentSpell
        if spell and spell.effects and spell.effects[1] then
            local mgef = core.magic.effects.records[spell.effects[1].id]
            if mgef then
                local sStr = "destruction"
                local school = mgef.school
                local SCHOOL = core.magic.SCHOOL or {
                    Alteration=0,Conjuration=1,Destruction=2,
                    Illusion=3,Mysticism=4,Restoration=5
                }
                if type(school) == "string" then sStr = school:lower()
                else
                    if school == SCHOOL.Restoration then sStr = "restoration"
                    elseif school == SCHOOL.Illusion   then sStr = "illusion"
                    elseif school == SCHOOL.Conjuration then sStr = "conjuration"
                    elseif school == SCHOOL.Alteration  then sStr = "alteration"
                    elseif school == SCHOOL.Mysticism   then sStr = "mysticism" end
                end
                local sndId = sStr.." cast"
                if mgef.castSound and mgef.castSound ~= "" then sndId = mgef.castSound end
                local castGlowOn = storage.playerSection('SettingsOSSC_Keys'):get('EnableCastGlow')
                if castGlowOn then isGlowActive=true; add_hand_glow_vfx() end
                pcall(function() core.sound.playSound3d(sndId, self, { volume=1.0 }) end)
            end
            add_spell_vfx()
        end
        if currentAnimGroup == 'qcsnap' then
            local animSection = storage.playerSection('SettingsOSSC_Animations')
            local snapVol = animSection:get('SnapSoundVolume') or 0.45
            snapVol = math.max(0.0, math.min(1.0, snapVol))
            debugLog("Playing snap sound on start+0.6s offset: volume=" .. snapVol)
            ambient.playSoundFile("sound/ossc/qcsnap.mp3",
                { timeOffset=0.6, volume=snapVol, loop=false })
        end
        local safetySpell  = currentSpell
        local safetyCastId = currentCastId
        local safetyTimerDuration = 0.96 / currentFinalSpeed
        async:newUnsavableSimulationTimer(safetyTimerDuration, function()
            if not isCasting then return end
            if currentCastId ~= safetyCastId then return end
            if hasFiredThisCast then return end
            debugLog("Safety launch timer fired for group '" .. groupname .. "' (no 'release' key) duration="..safetyTimerDuration)
            hasFiredThisCast = true
            if safetySpell then
                table.insert(pendingLaunches, {
                    spell      = safetySpell,
                    castId     = safetyCastId,
                    timeToFire = core.getSimulationTime()
                })
            end
        end)
    elseif lowerKey == 'release' then
        if hasFiredThisCast then return end
        hasFiredThisCast = true
        debugLog("'release' — queuing launch castId="..currentCastId)
        if currentSpell then
            table.insert(pendingLaunches, {
                spell      = currentSpell,
                castId     = currentCastId,
                timeToFire = core.getSimulationTime()
            })
        end
    elseif lowerKey == 'stop' then
        debugLog("'stop' key — unlocking castId="..currentCastId)
        animUnlock("stop key ["..groupname.."]")
    end
end

-- ── Incapacitation text key handler ───────────────────────────────────────
local function onIncapacitationTextKey(groupname, key)
    local lowerKey   = tostring(key):lower()
    local lowerGroup = tostring(groupname):lower()
    debugLog("IncapTextKey ["..groupname.."] '"..lowerKey.."'")
    if lowerKey == 'stop' then
        if lowerGroup == 'knockdown'     or lowerGroup == 'knockout' or
           lowerGroup == 'swimknockdown' or lowerGroup == 'swimknockout' then
            debugLog("Incapacitation stop — unlocking from " .. groupname)
            animUnlock("incap stop [" .. groupname .. "]")
        end
    end
end

-- ── NEW — egidle2 text key handler ─────────────────────────────────────────
local function onegidle2TextKey(groupname, key)
    local lowerKey = tostring(key):lower()
    debugLog("egidle2 TextKey ["..groupname.."] '"..lowerKey.."'")
    if lowerKey == 'loop stop' then
        isGrimoireIdlePlaying = false
        if grimoireConditionMet() then
            startGrimoireIdle()
        else
            debugLog("egidle2 loop stop — conditions no longer met, not restarting")
        end
    end
end

-- ── Action handler ────────────────────────────────────────────────────────
input.registerActionHandler('OSSC_QuickCast', async:callback(function(pressed)
    if not pressed then return end
    triggerQuickCast()
end))

-- ── Text key handlers ─────────────────────────────────────────────────────
if I.AnimationController then
    local groups = {
        'quickcast','quickbuff','qcconj','qctouch',
        'qcalt','qcalts','qcill','qcsnap','qcdrain','qcskrow',
        'eqcastr',   
    }
    for _, g in ipairs(groups) do
        I.AnimationController.addTextKeyHandler(g, onTextKey)
    end

    local incapGroups = { 'knockdown','knockout','swimknockdown','swimknockout' }
    for _, g in ipairs(incapGroups) do
        I.AnimationController.addTextKeyHandler(g, onIncapacitationTextKey)
    end

    I.AnimationController.addTextKeyHandler('egidle2', onegidle2TextKey)
else
    debugLog("AnimationController interface not available.")
end

debugLog("--- OSSC PLAYER SCRIPT INITIALIZED ---")

local function onSave() return { powerCooldowns = OSSC_PowerCooldowns } end
local function onLoad(data)
    if data and data.powerCooldowns then OSSC_PowerCooldowns = data.powerCooldowns end
end

return {
    engineHandlers = { onUpdate=onUpdate, onSave=onSave, onLoad=onLoad },
    eventHandlers  = {
        AddVfx      = function(data) pcall(function() anim.addVfx(self, data.model, data.options) end) end,
        RemoveVfx   = function(vId)  pcall(function() anim.removeVfx(self, vId) end) end,
        PlaySound3d = function(data) pcall(function() core.sound.playSound3d(data.sound, self) end) end,
        MagExp_Local_MagicHit = function(data)
            debugLog(string.format("Received MagicHit: %s", tostring(data)))
        end
    }
}
