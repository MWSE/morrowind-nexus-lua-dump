local mp = "scripts/MaxYari/ReAnimation_v2/"

local omwself = require('openmw.self')
local types = require('openmw.types')
local core = require("openmw.core")

local animation = require('openmw.animation')
local I = require('openmw.interfaces')
local animManager = require(mp .. "scripts/anim_manager")
local gutils = require(mp .. "scripts/gutils")
local EventsManager = require(mp .. "scripts/events_manager")

DebugLevel = 0

local animations = {}
local trackedAnims = {}
local trackedAnims_n = 0

local attackCounters = {}
local stance = nil

local frame_n = 0

local state_check_frame_n = 0
local state = {
    stance = nil,
    armatureType = nil,
    onStateChange = EventsManager:new()
}

--- Helper methods ----------------------
-----------------------------------------
local function isProperArmatureType(anim)
    if anim.armatureType == gutils.ARMATURE_TYPE.Any then return true end
    return anim.armatureType == state.armatureType
end

local function isProperStance(anim)
    if anim.stance == gutils.STANCE.Any then return true end
    return anim.stance == state.stance
end

local function addToTrackedAnimsList(anim)  
    if anim.alwaysTracked then return end -- alwaysTracked anims are managed by rebuildTrackedAnimsList  
    table.insert(trackedAnims, anim)
    trackedAnims_n = trackedAnims_n + 1
end

local function removeFromTrackedAnimsList(i)
    local anim = trackedAnims[i]    
    if anim.alwaysTracked then return end -- alwaysTracked anims are managed by rebuildTrackedAnimsList 
    table.remove(trackedAnims, i)
    trackedAnims_n = trackedAnims_n - 1
end

local function rebuildTrackedAnimsList()
    local newTrackedAnims = {}    
    for _, anims in pairs(animations) do
        for _, anim in ipairs(anims) do
            anim.alwaysTracked = false
            if anim.running then
                table.insert(newTrackedAnims, anim)                
            elseif anim.startOnUpdate and isProperArmatureType(anim) and isProperStance(anim) then
                anim.alwaysTracked = true
                table.insert(newTrackedAnims, anim) 
            end           
        end
    end
    trackedAnims = newTrackedAnims
    trackedAnims_n = #trackedAnims
end


local function checkActorStates()
    if state_check_frame_n == frame_n then return end
    
    local stance = types.Actor.getStance(omwself)
    local armature_type = gutils.getArmatureType()

    if stance ~= state.stance or armature_type ~= state.armatureType then
        state.stance = stance
        state.armatureType = armature_type
        state.onStateChange:emit(state)
        rebuildTrackedAnimsList()
    end

    state_check_frame_n = frame_n
end

local function addToAnimMap(anim)
    local key = anim.parent or "-"    
    local anims = animations[key]
    if not anims then
        anims = {}
        animations[key] = anims
    end
    -- print("Registering animation override with id for parent " .. key)
    table.insert(anims, anim)
end


--- API Functions -----------------------
--- -------------------------------------
--- It is expected that an override has either a parent anim group assigned or startOnUpdate: true. Otherwise override will never start.
local function addAnimationOverride(anim)
    -- print("registering animation"  .. anim.groupname)
    if not anim.stance then anim.stance = gutils.STANCE.Weapon end -- Default value for backwards compatibility
    if anim.enabled == nil then anim.enabled = true end -- Default value for backwards compatibility
    
    if type(anim.parent) == "table" then
        for _, parent in ipairs(anim.parent) do
            local newAnimation = gutils.shallowTableCopy(anim)
            newAnimation.parent = parent
            addToAnimMap(newAnimation)            
        end
    else
        addToAnimMap(anim)        
    end
end

local function removeAnimationOverride(id)
    if not id then return end    
    for key, anims in pairs(animations) do
        for i, anim in ipairs(anims) do
            if anim.id == id then
                table.remove(anims, i)
                return true
            end
        end
    end
    return false
end


--[[ 
params example:
{
    parentGroupname = "weapononehand",
    overrideGroupname = "weapononehand1",
    armatureType = I.ReAnimation.ARMATURE_TYPE.ThirdPerson,
} 
]]

-- This will result in parentAttackGroupname and altAttackGroupname being used one after another.
-- altAttackGroupname textkey timings should match parent textkey timings exactly.
local function addAltAttackAnimations(params)
    if not params.parentAttackGroupname or not params.altAttackGroupname then
        error("addAltAttackAnimation(): parentAttackGroupname or altAttackGroupname were not found in params object.")
        return
    end
    
    local override = {
        id = "AltAttack",
        parent = params.parentAttackGroupname,
        groupname = params.altAttackGroupname,
        armatureType = params.armatureType,
        enabled = true,
        preOverride = function(self, pOptions)
            local startKey = pOptions.startkey or pOptions.startKey
            local stopKey = pOptions.stopkey or pOptions.stopKey
            
            -- Alternate attacks
            if gutils.isAttackTypeStart(startKey) then
                
                local key = self.parent .. gutils.isAttackType(startKey)
                if not attackCounters[key] then attackCounters[key] = -1 end
                attackCounters[key] = (attackCounters[key] + 1) % 2

                if attackCounters[key] == 1 then
                    self.enabled = true
                else
                    self.enabled = false
                end
            end
        end,
        condition = function(self)  
            local startKey = self.parentOptions.startkey or self.parentOptions.startKey
            if startKey == nil then return false end -- A User reported an error there, with startKey being nil. No idea why, but heres a crappy fix anyway.
            return gutils.isAttackType(startKey)
        end,
        options = function(self, pOptions)
            local opts = gutils.cloneAnimOptions(pOptions)

            -- Since the engine never runs 2 animations with exact same priorities - it's important to make parent animation priority unique to ensure that it will remain running in the background.
            -- Running original animations in the background is important to keep internal engine's character controller satisfied.
            gutils.uniquifyPriority(pOptions)

            pOptions.blendMask = 0
            pOptions.blendmask = 0
            
            return opts
        end,
        startOnAnimEvent = true
    }
    addAnimationOverride(override)    
end



--- Core Override handling--------------------------
--- ------------------------------------------------

I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    if not next(animations) then return end

    -- This will update actor's stance, armature type and rebuild a list of animations that should be tracked
    checkActorStates()

    -- print("Animation started", groupname, startKey, stopKey)
    -- Update stance and armature statuses here! If they changed - run onActorStateChanged

    local anims = animations[groupname]
    if not anims then return end  

    local startKey = options.startkey or options.startKey
    local stopKey = options.stopkey or options.stopKey

    -- print("Found " .. #anims .. " override(s) for " .. groupname)

    -- Starting override anims
    for _, anim in ipairs(anims) do  
        anim.parentOptions = gutils.cloneAnimOptions(options)

        -- print("Anim starts on anim event: " .. tostring(anim.startOnAnimEvent) .. ", proper armature type: " .. tostring(isProperArmatureType(anim)) .. ", proper stance: " .. tostring(isProperStance(anim)))
        if anim.startOnAnimEvent and animation.hasGroup(omwself, anim.groupname) and isProperArmatureType(anim) and isProperStance(anim) then
            local shouldStart = anim:condition()
            if shouldStart then
                -- End this override's groupname and run pre-override pass. 
                -- Reminder: pre-override pass is there to allow for dynamic anim.groupname changes, i.e
                -- it should be supported for anim.preOverride to change its own anim.groupname.  
                --print("Should start " .. anim.groupname, "startKey: " .. tostring(startKey) .. ", stopKey: " .. tostring(stopKey), "enabled: " .. tostring(anim.enabled), "running: " .. tostring(anim.running))        
                if anim.preOverride then anim:preOverride(options) end
                --print("After preover check - enabled: " .. tostring(anim.enabled), "running: " .. tostring(anim.running))        

                -- This is necessary for alt attacks to work
                animation.cancel(omwself, anim.groupname)
                anim.running = false

                -- Play the override!   
                if anim.enabled and not anim.running then
                    --print("Overriding " .. anim.parent .. " with " .. anim.groupname, "startKey: " .. tostring(startKey) .. ", stopKey: " .. tostring(stopKey))
                    I.AnimationController.playBlendedAnimation(anim.groupname, anim:options(options)) 
                    anim.running = true
                    addToTrackedAnimsList(anim)
                end
            end
        end
    end
end)



local function onUpdate(dt)
    if not trackedAnims_n or dt <= 0 then return end
    --print("onUpdate called. dt: " .. tostring(dt) .. ", trackedAnims_n: " .. tostring(trackedAnims_n))
    
    frame_n = frame_n + 1    
    if trackedAnims_n <= 0 then return end   

    for i = trackedAnims_n, 1, -1 do
        local anim = trackedAnims[i]
        --print(anim.groupname .. " is being checked for update. Running: " .. tostring(anim.running))
        
        local isParentPlaying = nil
        local isPlaying = nil
        local shouldStart = nil
        local shouldStop = nil

        -- Should we stop an already running animation?
        if anim.running then
            isPlaying = animManager.isPlaying(anim.groupname)
            if anim.parent then isParentPlaying = animManager.isPlaying(anim.parent) end

            -- print("Is anim " .. anim.groupname .. " playing: " .. tostring(isPlaying) .. ", is parent " .. tostring(anim.parent) .. " playing: " .. tostring(isParentPlaying))

            if not isPlaying then anim.running = false end

            shouldStop = isPlaying and
                ((anim.stopCondition and anim:stopCondition()) or (anim.parent and not isParentPlaying))
        end

        -- Should we start a non-running tracked animation?
        if anim.startOnUpdate and not anim.running then
            if anim.parent and isParentPlaying == nil then isParentPlaying = animManager.isPlaying(anim.parent) end

            --print("Checking " .. anim.groupname .. " start conditions on update. Parent: " .. tostring(anim.parent) .. ", isParentPlaying: " .. tostring(isParentPlaying) .. ", condition: " .. tostring(anim:condition()) .. ", hasGroup: " .. tostring(animation.hasGroup(omwself, anim.groupname)))
            shouldStart = (not anim.parent or isParentPlaying) and anim:condition() and animation.hasGroup(omwself, anim.groupname)
        end

        -- Starting and stopping animations
        if shouldStart then
            --print("Starting " .. anim.groupname .. " on update")
            I.AnimationController.playBlendedAnimation(anim.groupname, anim:options())
            anim.running = true
        end
        if shouldStop then
            --print("Stopping " .. anim.groupname .. " on update")
            animation.cancel(omwself, anim.groupname)
            anim.running = false            
        end

        -- Cleanup. Non-running animations are removed from the tracked list (purely for optimization)
        if not anim.running then
            removeFromTrackedAnimsList(i)
        end        
    end
end

return {
    interfaceName = "ReAnimation",
    interface = {
        version = 2.6,
        ARMATURE_TYPE = gutils.ARMATURE_TYPE,
        STANCE = gutils.STANCE,
        addAnimationOverride = addAnimationOverride,        
        addAltAttackAnimations = addAltAttackAnimations,
        removeAnimationOverride = removeAnimationOverride,
        animations = animations,
        gutils = gutils,
        state = state,
    },
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
