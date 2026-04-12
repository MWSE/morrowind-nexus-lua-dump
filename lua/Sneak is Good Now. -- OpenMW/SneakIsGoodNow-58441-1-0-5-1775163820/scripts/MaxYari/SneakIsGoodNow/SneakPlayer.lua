

local mp = "scripts/MaxYari/SneakIsGoodNow/"
DebugLevel = 0

local I = require("openmw.interfaces")
local types = require("openmw.types")
local nearby = require("openmw.nearby")
local core = require("openmw.core")
local omwself = require("openmw.self")
local util = require("openmw.util")

local DEFS = require(mp .. 'utils/sneak_defs')
local gutils = require(mp .. 'utils/gutils')
local itemutil = require(mp .. "utils/item_utils")
local detection = require(mp .. "detection_math")
local aggression = require(mp .. "aggression_math")
local DetectionMarker = require(mp .. "Sneak_ui_elements")
local settings = require(mp .. 'settings').settings
local selfActor = gutils.Actor:new(omwself)

gutils.print("Sneak! E-N-G-A-G-E-D", 0)

local sneakCheckPeriod = 0.33 -- seconds between sneak checks per actor
local followTargetsCheckPeriod = 2.0 -- seconds between follow target updates per actor
local losCheckPeriod = 0.2
local detectionDecreaseRate = 0.25  -- fixed decrease rate per second

-- "ps" stands for "Player State"
local ps = {
    isSneaking = false,
    detectedByNonAggro = false,
    isMoving = false,
    isInvisible = false,
    chameleon = 0
}

local extraMods = {
    elusivenessMod = 1.0,
    elusivenessConst = 0
}

local modifiedSkill = nil
local skillMod = 0
local lastCell = nil

local nearbyCheckTimer = 0
local nearbyCheckPeriod = 0.2

local effectsCheckTimer = 0
local effectsCheckPeriod = 0.2

local observerActorStatuses = {}
local persistantActorStatuses = {}

local interface = {
    version = 1.0,
    observerActorStatuses = observerActorStatuses,
    playerState = ps,
    extraMods = extraMods
}

    
-- "ast" stands for "Actor's Status"
local function getAst(actor)
    local ast = persistantActorStatuses[actor.id]
    if not ast then
        -- gutils.print("Creating new persistant actor status for " .. actor.recordId)
        ast = {
            actor = actor,
            gactor = gutils.Actor:new(actor),
            cell = actor.cell,
            distance = 250,
            progress = 0.0,
            successRolls = 0
        }

        persistantActorStatuses[actor.id] = ast
    end
    return ast
end

local function getAstIfExists(actor)
    if not persistantActorStatuses[actor.id] then return nil end
    return getAst(actor)
end




local function getDetectionVelocity(sneakChance)
    -- returns a velocity multiplier based on sneak chance
    -- sneakChance is 0-100
    -- at 0 sneakChance, velocity is 2.0 (detected quickly)
    -- at 100 sneakChance, velocity is 0.05 (detection slows to a crawl)
    local maxDetectDur = 8
    local minDetectDur = 0.5
    if not sneakChance then
        sneakChance = 0
    end

    local detectDur = util.remap(sneakChance, 0, 100, minDetectDur, maxDetectDur)
    return 1 / detectDur
end

local function posAboveActor(actor)
    local bbox = actor:getBoundingBox()
    return bbox.center + util.vector3(0, 0, bbox.halfSize.z)
end

local function getFollowTargets(actor)
    actor:sendEvent("MaxYariUtil_GetFollowTargets")
end

local function isFriend(ast)    
    if not ast.followTargets then return false end
    if gutils.arrayContains(ast.followTargets, omwself.object) and (not ast.combatTargets or not gutils.arrayContains(ast.combatTargets, omwself.object)) then
        return true
    end
    return false
end





local function isActorKnockedOut(actor)
    for _, spell in pairs(types.Actor.activeSpells(actor)) do
        if spell.id == DEFS.KNOCKOUT_SPELL_ID then return true end
    end
    return false
end


-- Main logic starts here -----------------------------------------------
-------------------------------------------------------------------------
local function detectionLogicTick(dt)
    -- Fetching cell changes and removing actors from other cells
    local cell = omwself.cell
    if not lastCell or (lastCell ~= cell and not (lastCell.isExterior and cell.isExterior)) then
        lastCell = cell
        for id, ast in pairs(persistantActorStatuses) do
            if ast.cell ~= cell then                 
                if ast.marker then                    
                    ast.marker:destroy()
                end                
                persistantActorStatuses[id] = nil
                observerActorStatuses[id] = nil
            end
        end
    end

    -- Throttled nearby scan: new observers picked up every ~0.2s instead of every frame;
    -- existing observers in observerActorStatuses continue to be processed every frame below
    nearbyCheckTimer = nearbyCheckTimer + dt
    if ps.isSneaking and nearbyCheckTimer >= nearbyCheckPeriod then
        nearbyCheckTimer = 0
        for _, actor in ipairs(nearby.actors) do

            if actor == omwself.object then goto continue end

            local isDead = types.Actor.isDead(actor)

            -- Don't add dead actors to observers, but mark them dead if ast exists
            local ast = nil
            if isDead then
                ast = getAstIfExists(actor)
                if ast then ast.isDead = true end
                goto continue
            end

            if not ast then ast = getAst(actor) end

            local distance = (omwself.position - actor.position):length()
            ast.distance = distance
            ast.isDead = false

            -- Add to observerActorStatuses if within detection range and not a friend
            if distance <= detection.detectionRange and not ast.isFriend then
                observerActorStatuses[actor.id] = ast
            end

            ::continue::
        end
    end
    
    ps.detectedByNonAggro = false
    for actorId, ast in pairs(observerActorStatuses) do
        -- LOS check for all observer actors (regardless of detection range)
        if ast.losChecker == nil then
            ast.losChecker = gutils.cachedFunction(detection.LOS, losCheckPeriod, math.random() * losCheckPeriod)
        end

        -- Sneak check for all observers (reuses inLOS from above)
        if ast.sneakChecker == nil then
            ast.sneakChecker = gutils.cachedFunction(detection.sneakCheck, sneakCheckPeriod, math.random() * sneakCheckPeriod)
        end
        if ast.followTargetsChecker == nil then
            ast.followTargetsChecker = gutils.cachedFunction(getFollowTargets, followTargetsCheckPeriod, math.random() * followTargetsCheckPeriod)
        end

        ast.inLOS = ast.losChecker(omwself.object, ast.actor)
        local isNotDetected, newSneakChance = ast.sneakChecker(ast, ps, extraMods)
        ast.followTargetsChecker(ast.actor)

        ast.noticing = not isNotDetected
        if newSneakChance ~= nil then ast.sneakChance = newSneakChance end
        
        if ast.fightingPlayer then
            ast.isAggressive = true
        else
            ast.isAggressive = aggression.isAggressive(ast, omwself.object)
        end        

        -- Manage detection progress ----
        ---------------------------------
        local detectionVel = getDetectionVelocity(ast.sneakChance)

        if ast.progress == nil then ast.progress = 0.0 end
        if ast.successRolls == nil then ast.successRolls = 0 end

        -- Handle knocked out actors (Devilish Sleep Spell compatibility)
        if ast.isKnockedOut then
            ast.isKnockedOut = isActorKnockedOut(ast.actor)
        end

        -- Handle dead/invalid actors
        if ast.isDead or ast.isKnockedOut or not ast.actor:isValid() then
            ast.noticing = false
            ast.progress = 0.0
            ast.successRolls = 0
        elseif ast.fightingPlayer then
            ast.noticing = true
            ast.progress = 1.0
        elseif not ast.inLOS then
            -- Out of LOS: immediate fixed decrease, set successRolls to 3
            ast.progress = math.max(0.0, ast.progress - dt * detectionDecreaseRate)
            ast.successRolls = 3
        elseif ast.noticing then
            -- Detected: increase with sneak-based velocity, reset counter
            ast.progress = math.min(1.0, ast.progress + dt * detectionVel)
            ast.successRolls = 0
        else
            -- Not detected: count success rolls
            ast.successRolls = ast.successRolls + 1
            if ast.successRolls >= 3 then
                -- After 3 successes, start decreasing at fixed rate
                ast.progress = math.max(0.0, ast.progress - dt * detectionDecreaseRate)
            end
            -- else: progress stays same
        end

        -- Send spotted event and break sneak only when detection progress reaches 1.0
        if ast.progress >= 1.0 then
            if ast.isAggressive then
                omwself.controls.sneak = false  -- Break sneak when fully detected 
            else
                ps.detectedByNonAggro = true
            end
        end

        -- Manage ui markers ------------------
        ---------------------------------------
        -- Show markers only when sneaking and detection progress is happening
        local shouldShowMarker = ps.isSneaking and not ast.isDead and not ast.isKnockedOut and ast.inLOS
        if shouldShowMarker then
            -- If marker doesnt exist but should - make it
            if not ast.marker then ast.marker = DetectionMarker:new() end
        elseif ast.marker then
            -- If it shouldnt exist but does - remove it
            local isSuccesful = ast.progress >= 1.0
            ast.marker:disappear(isSuccesful)
        end

        if ast.marker and ast.marker.destroyed then
            ast.marker = nil
        end

        if ast.marker then
            -- Update the marker's progress and position
            ast.marker:setProgress(ast.progress)
            ast.marker:setWorldPos(posAboveActor(ast.actor))
            ast.marker:setAggressive(ast.isAggressive)
        end

        -- Update tweeners here to avoid a second full pass over observerActorStatuses in onUpdate
        if ast.marker then ast.marker:updateTweeners(dt) end

        -- Final cleanup, if no marker and no progress - remove the status object --
        ----------------------------------------------------------------------------
        if (ast.marker == nil) and (ast.progress <= 0.0) then
            observerActorStatuses[actorId] = nil
        end

        ::continue::
    end
end


local function onUpdate(dt)
    if dt == 0 then
        return
    end   

    -- Fetching locomotion statuses
    ps.isMoving = selfActor:getCurrentSpeed() > 0 or not selfActor:isOnGround()
    ps.isSneaking = omwself.controls.sneak

    -- Fetching invisibility and chameleon status (throttled, effects change infrequently)
    effectsCheckTimer = effectsCheckTimer + dt
    if effectsCheckTimer >= effectsCheckPeriod then
        effectsCheckTimer = 0
        local activeEffects = selfActor:activeEffects()
        local invisibilityEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Invisibility)
        ps.isInvisible = (invisibilityEffect ~= nil) and (invisibilityEffect.magnitude > 0)
        local chameleonEffect = activeEffects:getEffect(core.magic.EFFECT_TYPE.Chameleon)
        ps.chameleon = chameleonEffect and chameleonEffect.magnitude or 0
    end

    detectionLogicTick(dt)

    -- Weapon skill modifier: only runs while sneaking or when cleaning up a leftover modifier
    if ps.isSneaking or modifiedSkill then
        local weaponObj = selfActor:getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedRight)
        local skill = "handtohand"
        if weaponObj and types.Weapon.objectIsInstance(weaponObj) then
            skill = itemutil.getSkillTypeForEquipment(weaponObj).id
        end
        local stat = selfActor:getSkillStat(skill)

        if ps.isSneaking then
            if modifiedSkill ~= skill then
                -- if we switched to a different skill, remove old modifier
                if modifiedSkill then
                    local oldStat = selfActor:getSkillStat(modifiedSkill)
                    oldStat.modifier = oldStat.modifier - skillMod
                end

                skillMod = stat.base * settings.WeaponBonus
                modifiedSkill = skill
                stat.modifier = stat.modifier + skillMod
            end
        else
            if modifiedSkill then
                -- remove modifier when not sneaking; use modifiedSkill's stat, not current weapon's,
                -- in case the player unequipped their weapon on the same frame they stopped sneaking
                local oldStat = selfActor:getSkillStat(modifiedSkill)
                oldStat.modifier = oldStat.modifier - skillMod
                modifiedSkill = nil
                skillMod = 0
            end
        end
    end
end





-- Event handlers ----------------------------------------------
----------------------------------------------------------------
local function onCombatTargetsChanged(e)
    
    if e.actor == omwself.object then return end
    -- print("Combat targets changed for " .. e.actor.recordId)

    local ast = getAst(e.actor)    
    ast.combatTargets = e.targets    
    ast.isFriend = isFriend(ast)
    ast.isDead = types.Actor.isDead(e.actor) 

    if not ast.isDead and gutils.arrayContains(ast.combatTargets, omwself.object) then
        gutils.print("Player: Combat targets changed for " .. e.actor.recordId, "Player is a target", 1)
        ast.fightingPlayer = true       
        ast.isAggressive = true 
        observerActorStatuses[e.actor.id] = ast
    else
        ast.fightingPlayer = false
    end
end

local function onGetFollowTargets(e)
    -- gutils.print("Player: Received follow targets resp from " .. e.actor.recordId, 1)    
    if e.actor == omwself.object then return end

    local ast = getAst(e.actor)
    ast.followTargets = e.targets
    ast.isFriend = isFriend(ast)
    -- gutils.print(e.actor.recordId, "Is a friend",ast.isFriend, 1)
end

local function onReportAttack(e)
    if e.target == omwself.object then return end

    -- gutils.print("Reported attack by " .. e.attacker.recordId .. " on " .. e.target.recordId)
    local ast = getAst(e.target)
    ast.isFriend = isFriend(ast)
    ast.isDead = types.Actor.isDead(e.target) 

    if e.attacker == omwself.object and not ast.isDead then
        ast.fightingPlayer = true
        ast.isAggressive = true
        ast.isKnockedOut = isActorKnockedOut(e.target)
        observerActorStatuses[e.target.id] = ast
    end
end

local function onSave()
    return {
        modifiedSkill = modifiedSkill,
        skillMod = skillMod
    }
end

local function onLoad(data)
    if data.modifiedSkill then
        modifiedSkill = data.modifiedSkill
        skillMod = data.skillMod
    end
end

return {    
    engineHandlers = {
        onUpdate = onUpdate,
        onSave = onSave,
        onLoad = onLoad
    },
    eventHandlers = { 
        OMWMusicCombatTargetsChanged = onCombatTargetsChanged,
        MaxYariUtil_FollowTargets = onGetFollowTargets,
        [DEFS.e.ReportAttack] = onReportAttack
    },
    interfaceName = DEFS.mod_name,
    interface = interface
}