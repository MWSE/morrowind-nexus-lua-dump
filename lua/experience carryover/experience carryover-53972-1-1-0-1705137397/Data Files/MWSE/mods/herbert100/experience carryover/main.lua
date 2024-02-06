-- =============================================================================
-- MAGIC NUMBERS
-- =============================================================================
-- you can change these if you'd like. i didn't think a mod like this should have an MCM, since it would only take up space.

-- minimum XP value for which we should check for extra_xp
-- this is here because skills like athletics run every frame with miniscule amounts of xp
-- so it would be nice to not do all our stuff every frame
local XP_CUTOFF = 2^(-4)

-- the priority of the `exerciseSkill` events
local EXERCISE_SKILL_PRIORITY = -10000      -- this one should be super low. it's supposed to run after everything else
local INITIAL_XP_PRIORITY = 10000           -- this one should be super high. it's supposed to run before everything else.

-- priority of the `skillRaised` event.
local SKILL_RAISED_PRIORITY = 0


-- set this to true if you want to debug
local DEBUGGING = false

-- =============================================================================
-- ACTUAL CODE
-- =============================================================================

local log_es, log_sr ---@type herbert.Logger|fun(...), herbert.Logger|fun(...)


if DEBUGGING and include("herbert100.logger") then
    local Logger = include("herbert100.logger") ---@type herbert.Logger
    log_es = Logger.new{mod_name="experience carryover", module_name="exerciseSkill"}
    log_sr = Logger.new{mod_name="experience carryover", module_name="skillRaised"}
    log_sr:set_level(Logger.LEVEL.DEBUG)
else
    log_es = function() end
    log_sr = log_es
end

-- =============================================================================
-- COMPUTATION VARIABLES
-- =============================================================================
-- the raw amount of xp that overflowed from the last exercise skill event.
-- this does not take PPE into account
-- PPE is not taken into account here so that we can find the right modifiers for each level (they could change as the player/skill levels up)
local xp_overflow = {} ---@type table<tes3.skill, number>
local initial_xp = 0



-- =============================================================================
-- LOG MESSAGES (defined here to "improve" code readability later on)
-- =============================================================================
---@param e exerciseSkillEventData
local function logmsg_inital_xp(e) return
    "getting initial xp for \"%s\" (id=%i). initial_xp = %3.4f. this should be equal to %3.4f", 
    tes3.getSkillName(e.skill), e.skill, initial_xp, e.progress
end

---@param e exerciseSkillEventData
local function logmsg_es(e, modifier, progress_needed) return
    [[calculating stuff for "%s" (id=%i).
        initial_xp: ............. %3.4f
        final_xp: ............... %3.4f
        modifier: ............... %3.4f
        progress_needed: ........ %3.4f
        progress_needed/modifier: %3.4f
    
    ]], 
    tes3.getSkillName(e.skill), e.skill,
    initial_xp, 
    e.progress, 
    modifier, 
    progress_needed, 
    progress_needed/modifier
end

local function logmsg_es_not_enough_xp(xp_obtained, progress_needed) return
    [[we didn't get enough xp to levelup, so returning and not doing anything else.
    xp obtained: ......... %3.4f
    xp needed for levelup: %3.4f]],
    xp_obtained, progress_needed
end
---@param e exerciseSkillEventData
local function logmsg_es_overflow_set(e, modifier, progress_needed) return
    [[got more xp than we needed, setting xp_overflow[%i] = %3.4f, since
    initial_xp - progress_needed/modifier == %3.4f - %3.4f == %3.4f

    ]], 
    e.skill, xp_overflow[e.skill],

    initial_xp, progress_needed/modifier, xp_overflow[e.skill]
end
            


---@param e skillRaisedEventData
local function logmsg_sr(e) return 
    [["%s" (id=%i) was raised to level %i. adding %3.4f extra xp once levelup finishes.
    ]],
    tes3.getSkillName(e.skill), e.skill, e.level, xp_overflow[e.skill]
end



-- =============================================================================
-- ACTUAL CODE
-- =============================================================================

--- runs at the very beginning of the `exerciseSkill` event, before any mods change the xp gained.
-- all it does is record the initial amount of xp we gained. (we will need this in order to find out how other mods modified the amount of gained xp)
---@param e exerciseSkillEventData
local function get_initial_xp(e)
    initial_xp = e.progress
    log_es(logmsg_inital_xp, e)
end

--[[ called whenever we gain xp for a skill. this runs after ALL other mods
    it receives the final amount of xp the player will get, after all modifiers are applied
    it then uses `initial_xp` to calculate the modifier that was applied to this skill
    it then applies that modifier ONLY to the amount of xp that will get us a levelup.
    i.e., the excess xp is added to `xp_overflow` in an unmodified state. (it will get modified later on, dont worry)
    once `skillRaised` is called, we will exercise the relevant skill again, passing in the unmodified amount of xp
    this will trigger the `exerciseSkill` event again, and at this point, modifiers will be applied to the remaining chunk of xp.
    if the remaining chunk of xp is enough to get us a full levelup, then the cycle will repeat again.
]]
---@param e exerciseSkillEventData
local function exercise_skill(e)
    -- only do things when xp is big enough
    if e.progress < XP_CUTOFF or initial_xp <= 0 then return end
    
    local skill_id = e.skill
    -- getSkillProgressRequirement doesn't take into account our current progress
    local progress_needed = tes3.mobilePlayer:getSkillProgressRequirement(skill_id) - tes3.mobilePlayer.skillProgress[skill_id+1]

    local final_xp = e.progress

    -- nothing to do if we dont have enough xp to level up
    if final_xp < progress_needed then
        log_es(logmsg_es_not_enough_xp, final_xp, progress_needed)
        return
    end

    -- `initial_xp * modifier == final_xp` ~> `modifier = final_xp/initial_xp`
    local modifier = final_xp/initial_xp

    log_es(logmsg_es, e, modifier, progress_needed )

    -- the extra xp is the total xp we were supposed to get, with only the requirements towards progressing the next level being modified
    -- this is so that modifiers dont get applied twice
    -- this code could be simplified to be ` initial_xp * (1 - progress_needed/final_xp)`, but i think that's less clear than what's going on here
    -- and it's harder to debug
    xp_overflow[skill_id] = initial_xp - progress_needed/modifier

    log_es(logmsg_es_overflow_set, e, modifier, progress_needed)
end


-- runs everytime a skill is leveled up
-- checks if the skill that we're leveling up had any bonus xp to add, and then adds it
---@param e skillRaisedEventData
local function skill_raised(e)
    local id = e.skill
    local extra_xp = xp_overflow[id]

    if not extra_xp then return end

    if extra_xp <= 0 then
        log_sr("extra_xp was %3.4f, so setting it to nil and returning.", extra_xp)
        xp_overflow[id] = nil
        return
    end
    -- we dont need to subtract a term since player progress will always be 0 upon leveling up
    log_sr(logmsg_sr, e)
    xp_overflow[id] = nil
    tes3.mobilePlayer:exerciseSkill(id, extra_xp)
end


local function initialize()
    -- use livecoding if we're debugging
    if DEBUGGING and livecoding then

        livecoding.registerEvent(tes3.event.exerciseSkill, get_initial_xp, {priority=INITIAL_XP_PRIORITY})
        livecoding.registerEvent(tes3.event.exerciseSkill, exercise_skill, {priority=EXERCISE_SKILL_PRIORITY})
        livecoding.registerEvent(tes3.event.skillRaised, skill_raised, {priority=SKILL_RAISED_PRIORITY})

        ---@param e keyDownEventData
        local function give_sneak_xp(e) 
            if e.isAltDown then 
                tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, 100) 
            end 
        end

        livecoding.registerEvent(tes3.event.keyDown, give_sneak_xp, {filter=tes3.scanCode.p})
    else
        mwse.log("[experience carryover: INFO] Mod initialized.") -- why not spoof the mwseLogger just this once
        event.register(tes3.event.exerciseSkill, get_initial_xp, {priority=INITIAL_XP_PRIORITY})
        event.register(tes3.event.exerciseSkill, exercise_skill, {priority=EXERCISE_SKILL_PRIORITY})
        event.register(tes3.event.skillRaised, skill_raised, {priority=SKILL_RAISED_PRIORITY})
    end

    
end
if DEBUGGING and livecoding then
    initialize()
end

event.register(tes3.event.initialized, initialize)