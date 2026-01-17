local async = require('openmw.async')
local camera = require('openmw.camera')
local core = require('openmw.core')
local input = require('openmw.input')
---@type nearby
local nearby = require('openmw.nearby')
local self = require('openmw.self')
local util = require('openmw.util')

local I = require('openmw.interfaces')

local Stats = self.type.stats

local DynamicStats = Stats.dynamic
local Fatigue = DynamicStats.fatigue(self)

local Attributes = Stats.attributes
local Agility = Attributes.agility(self)
local Speed = Attributes.speed(self)

local Skills = Stats.skills
local Athletics = Skills.athletics(self)
local Acrobatics = Skills.acrobatics(self)

local API = require('openmw.interfaces').SkillFramework

local skillId = 'climbing_skill'

local useTypes = {
    ClimbStart = 1,
    ClimbTick  = 2,
}

API.registerSkill(skillId, {
    name = 'Climbing',
    description = 'Ability to scale walls and ledges.',
    attribute = 'agility',
    specialization = API.SPECIALIZATION.Stealth,

    -- MUST be a table indexed by your useType numbers
    skillGain = {
        [useTypes.ClimbStart] = .25,
        [useTypes.ClimbTick]  = .05,
    },

    startLevel = 5,
    maxLevel = 100,
    statsWindowProps = {
        subsection = API.STATS_WINDOW_SUBSECTIONS.Movement
    }
})


local function getClimbingLevel()
    -- SkillFramework versions differ; try common patterns without crashing.
    if API.getSkillLevel then
        return API.getSkillLevel(skillId)
    end

    if API.getSkill then
        local s = API.getSkill(skillId)
        if s and s.level then return s.level end
        if s and s.base then return s.base end
    end

    -- If we can't read it, fall back so climbing still works.
    return 5
end

local function lerp(a, b, t)
    return a + (b - a) * t
end


--- @class ClimbMod
--- @field CLIMB_ACTIVATE_RANGE number The maximum range (in units) within which climbing can be activated.
--- @field CLIMB_SEARCH_STEP_RANGE number The step range (in units) used for searching for the top of climbable surfaces.

--- @class ClimbState
--- @field climbEngaged boolean Indicates whether the climbing state is currently active.
--- @field climbRisePos nil|util.vector3 The first stopping point during the climb, before moving forward. Nil if not climbing.
--- @field climbEndPos nil|util.vector3 The position where the climb ends. Nil if not climbing.
--- @field prevCamMode nil|number The previous camera mode before climbing was engaged. Nil if not climbing.

local ClimbMod = {
    CLIMB_ACTIVATE_RANGE = 64,
    CLIMB_SEARCH_STEP_RANGE = 2,
}

local ClimbState = {
    climbEngaged = false,
    climbRisePos = nil,
    climbEndPos = nil,
    prevCamMode = nil,
}

local climbXpTimer = 0


--- Toggles the override state for various control systems in the game.
--- 
--- This function enables or disables the override for movement, combat, 
--- and UI controls based on the provided state.
---
--- @param state boolean
---   A boolean value indicating whether to enable (`true`) or disable (`false`) 
---   the override for the controls.
function ClimbMod.switchControls(state)
    I.Controls.overrideMovementControls(state)
    I.Controls.overrideCombatControls(state)
    I.Controls.overrideUiControls(state)
end

--- Engages the climbing mode by setting the climb state to active and
--- storing the starting and ending positions of the climb.
--- XP will be granted immediately when climbing starts.
---
--- @param risePos util.vector3 The starting position of the climb.
--- @param endPos util.vector3 The ending position of the climb.
--- Engages the climbing mode
function ClimbMod.engage(risePos, endPos)
  ClimbMod.switchControls(true)

  ClimbState = {
    climbEngaged = true,
    climbRisePos = risePos,
    climbEndPos  = endPos,
    prevCamMode  = camera.getMode(),
  }

  camera.setMode(camera.MODE.FirstPerson)

  core.sendGlobalEvent('S3_ChimClimb_ClimbStart', {
    startPos = risePos,
    endPos = endPos,
    fatigueDrain = ClimbMod.getFatigueDrain(),
    speedMult = ClimbMod.getSpeedMult(),
    target = self.object,
  })

  -- SkillFramework: award via registered skillGain[useType]
  API.skillUsed(skillId, { useType = useTypes.ClimbStart })
	print("[Climbing XP] ClimbStart fired")
end

function ClimbMod.disengage()
  ClimbMod.switchControls(false)
  camera.setMode(ClimbState.prevCamMode or camera.MODE.ThirdPerson)

  ClimbState = {
    climbEngaged = false,
    climbRisePos = nil,
    climbEndPos  = nil,
    prevCamMode  = nil,
  }

  core.sendGlobalEvent('S3_ChimClimb_ClimbInterrupt', self.id)

  -- Optional, but usually unnecessary:
  -- API.skillUsed(skillId, { useType = useTypes.ClimbEnd })
end

--- Calculates the fatigue drain for climbing based on game settings and the player's encumbrance.
--- 
--- This function retrieves the base fatigue drain and the multiplier for fatigue drain from 
--- game settings (GMST). It then calculates the normalized encumbrance of the player as a 
--- ratio of their current encumbrance to their maximum capacity. The final fatigue drain 
--- is computed as the sum of the base fatigue drain and the product of the multiplier with 
--- the normalized encumbrance. 
--- https://wiki.openmw.org/index.php?title=Research:Movement#On_jumping
---
--- @return number The calculated fatigue drain value.
function ClimbMod.getFatigueDrain()
    local fatigueJumpBase = core.getGMST('fFatigueJumpBase')
    local fatigueJumpMult = core.getGMST('fFatigueJumpMult')
    local encRatio = self.type.getEncumbrance(self) / self.type.getCapacity(self)

    local baseDrain = fatigueJumpBase + (fatigueJumpMult * encRatio)

    local lvl = getClimbingLevel()
    local t = math.min(math.max(lvl / 100, 0), 1)

    -- At level 5: ~1.0x drain
    -- At level 100: ~0.55x drain (tune)
    local drainMult = lerp(1.0, 0.55, t)

    return baseDrain * drainMult
end


--- Calculates the flat value of a given stat, ensuring it does not exceed 100.
--- 
--- This function takes a stat object with a `modified` property and returns
--- the lesser of the `modified` value or 100. It is useful for clamping
--- stat values to a maximum threshold.
---
--- @param stat userdata A table representing the stat, which must contain a `modified` field.
--- @return number The clamped stat value, capped at 100.
local function getStatMult(stat)
---@diagnostic disable-next-line: undefined-field
    return math.min(stat.modified, 100) / 100
end

--- Calculates the climbing speed multiplier based on player attributes and skills.
--- TODO: Also account for normalized encumbrance, maybe
--- @return number The climbing speed multiplier.
function ClimbMod.getSpeedMult()
    local agilityFactor = getStatMult(Agility)
    local speedFactor = getStatMult(Speed)
    local athleticsFactor = getStatMult(Athletics)
    local acrobaticsFactor = getStatMult(Acrobatics)

    -- Weighted formula for climbing speed multiplier
    local multiplier = 1.0 + (0.4 * speedFactor) + (0.3 * athleticsFactor) + (0.1 * agilityFactor) + (0.2 * acrobaticsFactor)

    -- Clamp the multiplier to a reasonable range (e.g., 1.0 to 2.0)
    return math.min(math.max(multiplier, 1.0), 2.0)
end

--- Calculates the climbing range for the player based on their bounding box.
---
--- This function determines the center of the player's bounding box and a point
--- directly above it at a height equal to twice the bounding box's half-size along the z-axis.
---
--- @return number minHeight The center of the player's bounding box. Objects lower than this can't be climbed.
--- @return number topPoint Z position of player's center + 2X z halfSize. Objects higher than this can't be climbed.
function ClimbMod.climbRanges()
    local box = self:getBoundingBox()
    local baseHeight = box.halfSize.z * 2

    local lvl = getClimbingLevel()
    local t = math.min(math.max(lvl / 100, 0), 1) -- 0..1

    -- At level 5: ~1.00x
    -- At level 100: ~1.75x (tune this)
    local heightMult = lerp(1.0, 2.4, t)

    local minZ = box.center.z
    local maxZ = box.center.z + (baseHeight * heightMult)

    return minZ, maxZ
end


--- Perform a raycast to find the maximum climbable height.
--- @param center util.vector3 The starting position of the raycast.
--- @param scanPos util.vector3 The ending position of the raycast.
--- @return RayCastingResult|nil The highest hit object or nil if no valid hit is found.
function ClimbMod.findMaxClimbableHeight(center, scanPos)
  local upwardHit
  local firstObj = nil

  while true do
    center = center + util.vector3(0, 0, ClimbMod.CLIMB_SEARCH_STEP_RANGE)
    scanPos = scanPos + util.vector3(0, 0, ClimbMod.CLIMB_SEARCH_STEP_RANGE)

    local currentHit = nearby.castRay(center, scanPos, {
      ignore = { self.object },
      collisionType = nearby.COLLISION_TYPE.World,
    })

    if not currentHit.hit then break end
    if not currentHit.hitPos then break end

    if not firstObj then firstObj = currentHit.hitObject end
    if currentHit.hitObject ~= firstObj then
      -- we climbed past the original surface onto something else; stop
      break
    end

    upwardHit = currentHit
  end

  return upwardHit
end

function ClimbMod.isClimbable(upwardHit)
    if not upwardHit or not upwardHit.hit or not upwardHit.hitPos then
        return false
    end

    local climbMin, climbMax = ClimbMod.climbRanges()
    local hitZ = upwardHit.hitPos.z

    -- Hard limits
    if hitZ < climbMin then
        return false
    end

    -- Soft over-height logic
    local lvl = getClimbingLevel()
    local over = hitZ - climbMax

    -- Free grace: small pull-up
    local grace = 10 + (lvl * 0.4)
    if over <= grace then
        return true
    end

    -- Chance-based scramble beyond grace
    local chance = math.max(0.05, 1.0 - ((over - grace) / 80))
    if math.random() < chance then
        print("Barely made the climb! Chance:", chance)
        return true
    end

    print("Too high to climb. Over by:", over)
    return false
end


--- Calculate the final destination for the climb.
--- @param upwardHit table The highest hit object.
--- @param zTransform table The player's Z rotation transform.
--- @return util.vector3 The final destination position.
local function calculateFinalDestination(upwardHit, zTransform)
    -- Start slightly above the ledge hit point
    local firstStopPoint = util.vector3(
        upwardHit.hitPos.x,
        upwardHit.hitPos.y,
        upwardHit.hitPos.z + 5
    )

    -- Step forward distance (tweakable)
    local forwardStep = self:getBoundingBox().halfSize.y / 2
    local forwardVec  = zTransform:apply(util.vector3(0, forwardStep, 0))
    local desiredPos  = firstStopPoint + forwardVec

    local rayOpts = {
        ignore = { self.object },
        collisionType = nearby.COLLISION_TYPE.World,
    }

    -- 1) Check forward clearance: don't move into a wall
    local forwardHit = nearby.castRay(firstStopPoint, desiredPos, rayOpts)
    local clearedPos = desiredPos
    if forwardHit.hit and forwardHit.hitPos then
        -- Stop short of the hit so we don't snap into the wall
        local backOff = zTransform:apply(util.vector3(0, -8, 0))
        clearedPos = forwardHit.hitPos + backOff
    end

    -- 2) Drop down onto the surface (find walkable landing)
    local dropFrom = clearedPos + util.vector3(0, 0, 40)
    local dropTo   = clearedPos - util.vector3(0, 0, 120)

    local groundHit = nearby.castRay(dropFrom, dropTo, rayOpts)
    if groundHit.hit and groundHit.hitPos then
        return groundHit.hitPos
    end

    -- Fallback: if no ground found, return the cleared position
    return clearedPos
end

input.registerTriggerHandler(
    "Jump",
    async:callback(function()
        if ClimbState.climbEngaged then
            return ClimbMod.disengage()
        end

        -- Transform encompassing player's current Z Rotation
        local zTransform = util.transform.rotateZ(self.rotation:getYaw())
        local center = self:getBoundingBox().center

        local lvl = getClimbingLevel()
        local t = math.min(math.max(lvl / 100, 0), 1)

        local activateRange = lerp(ClimbMod.CLIMB_ACTIVATE_RANGE, 96, t) -- 64 -> 96
        local scanPos = center + zTransform:apply(util.vector3(0, activateRange, 0))

        local waistHit = nearby.castRay(center, scanPos, {
            ignore = { self.object },
            collisionType = nearby.COLLISION_TYPE.World,
        })

        if not waistHit.hit then
            print("No hit detected at waist level.")
            return
        elseif not waistHit.hitObject then
            error("No hit object detected, but something was hit! Is the collisionType correct?")
        end

        print('\n', "Center is:", center, '\n', 'scanPos is:', scanPos, '\n', 'zTransform is', zTransform, '\n\n\n')

        local upwardHit = ClimbMod.findMaxClimbableHeight(center, scanPos)
        if not upwardHit then
            error('No upward hit detected.')
        end

        if not ClimbMod.isClimbable(upwardHit) then
            print("Hit object is not climbable.")
            return
        end

        local finalDestination = calculateFinalDestination(upwardHit, zTransform)
        print("Final destination is", finalDestination)

        ClimbMod.engage(upwardHit.hitPos, finalDestination)
    end)
)

return {
    engineHandlers = {
onFrame = function(dt)
    if ClimbState.climbEngaged then
        -- award XP once per second while climbing (optional)
        climbXpTimer = climbXpTimer + dt
        if climbXpTimer >= 1.0 then
            climbXpTimer = climbXpTimer - 1.0
            API.skillUsed(skillId, { useType = useTypes.ClimbTick })
		print("[Climbing XP] ClimbTick fired")
        end

        -- Prevent jump while climbing
        self.controls.jump = false

        -- Force first-person camera during climb
        if camera.getMode() ~= camera.MODE.FirstPerson then
            camera.setMode(camera.MODE.FirstPerson)
        end
    else
        -- reset timer when not climbing so next climb starts clean
        climbXpTimer = 0
    end
end,

        onSave = function()
            -- Save climb state
            return ClimbState
        end,

        onLoad = function(data)
            -- Load climb state or default values
            ClimbState = data or {
                climbEngaged = false,
                climbRisePos = nil,
                climbEndPos = nil,
                prevCamMode = nil,
            }
        end,
    },

    eventHandlers = {
        -- Climb end just resets the state, XP already given in onFrame
        S3_ChimClimb_ClimbEnd = ClimbMod.disengage,

        -- Update fatigue from global event
        S3_ChimClimb_DrainFatigue = function(newFatigue)
            Fatigue.current = newFatigue
        end,
    },
}

