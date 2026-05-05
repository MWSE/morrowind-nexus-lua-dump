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
local lastCameraMode      = nil
local castStartTime       = 0
local lastCastAttemptTime = 0
local currentCastId       = 0
local currentAnimGroup    = nil
local currentAnimPriority = anim.PRIORITY.Scripted

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

    -- Enchantments: let MagExp global script (launchSpell) handle charges/scrolls.
    -- We only handle magicka/fatigue here.
    if spell.item then
        return true
    end

    local canAfford = true
    if I.MagExp_Player and I.MagExp_Player.consumeSpellCost then
        -- Spell magicka cost only, no item object
        canAfford = I.MagExp_Player.consumeSpellCost(spell.id, nil)
    end

    local sec = storage.playerSection('SettingsOSSC_General')
    if canAfford and sec and sec:get('UseFatigue') then
        local fatigue   = types.Actor.stats.dynamic.fatigue(self)
        local fBase     = core.getGMST('fFatigueSpellBase') or 0
        local fMult     = core.getGMST('fFatigueSpellMult') or 0
        local fCostMult = core.getGMST('fFatigueSpellCostMult') or 1
        local fatigueCost = (fBase + (fMult * (spell.cost or 0))) * fCostMult
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
    spellvfx    = false
    isGlowActive = false
end

local function refresh_vfx()
    stop_all_vfx()
    if spellvfx    then add_spell_vfx()    end
    if isGlowActive then add_hand_glow_vfx() end
end

-- ── Full cast cleanup (called from one place only) ────────────────────────
local function fullCleanup(reason)
    debugLog("Cleanup: " .. (reason or ""))
    stop_all_vfx()
    isCasting        = false
    currentSpell     = nil
    hasQueuedLaunch  = false
    -- FIX (double-launch): hasFiredThisCast stays true until a NEW cast begins.
    -- It is only reset in the action handler when a fresh cast is confirmed.
    currentAnimGroup = nil
    disableCombatBlock()
end

-- ── onUpdate ──────────────────────────────────────────────────────────────
local function onUpdate(dt)
    local curCamMode = camera.getMode()
    if lastCameraMode ~= curCamMode then
        lastCameraMode = curCamMode
        if isCasting and (spellvfx or isGlowActive) then refresh_vfx() end
    end

    if #pendingLaunches == 0 then return end

    local currentTime = core.getSimulationTime()

    -- FIX (double-launch): process AT MOST ONE launch per frame and break
    -- immediately after. This prevents two entries resolving in the same tick
    -- if they somehow share a castId.
    for i = #pendingLaunches, 1, -1 do
        local pl = pendingLaunches[i]

        -- Discard entries from previous casts
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
                        -- ── Direction / position ──────────────────────────
                        local pitch     = -(camera.getPitch()+camera.getExtraPitch())
                        local yaw       =   camera.getYaw()+camera.getExtraYaw()
                        local cosPitch  = math.cos(pitch)
                        local cameraDir = util.vector3(
                            cosPitch*math.sin(yaw),
                            cosPitch*math.cos(yaw),
                            math.sin(pitch))
                        local flatForward = util.vector3(cameraDir.x, cameraDir.y, 0):normalize()
                        local leftDir     = util.vector3(-flatForward.y, flatForward.x, 0)

                        -- FIX (self-absorption): push startPos further forward
                        -- so the projectile never spawns inside the player capsule.
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

                        local range = core.magic.RANGE.Target
                        local spellRec = core.magic.spells.records[spell.id] or spell.enchantment
                        local hasTouchEffects = false
                        
                        -- Check if spell has ANY Touch effects, not just the first one
                        if spellRec and spellRec.effects then
                            for _, eff in ipairs(spellRec.effects) do
                                if eff.range == core.magic.RANGE.Touch then
                                    hasTouchEffects = true
                                    break
                                end
                            end
                            -- Use first effect for primary range determination
                            if spellRec.effects[1] then
                                range = spellRec.effects[1].range
                            end
                        end

                        -- FIX (self-absorption): NEVER pass self as hitObject to MagExp.
                        -- For RANGE.Self, send hitObject = nil — MagExp applies self-range
                        -- effects to the attacker automatically.
                        -- UNLESS the spell also has Touch effects that need a target
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

                        -- FIX (empty-object error): validate hitObject via pcall
                        -- before using it. An invalid/despawned object has no class.
                        -- Also set hitObject for spells with Touch effects, even if primary range is Self
                        if range ~= core.magic.RANGE.Self or hasTouchEffects then
                            local candidateHit = ray.hit and ray.hitObject or nil
                            if candidateHit then
                                local hitValid = false
                                local hitType  = nil
                                pcall(function()
                                    hitType  = candidateHit.type
                                    hitValid = (hitType ~= nil)
                                end)
                                -- Also reject self — projectile should never target its caster
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

    core.sendGlobalEvent('MagExp_CastRequest', {
        attacker     = self,
        spellId      = spell.id,
        startPos     = startPos,
        direction    = skewedDir,
        area         = spell.area,
        -- Spells: cost already handled locally → isFree=true.
        -- Enchantments: let launchSpell do charges → isFree=false.
        isFree       = (not isEnchantment) and usesPrepaidResource or false,
        item         = spell.item,
        itemRecordId = spell.item and spell.item.recordId or nil,
        hitObject    = hitObject,
        spawnOffset  = spawnOffset,
        isGodMode    = debug.isGodMode(),
        effectScale  = effectScale,
    })
    sentCastRequest = true
end

                        -- ── Skill XP ──────────────────────────────────────
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
                        -- Resources not available
                        pcall(function() core.sound.playSound3d("spell failure illusion", self) end)
                    end
                else
                    -- Failed roll
                    handleCastCosts(spell)
                    ui.showMessage("You failed casting the spell.")
                    pcall(function() core.sound.playSound3d("spell failure illusion", self) end)
                end
            end

            -- FIX (double-launch): cleanup after the single resolved entry,
            -- then BREAK so no further entries are processed this frame.
            -- lastCastAttemptTime is reset here so the cooldown starts from
            -- resolution, not from when the button was pressed.
            
            fullCleanup("launch resolved")
            break
        end
    end
end

-- ── onTextKey ─────────────────────────────────────────────────────────────
local function onTextKey(groupname, key)
    if not isCasting then return end

    -- FIX (wrong-group keys): only process the group we actually started.
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

    elseif lowerKey == 'release' then
        -- FIX (double-launch): guard with hasFiredThisCast, which is only cleared
        -- at the very start of a brand-new cast in the action handler.
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
    end
    -- 'stop' and all other keys intentionally ignored.
    -- Cleanup happens in onUpdate after the launch resolves (or safety timer).
end

-- ── Action handler ────────────────────────────────────────────────────────
input.registerActionHandler('OSSC_QuickCast', async:callback(function(pressed)
    if not pressed then return end

    local uiMode = (ui and ui.activeMode)
    if not uiMode and I.UI and I.UI.getMode then uiMode = I.UI.getMode() end

    local now = core.getSimulationTime()

    -- FIX (inconsistent button): cooldown now uses time since last RESOLUTION
    -- (lastCastAttemptTime is updated in onUpdate), not time since last press.
    -- Also shortened the cooldown window slightly.
    if uiMode ~= nil or core.isWorldPaused() or isCasting or now - lastCastAttemptTime < 0.8 then
        return
    end

    -- FIX (double-launch): reset hasFiredThisCast only here, at the confirmed
    -- start of a new cast, never inside cleanup or onUpdate.
    isCasting        = true
    hasFiredThisCast = false
    hasQueuedLaunch  = false
    pendingLaunches  = {}

    -- FIX (double-launch): increment castId to invalidate any lingering entries.
    currentCastId       = currentCastId + 1
    castStartTime       = now
    lastCastAttemptTime = now

    enableCombatBlock()


    -- FIX (inconsistent button): dedicated short abort timer. If no launch has
    -- been queued after 2 s the animation clearly never fired 'release' (missing
    -- group, bad skeleton, etc.). Abort so the button is never locked for 4 s.
    local abortCastId = currentCastId
    async:newUnsavableSimulationTimer(1.0, function()
        if isCasting and not hasFiredThisCast and currentCastId == abortCastId then
            debugLog("No launch queued after 2s — aborting")
            fullCleanup("no-launch abort")
        end
    end)

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
    local range = (activeSpell.effects and activeSpell.effects[1])
        and activeSpell.effects[1].range or core.magic.RANGE.Target

    local schoolStr = "destruction"
    if activeSpell.effects and activeSpell.effects[1] then
        local mgef = core.magic.effects.records[activeSpell.effects[1].id]
        if mgef and mgef.school then
            local S = {[0]="alteration",[1]="conjuration",[2]="destruction",
                       [3]="illusion",[4]="mysticism",[5]="restoration"}
            schoolStr = (type(mgef.school)=="string") and mgef.school:lower()
                or S[mgef.school] or "destruction"
        end
    end

    local animGroup = 'quickcast'
    -- Fix: Use existing quickcast animation for all conjuration spells
    -- qcconj and qctouch animations don't exist in the mod files
    if schoolStr == "conjuration" then
        if range == core.magic.RANGE.Self then animGroup = 'quickbuff'
        elseif range == core.magic.RANGE.Touch then animGroup = 'qctouch'
        else animGroup = 'quickcast' end
    elseif schoolStr == "alteration" then
        if range == core.magic.RANGE.Self then
            animGroup = 'qcsnap'
            ambient.playSoundFile("sound/ossc/qcsnap.mp3",
                { timeOffset=0.6, volume=0.45, loop=false })
        elseif range == core.magic.RANGE.Touch then animGroup = 'qcalts'
        else animGroup = 'qcalt' end
    elseif schoolStr == "illusion" then
        if range == core.magic.RANGE.Touch then animGroup = 'qcill'
        elseif range == core.magic.RANGE.Self then animGroup = 'qcill'
        else animGroup = 'quickcast' end
    elseif schoolStr == "mysticism" then
        if range == core.magic.RANGE.Target then animGroup = 'quickcast'
        elseif range == core.magic.RANGE.Touch then animGroup = 'qctouch'
        else animGroup = 'qcsnap' end
    else
        if range == core.magic.RANGE.Target then animGroup = 'quickcast'
        elseif range == core.magic.RANGE.Self then animGroup = 'quickbuff'
        elseif range == core.magic.RANGE.Touch then animGroup = 'qcdrain' end
    end

    local animSettings = storage.playerSection('SettingsOSSC_AnimSpeeds')
    local groupSpeedKey = {
        ['quickcast']='AnimSpeed_Quickcast', ['quickbuff']='AnimSpeed_Quickbuff',
        ['qcconj']='AnimSpeed_Qcconj',       ['qctouch']='AnimSpeed_Qctouch',
        ['qcalt']='AnimSpeed_Qcalt',         ['qcalts']='AnimSpeed_Qcalts',
        ['qcill']='AnimSpeed_Qcill',         ['qcsnap']='AnimSpeed_Qcsnap',
        ['qcdrain']='AnimSpeed_Qcdrain'
    }
    local speedKey   = groupSpeedKey[animGroup] or 'AnimSpeed_Quickcast'
    local baseSpeed  = animSettings:get(speedKey) or 1.00
    local finalSpeed = baseSpeed * (animSettings:get('AnimSpeedScale') or 1.0)

    -- FIX (wrong-group filter + fallback): set currentAnimGroup to the intended
    -- group BEFORE playing so onTextKey is ready immediately.
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

    -- FIX (fallback + wrong-group filter): if the group isn't playing after 0.1 s,
    -- switch currentAnimGroup to the fallback so onTextKey accepts its keys.
    if animGroup ~= 'quickcast' and animGroup ~= 'quickbuff' then
        local fallbackCastId = currentCastId
        async:newUnsavableSimulationTimer(0.1, function()
            if not isCasting or currentCastId ~= fallbackCastId then return end
            if not anim.isPlaying(self, animGroup) then
                local fallback = (range == core.magic.RANGE.Self) and 'quickbuff' or 'quickcast'
                debugLog("Fallback: "..animGroup.." → "..fallback)
                currentAnimGroup = fallback  -- update filter BEFORE playing
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
end))

-- ── Text key handlers ─────────────────────────────────────────────────────
if I.AnimationController then
    local groups = {
        'quickthrow','quickcast','quickbuff','qcconj','qctouch',
        'qcalt','qcalts','qcill','qcsnap','qcdrain'
    }
    for _, g in ipairs(groups) do
        I.AnimationController.addTextKeyHandler(g, onTextKey)
    end
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
        MagExp_Local_MagicHit = function(_) end
    }
}