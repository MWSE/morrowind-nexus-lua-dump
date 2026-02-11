local mp = "scripts/MaxYari/ReAnimation_v2/"

local omwself = require('openmw.self')
local types = require('openmw.types')
local core = require("openmw.core")

local animation = require('openmw.animation')
local I = require('openmw.interfaces')
local animManager = require(mp .. "scripts/anim_manager")
local gutils = require(mp .. "scripts/gutils")

DebugLevel = 0

local animations = {}
local attackCounters = {}
local activeAnims = {}
local activeAnims_n



--- API Functions -----------------------
--- -------------------------------------

local function addAnimationToParent(anim)
    if anim.parent and type(anim.parent) ~= "string" then
        return
    end
    local parent = animations[anim.parent or ""]
    if not parent then
        parent = {}		animations[anim.parent or ""] = parent
    end
    table.insert(parent, anim)
    if anim.alwaysActive then
        table.insert(activeAnims, 1, anim)	activeAnims_n = #activeAnims
    end
end

local function addAnimationOverride(anim)
    -- print("registering animation"  .. anim.groupname)
    if type(anim.parent) == "table" then
        for _, parent in ipairs(anim.parent) do
            local newAnimation = gutils.shallowTableCopy(anim)
            newAnimation.parent = parent
            addAnimationToParent(newAnimation)
        end
    else
        addAnimationToParent(anim)
    end
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
        parent = params.parentAttackGroupname,
        groupname = params.altAttackGroupname,
        armatureType = params.armatureType,
        condition = function(self)       
            local startKey = self.parentOptions.startkey or self.parentOptions.startKey
            if not gutils.isAttackType(startKey) then
                return false
            end
            local counterKey = self.parent .. gutils.isAttackType(startKey)
            return attackCounters[counterKey] == 1
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
    addAnimationToParent(override)
end



--- Core Override handling--------------------------
--- ------------------------------------------------

I.AnimationController.addPlayBlendedAnimationHandler(function(groupname, options)
    if not next(animations) then return end

    local startKey = options.startKey or "start"
    local stopKey = options.stopKey or "stop"

    -- print("Animation started", groupname, startKey, stopKey)

    -- Count attacks
    if gutils.isAttackTypeStart(startKey) then
        local key = groupname .. gutils.isAttackType(startKey)
        if not attackCounters[key] then attackCounters[key] = -1 end
        attackCounters[key] = (attackCounters[key] + 1) % 2
    end

    local parent = animations[groupname]	if not parent then	return		end

    -- Starting override anims
    for _, anim in ipairs(parent) do
        -- Learn parent options of animations
        anim.parentOptions = gutils.cloneAnimOptions(options)

        if animation.hasGroup(omwself, anim.groupname) and anim.startOnAnimEvent
            and gutils.isMatchingArmatureType(anim.armatureType) then
            if not anim.running and not anim.alwaysActive then
                table.insert(activeAnims, 1, anim)	activeAnims_n = #activeAnims
            end
            local shouldStart = anim:condition()
            if shouldStart then
                -- print("Overriding " .. anim.parent .. " with " .. anim.groupname)
                animation.cancel(omwself, anim.groupname)
                I.AnimationController.playBlendedAnimation(anim.groupname, anim:options(options))
                anim.running = true
            end
        end
    end
end)


local function onUpdate(dt)
    if not activeAnims_n or dt <= 0 then		return		end

    for i = activeAnims_n, 1, -1 do
        local anim = activeAnims[i]
        if gutils.isMatchingArmatureType(anim.armatureType) then
            local isParentPlaying = nil
            local isPlaying = nil
            local shouldStart = nil
            local shouldStop = nil

            if anim.running then
                isPlaying = animManager.isPlaying(anim.groupname)
                if anim.parent then isParentPlaying = animManager.isPlaying(anim.parent) end

                if not isPlaying then		anim.running = false                end

                shouldStop = isPlaying and
                    ((anim.stopCondition and anim:stopCondition()) or (anim.parent and not isParentPlaying))

            elseif anim.startOnUpdate and not anim.running then
                if anim.parent and isParentPlaying == nil then isParentPlaying = animManager.isPlaying(anim.parent) end

                shouldStart = (not anim.parent or isParentPlaying) and anim:condition() and animation.hasGroup(omwself, anim.groupname)
            end

            if shouldStart then
                I.AnimationController.playBlendedAnimation(anim.groupname, anim:options())
                anim.running = true
            elseif shouldStop then
                animation.cancel(omwself, anim.groupname)
                anim.running = false
            end
        end
        if not anim.alwaysActive and not anim.running then
            table.remove(activeAnims, i)	activeAnims_n = activeAnims_n - 1
        end
    end

    if activeAnims_n <= 0 then		activeAnims_n = nil		end
end

return {
    interfaceName = "ReAnimation",
    interface = {
        version = 2.53,
        ARMATURE_TYPE = gutils.ARMATURE_TYPE,
        addAnimationOverride = addAnimationOverride,
        addAltAttackAnimations = addAltAttackAnimations
    },
    engineHandlers = {
        onUpdate = onUpdate,
    }
}
