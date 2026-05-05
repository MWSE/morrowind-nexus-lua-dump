-- ============================================================
-- DisarmTrap - Global Script (v2.3 - Authoritative 5s Restorer)
-- ============================================================

local core   = require('openmw.core')
local world  = require('openmw.world')
local types  = require('openmw.types')
local util   = require('openmw.util')
local I      = require('openmw.interfaces')
local async  = require('openmw.async')
local debugMode = false
local trapMultiplier = 1.4

local EFFECT_DISARM = 'disarmtrap'
local EFFECT_ABSORB = 'absorbtrap'
local EFFECT_DETECT = 'detecttrap'
local EFFECT_DETECT_ALT = 'detecttrap_alt'

-- Sounds
local SOUND_ALTERATION_HIT = "alteration hit"
local SOUND_MYSTICISM_HIT  = "mysticism hit"
local SOUND_DISARM         = "Disarm Trap"

-- ============================================================
-- Helper: Checks if an individual object is trapped and disarms it.
-- ============================================================
local function getTrapInfo(obj)
    if not obj or not obj:isValid() then return nil end
    local isLockable = (obj.type == types.Door or obj.type == types.Container)
    if not isLockable then return nil end

    local trap = nil
    local L = types.Lockable or types.LOCKABLE
    
    pcall(function() trap = L.getTrapSpell(obj) end)
    
    if not trap or (type(trap) == "string" and trap == "") then 
        pcall(function()
            local rec = obj.type.record(obj)
            if rec and rec.trap and rec.trap ~= "" then trap = rec.trap end
        end)
    end

    if trap and (trap ~= "" or type(trap) ~= "string") then
        local trapId = tostring(trap.id or trap)
        local trapSpell = core.magic.spells.records[trapId]
        local trapCost = trapSpell and trapSpell.cost or 0
        local trapName = trapSpell and trapSpell.name or "Unknown Trap"
        return { 
            id = trapId, 
            cost = trapCost, 
            name = trapName, 
            clear = function() pcall(function() L.setTrapSpell(obj, nil) end) end 
        }
    end
    return nil
end

-- ============================================================
-- Main Handler
-- ============================================================
local function processEffect(info, mode)
    local hitPos = info.hitPos or (info.attacker and info.attacker.position) or util.vector3(0,0,0)
    local attacker = info.attacker
    local area = info.area or 0
    
    local scanRadius = 150 
    if area > 0 then
        scanRadius = area * 24
    end

    local spellMagnitude = 0
    local spellRec = core.magic.spells.records[info.spellId] or core.magic.enchantments.records[info.spellId]
    if spellRec then
        for _, eff in ipairs(spellRec.effects) do
            if eff.id == EFFECT_DISARM or eff.id == EFFECT_ABSORB or eff.id == EFFECT_DETECT then
                spellMagnitude = (eff.magnitudeMin + eff.magnitudeMax) / 2
                break
            end
        end
    end

    local foundObjects = {}

    if info.target then
        local tInfo = getTrapInfo(info.target)
        if tInfo then table.insert(foundObjects, { obj = info.target, trapInfo = tInfo }) end
    end

    if #foundObjects == 0 or area > 0 then
        local cellsToScan = {}
        if attacker and attacker:isValid() then table.insert(cellsToScan, attacker.cell) end
        if info.target and info.target:isValid() and info.target.cell ~= attacker.cell then 
            table.insert(cellsToScan, info.target.cell) 
        end

        for _, cell in ipairs(cellsToScan) do
            for _, obj in ipairs(cell:getAll(types.Container)) do
                if (obj.position - hitPos):length() <= scanRadius then
                    if not info.target or obj.id ~= info.target.id then
                        local tInfo = getTrapInfo(obj)
                        if tInfo then table.insert(foundObjects, { obj = obj, trapInfo = tInfo }) end
                    end
                end
            end
            for _, door in ipairs(cell:getAll(types.Door)) do
                if (door.position - hitPos):length() <= scanRadius then
                    if not info.target or door.id ~= info.target.id then
                        local tInfo = getTrapInfo(door)
                        if tInfo then table.insert(foundObjects, { obj = door, trapInfo = tInfo }) end
                    end
                end
            end
        end
    end

    local count = #foundObjects
    if count > 0 then
        for _, entry in ipairs(foundObjects) do
            local obj = entry.obj
            local tInfo = entry.trapInfo
            
            if mode == 'detect' or mode == 'detect_alt' then
                if attacker and attacker:isValid() then
                    if mode == 'detect' then
                        attacker:sendEvent('DetectTrap_Result', {
                            name = tInfo.name,
                            cost = math.floor(tInfo.cost * trapMultiplier)
                        })
                    else
                        attacker:sendEvent('DetectTrapAlt_Result', {
                            cost = math.floor(tInfo.cost * trapMultiplier)
                        })
                    end
                end
                
            elseif mode == 'disarm' or mode == 'absorb' then
                local tooComplex = ((tInfo.cost * trapMultiplier) > spellMagnitude)
                local success = (spellMagnitude > (tInfo.cost * trapMultiplier))
                
                if success then
                    tInfo.clear()
                    
                    if mode == 'absorb' and attacker and attacker:isValid() then
                        local magickaAmount = tInfo.cost + 15
                        pcall(function() 
                            I.MagExp.launchSpell({
                                attacker  = attacker,
                                spellId   = 'disarmtrap_abs_magicka',
                                startPos  = attacker.position,
                                direction = util.vector3(0,0,1),
                                isFree    = true,
                                spellType = core.magic.RANGE.Self
                            })
                            attacker:sendEvent('StartRestoration', { stat = 'magicka', amount = magickaAmount })
                            
                            local bSnd  = SOUND_MYSTICISM_HIT
                            local bSnd2 = "mysticism_hit"
                            if not core.sound.playSound3d(bSnd, attacker) then core.sound.playSound3d(bSnd2, attacker) end
                            core.sound.playSound3d(SOUND_DISARM, attacker)
                        end)
                        attacker:sendEvent('DisarmTrap_Result', { mode = 'absorb', success = true, amount = magickaAmount })
                    elseif mode == 'disarm' and attacker and attacker:isValid() then
                        core.sound.playSound3d(SOUND_DISARM, attacker)
                        attacker:sendEvent('DisarmTrap_Result', { mode = 'disarm', success = true })
                    end
                else
                    if mode == 'absorb' then
                        tInfo.clear()
                        if attacker and attacker:isValid() then
                            I.MagExp.applySpellToActor(tInfo.id, attacker, attacker)
                            attacker:sendEvent('DisarmTrap_Result', { mode = 'absorb', success = false })
                        end
                    elseif mode == 'disarm' then
                        if attacker and attacker:isValid() then
                            attacker:sendEvent('DisarmTrap_Result', { mode = 'disarm', success = false, tooComplex = tooComplex })
                        end
                    end
                end
            end

            -- [HIT VFX/Sound] Robust spawn logic for World Objects (Doors/Containers)
            if obj and obj:isValid() then
                local mRec = isAbsorb and core.magic.effects.records['absorbhealth'] or core.magic.effects.records['open']
                local rid  = mRec and mRec.hitArea or (isAbsorb and "VFX_MysticismArea" or "VFX_MysticismArea")
                local rid2 = isAbsorb and "VFX_MysticismArea" or "VFX_MysticismArea"
                local vRec = types.Static.records[rid] or types.Weapon.records[rid] or types.Static.records[rid2] or types.Weapon.records[rid2]
                local modelPath = vRec and vRec.model
                    if not modelPath or modelPath == "" then
                        modelPath = isAbsorb and "meshes/e/magic_hit_myst.nif" or "meshes/e/magic_hit_alt.nif"
                    end

                    if modelPath then
                        -- Center & Base Spawn 
                        local box = obj:getBoundingBox()
                        local spawnCenter = box.center --+ util.vector3(0, 0, 0) -- here you can modify the VFX position, first 0 is X, second 0 is Y, third 0 is Z (X = forward/backward from player perspective)
                        
                        world.vfx.spawn(modelPath, spawnCenter, { mwMagicVfx = true, scale = 1.25 })
                    end
                local snd  = isAbsorb and SOUND_MYSTICISM_HIT or SOUND_ALTERATION_HIT
                local snd2 = isAbsorb and "mysticism_hit" or "alteration_hit"
                if not core.sound.playSound3d(snd, obj) then
                    core.sound.playSound3d(snd2, obj)
                end
            end
        end
    else
        -- if attacker and attacker:isValid() then
        --    attacker:sendEvent('DisarmTrap_Result', { count = 0, mode = mode })
        -- end
    end
end

local function onMagicHit(info)
    if not info or not info.spellId then return end
    local spell = core.magic.spells.records[info.spellId] or core.magic.enchantments.records[info.spellId]
    if not spell then return end
    for _, eff in ipairs(spell.effects) do
        if eff.id == EFFECT_DISARM then
            processEffect(info, 'disarm')
            return
        elseif eff.id == EFFECT_ABSORB then
            processEffect(info, 'absorb')
            return
        elseif eff.id == EFFECT_DETECT then
            processEffect(info, 'detect')
            return
        elseif eff.id == EFFECT_DETECT_ALT then
            processEffect(info, 'detect_alt')
            return
        end
    end
end

-- Helper: checks if an actor already has a specific spell (case-insensitive)
local function hasSpell(actor, spellId)
    spellId = spellId:lower()
    local mySpells = types.Actor.spells(actor)
    for i = 1, #mySpells do
        if mySpells[i].id:lower() == spellId then
            return true
        end
    end
    return false
end

local injected_npcs = {}

return {
    engineHandlers = {
        onSave = function()
            return { injected_npcs = injected_npcs }
        end,
        onLoad = function(data)
            if data and data.injected_npcs then
                injected_npcs = data.injected_npcs
            end
        end,
        onActorActive = function(actor)
            -- Step 1: NPC check
            if not types.NPC.objectIsInstance(actor) then return end
            
            -- Versioning check
            if not actor.id or injected_npcs[actor.id] then return end

            -- Step 2: Read skills
            local alteration = types.NPC.stats.skills.alteration(actor).base
            local mysticism  = types.NPC.stats.skills.mysticism(actor).base

            if debugMode then
                print(string.format("[TrapHandling] Checking %s - Alt: %d, Myst: %d", actor.recordId, alteration, mysticism))
            end

            local changed = false
            
            -- Step 3: Check Alteration threshold (Disarm Trap & Detect Trap Alt)
            if alteration > 40 then
                if not hasSpell(actor, "disarmtrap_spell") then
                    types.Actor.spells(actor):add("disarmtrap_spell")
                    if debugMode then print("[AlterationSpell] SUCCESS added disarmtrap_spell to: " .. actor.recordId) end
                    changed = true
                else
                    if debugMode then print("[AlterationSpell] Already has spell: " .. actor.recordId) end
                end

                if not hasSpell(actor, "detecttrap_alt_spell") then
                    types.Actor.spells(actor):add("detecttrap_alt_spell")
                    if debugMode then print("[AlterationSpell] SUCCESS added detecttrap_alt_spell to: " .. actor.recordId) end
                    changed = true
                else
                    if debugMode then print("[AlterationSpell] Already has spell: " .. actor.recordId) end
                end
            end
            
            -- Step 4: Check Mysticism threshold (Absorb Trap & Detect Trap)
            if mysticism > 40 then
                if not hasSpell(actor, "absorbtrap_spell") then
                    types.Actor.spells(actor):add("absorbtrap_spell")
                    if debugMode then print("[MysticismSpell] SUCCESS added absorbtrap_spell to: " .. actor.recordId) end
                    changed = true
                else
                    if debugMode then print("[MysticismSpell] Already has spell: " .. actor.recordId) end
                end

                if not hasSpell(actor, "detecttrap_spell") then
                    types.Actor.spells(actor):add("detecttrap_spell")
                    if debugMode then print("[MysticismSpell] SUCCESS added detecttrap_spell to: " .. actor.recordId) end
                    changed = true
                else
                    if debugMode then print("[MysticismSpell] Already has spell: " .. actor.recordId) end
                end
            end
            
            
            -- Mark as checked regardless of success to avoid log spam/redundant checks
            injected_npcs[actor.id] = true
        end
    },
    eventHandlers  = {
        MagExp_OnMagicHit = onMagicHit,
        DisarmTrap_UpdateSettings = function(data)
            if data then 
                debugMode = data.debugMode 
                trapMultiplier = data.trapMultiplier or 1.4
            end
        end
    }
}
