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

local function debugLog(msg)
    local debugOn = storage.playerSection('SettingsOSSC_General'):get('DebugMode')
    if debugOn then
        print("[OSSC] " .. tostring(msg))
    end
end






local isCasting    = false
local hasQueuedLaunch = false
local currentSpell = nil
local pendingLaunches = {}

local OSSC_PowerCooldowns = {}

local function getSpeed(spell)
    local settings = storage.playerSection('SettingsOSSC_Speeds')
    local firstEff = (spell.effects and spell.effects[1])
    if not firstEff then return 1500 end

    local id = firstEff.id:lower()
    local mgefRec = core.magic.effects.records[firstEff.id]
    local school = mgefRec and tostring(mgefRec.school):lower() or ""

    local key = "SpeedDefault"

    -- Effect-ID-based matches (most reliable, covers Destruction sub-types)
    if id:find("fire") then
        key = "SpeedFire"
    elseif id:find("frost") or id:find("cold") then
        key = "SpeedFrost"
    elseif id:find("shock") or id:find("lightn") then
        key = "SpeedShock"
    elseif id:find("poison") then
        key = "SpeedPoison"
    elseif id:find("restor") or id:find("heal") then
        key = "SpeedHeal"
    -- School-string matches (mgefRec.school is always a lowercase string in OpenMW Lua)
    elseif school == "illusion" then
        key = "SpeedIllusion"
    elseif school == "alteration" then
        key = "SpeedAlteration"
    elseif school == "conjuration" then
        key = "SpeedConjuration"
    elseif school == "mysticism" then
        key = "SpeedMysticism"
    elseif school == "restoration" then
        key = "SpeedHeal"
    elseif school == "destruction" then
        key = "SpeedFire"   -- generic destruction fallback
    end

    local spd = settings:get(key)
    return tonumber(spd) or 1500
end



local INCAPACITATED_GROUPS = {
    "knockdown", "knockout", "swimknockout", "swimknockdown"
}

local function getSpellElementType(spell)
    if not spell or not spell.effects then return 'default' end
    for _, eff in ipairs(spell.effects) do
        local mgef = core.magic.effects.records[eff.id]
        if mgef then
            local name = mgef.name:lower()
            if string.find(name, "fire")           then return "fire"   end
            if string.find(name, "frost")          then return "frost"  end
            if string.find(name, "shock")          then return "shock"  end
            if string.find(name, "poison")         then return "poison" end
            if string.find(name, "restore health")
            or string.find(name, "heal")           then return "heal"   end
        end
    end
    return 'default'
end

local function getCastChance(spell, caster)
    if spell.type == core.magic.SPELL_TYPE.Power then return 100 end
    if not spell.effects or #spell.effects == 0 then return 100 end
    local magicEffectRecord = core.magic.effects.records[spell.effects[1].id]
    local schoolId = magicEffectRecord.school

    local skillVal = 0
    if schoolId then
        local sk = types.NPC.stats.skills[schoolId]
        if sk then skillVal = sk(caster).modified end
    end

    local willpower    = types.Actor.stats.attributes.willpower(caster).modified
    local luck         = types.Actor.stats.attributes.luck(caster).modified
    local cost         = spell.cost or 0
    local fatigue      = types.Actor.stats.dynamic.fatigue(caster)
    local fatigueRatio = 1
    if fatigue.base > 0 then
        fatigueRatio = fatigue.current / fatigue.base
    end

    local chance = (skillVal * 2 + willpower / 5 + luck / 10 - cost) * (0.75 + 0.5 * fatigueRatio)
    if chance < 0   then chance = 0   end
    if chance > 100 then chance = 100 end
    return chance
end

local function onUpdate(dt)
    if #pendingLaunches > 0 then

        local currentTime = core.getSimulationTime()
        for i = #pendingLaunches, 1, -1 do
            local pl = pendingLaunches[i]
            
            if currentTime >= pl.timeToFire then
                local spell = pl.spell
                if spell then
                    local chance = getCastChance(spell, self)
                    local roll   = math.random(1, 100)
                    local cost   = spell.cost or 0
                    local godMode = debug.isGodMode()
                    
                    if godMode then 
                        cost = 0 
                        chance = 100
                    end
                    
                    local magicka = types.Actor.stats.dynamic.magicka(self)
                    
                    if magicka.current < cost then
                        ui.showMessage("Not enough Magicka.")
                        core.sound.playSound3d("spell failure restoration", self)
                    else
                        magicka.current = magicka.current - cost
                        
                        -- [FATIGUE USE] MCP Formula: FatigueCost(Spell) = MagickaCost * (fFatigueSpellBase + fFatigueSpellMult * EncPercent)
                        local useFatigue = storage.playerSection('SettingsOSSC_General'):get('UseFatigue')
                        if not godMode and useFatigue and spell.cost and spell.cost > 0 then
                            pcall(function()
                                local fFatigueSpellBase = core.getGMST("fFatigueSpellBase")
                                local fFatigueSpellMult = core.getGMST("fFatigueSpellMult")
                                
                                local currentEnc = types.Actor.getEncumbrance(self)
                                local maxEnc = types.Actor.getCapacity(self)
                                local encPercent = (maxEnc and maxEnc > 0) and (currentEnc / maxEnc) or 0
                                
                                local fatigueCost = spell.cost * (fFatigueSpellBase + fFatigueSpellMult * encPercent)
                                local stats = types.Actor.stats.dynamic.fatigue(self)
                                local newF = stats.current - fatigueCost
                                if newF < 0 then newF = 0 end
                                stats.current = newF
                            end)
                        end

                        print("OSSC: Casting " .. spell.id .. " (Chance: " .. chance .. " Roll: " .. roll .. ")")

                        if roll <= chance then
                            local pitch = -(camera.getPitch() + camera.getExtraPitch())
                            local yaw   =   camera.getYaw()   + camera.getExtraYaw()
                            local direction, startPos

                            if camera.getMode() == camera.MODE.FirstPerson then
                                local xzLen = math.cos(pitch)
                                direction   = util.vector3(xzLen * math.sin(yaw), xzLen * math.cos(yaw), math.sin(pitch))
                                local forwardDir = util.vector3(direction.x, direction.y, 0):normalize()
                                local rightDir   = util.vector3(forwardDir.y, -forwardDir.x, 0)
                                startPos    = camera.getPosition() - util.vector3(0, 0, 10) - (rightDir * 55)
                            else
                                -- Default to Third Person logic for all other modes (Vanity, Preview, etc.)
                                local bodyDir    = self.rotation * util.vector3(0, 1, 0)
                                local bodyYaw    = math.atan2(bodyDir.x, bodyDir.y)
                                local xzLen      = math.cos(pitch)
                                direction        = util.vector3(xzLen * math.sin(bodyYaw), xzLen * math.cos(bodyYaw), math.sin(pitch))
                                local forwardDir = util.vector3(direction.x, direction.y, 0):normalize()
                                local rightDir   = util.vector3(forwardDir.y, -forwardDir.x, 0)
                                startPos         = self.position + util.vector3(0, 0, 110) + (forwardDir * 15) - (rightDir * 50)
                            end

                            core.sendGlobalEvent('MagExp_CastRequest', {
                                attacker    = self,
                                spellId     = spell.id,
                                startPos    = startPos,
                                direction   = direction,
                                isFree      = true,
                                speed       = getSpeed(spell)
                            })

                            -- [SKILL PROGRESS] Reward XP for successful cast
                            if spell.effects and spell.effects[1] then
                                local mgef = core.magic.effects.records[spell.effects[1].id]
                                if mgef and mgef.school then
                                    local skill = types.NPC.stats.skills[mgef.school]
                                    if skill then
                                        local xpGain = storage.playerSection('SettingsOSSC_General'):get('SkillExperience')
                                        I.SkillProgression.skillUsed(mgef.school, { skillGain = xpGain })
                                    end
                                end
                            end
                        else
                             ui.showMessage("Your spell failed to cast.")
                             core.sound.playSound3d("spell failure illusion", self)
                        end
                    end
                end
                table.remove(pendingLaunches, i)
            end
        end
    end

    if isCasting
    and not anim.isPlaying(self, 'quickthrow')
    and not anim.isPlaying(self, 'quickbuff')
    and not anim.isPlaying(self, 'spellcast') then
        isCasting = false
        if I.Controls then I.Controls.overrideCombatControls(false) end
    end
end

local function onTextKey(groupname, key)
    if not isCasting then return end

    local lowerKey = key:lower()
    debugLog("Text Key Fired -> group=" .. tostring(groupname) .. "  key=" .. tostring(key))

    -- [START] Wind-up sound
    if string.find(lowerKey, 'start') then
        if hasQueuedLaunch then return end
        hasQueuedLaunch = true
        
        local spell = currentSpell
        if spell and spell.effects and spell.effects[1] then
            local mgef = core.magic.effects.records[spell.effects[1].id]
            if mgef then
                local sStr = "destruction"
                local school = mgef.school
                local SCHOOL = core.magic.SCHOOL or { Alteration=0, Conjuration=1, Destruction=2, Illusion=3, Mysticism=4, Restoration=5 }
                
                if type(school) == "string" then
                    sStr = school:lower()
                else
                    if school == SCHOOL.Restoration then sStr = "restoration"
                    elseif school == SCHOOL.Illusion then sStr = "illusion"
                    elseif school == SCHOOL.Conjuration then sStr = "conjuration"
                    elseif school == SCHOOL.Alteration then sStr = "alteration"
                    elseif school == SCHOOL.Mysticism then sStr = "mysticism" end
                end
                
                local sndId = sStr .. " cast"
                if mgef.castSound and mgef.castSound ~= "" then
                    sndId = mgef.castSound
                end
                
                debugLog("Windup Sound evaluating to: " .. tostring(sndId))
                pcall(function() core.sound.playSound3d(sndId, self, { volume = 1.0 }) end)
                
                local delay = 0.62 -- targetted spells casting/inflicting timer
                if spell.effects and spell.effects[1] then
                    local r = spell.effects[1].range
                    if r == core.magic.RANGE.Self then
                        delay = 1.00 -- self spells casting/inflicting timer
                    elseif r == core.magic.RANGE.Touch then
                        delay = 0.62 -- touch spells casting/inflicting timer
                    end
                end

                -- [GLOBAL EXECUTION] Delayed casting based on spell range
                table.insert(pendingLaunches, {
                    spell      = spell,
                    timeToFire = core.getSimulationTime() + delay
                })

            end
        end

    elseif string.find(lowerKey, 'stop') then
        isCasting = false
        if I.Controls then I.Controls.overrideCombatControls(false) end
    end
end

input.registerActionHandler('OSSC_QuickCast', async:callback(function(pressed)
    if not pressed then return end
    if isCasting then return end

    debugLog("Quick Cast Action Triggered")

    for _, groupName in ipairs(INCAPACITATED_GROUPS) do
        if anim.isPlaying(self, groupName) then return end
    end

    local activeSpell = types.Actor.getSelectedSpell(self)
    if activeSpell then
        local spellRec = core.magic.spells.records[activeSpell.id]
        if spellRec and spellRec.type == core.magic.SPELL_TYPE.Power then
            ui.showMessage("You need bigger focus to cast powers. Use spell stance.")
            return
        end

        currentSpell    = activeSpell
        isCasting       = true
        hasQueuedLaunch = false

        if I.Controls then I.Controls.overrideCombatControls(true) end
        core.sendGlobalEvent('MagExp_BreakInvisibility', { actor = self })

        local range = (activeSpell.effects and activeSpell.effects[1]) and activeSpell.effects[1].range or core.magic.RANGE.Target
        local animGroup = (range == core.magic.RANGE.Self) and 'quickbuff' or 'quickthrow'

        if animGroup == 'quickbuff' then
            I.AnimationController.playBlendedAnimation(animGroup, {
                priority = anim.PRIORITY.Scripted + 100,
                startkey = 'start',
                stopkey  = 'stop',
                speed    = 1.5,
            })
        else
            I.AnimationController.playBlendedAnimation(animGroup, {
                priority = anim.PRIORITY.Scripted + 100,
                startkey = 'start',
                stopkey  = 'stop',
                speed    = 0.65,
            })
            anim.setSpeed(self, animGroup, 0.55)
            async:newUnsavableSimulationTimer(0.65, function()
                if isCasting and anim.isPlaying(self, animGroup) then
                    pcall(function() anim.setSpeed(self, animGroup, 0.85) end)
                end
            end)
        end
    end
end))


if I.AnimationController then
    I.AnimationController.addTextKeyHandler('quickthrow', onTextKey)
    I.AnimationController.addTextKeyHandler('quickbuff',  onTextKey)
else
    print("OSSC: AnimationController interface not available.")
end

debugLog("--- OSSC PLAYER SCRIPT INITIALIZED SUCCESSFULLY ---")


local function onSave()
    return {
        powerCooldowns = OSSC_PowerCooldowns,
    }
end

local function onLoad(data)
    if data and data.powerCooldowns then
        OSSC_PowerCooldowns = data.powerCooldowns
    end
end

return {
    engineHandlers = {
        onUpdate      = onUpdate,
        onSave        = onSave,
        onLoad        = onLoad,
    }
}