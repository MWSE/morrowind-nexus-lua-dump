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
local initial_xp = {} ---@type table<tes3.skill, number>


local sm_xp_overflow = {}
local sm_initial_xp = {}


-- =============================================================================
-- LOG MESSAGES (defined here to "improve" code readability later on)
-- =============================================================================


local function logmsg_not_enough_xp(xp_obtained, progress_needed) 
    return "we didn't get enough xp to levelup, so returning and not doing anything else.\n\t\z
        xp obtained: ......... %3.4f\n\t\z
        xp needed for levelup: %3.4f", xp_obtained, progress_needed
end




-- =============================================================================
-- ACTUAL CODE
-- =============================================================================

--- runs at the very beginning of the `exerciseSkill` event, before any mods change the xp gained.
-- all it does is record the initial amount of xp we gained. (we will need this in order to find out how other mods modified the amount of gained xp)
---@param e exerciseSkillEventData
local function get_initial_xp(e)
    initial_xp[e.skill] = e.progress
    if DEBUGGING then
        log_es("exercising %q (id=%s). setting initial_xp = %3.4f",
            tes3.getSkillName(e.skill), e.skill, initial_xp[e.skill], e.progress
        )
    end
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
    if e.progress < XP_CUTOFF then return end

    local id = e.skill
    local raw_xp = initial_xp[id]

    if raw_xp <= 0 then return end
    
    -- getSkillProgressRequirement doesn't take into account our current progress
    local progress_needed = math.floor(tes3.mobilePlayer:getSkillProgressRequirement(id)) - tes3.mobilePlayer.skillProgress[id+1]

    local modified_xp = e.progress

    -- nothing to do if we dont have enough xp to level up
    if modified_xp < progress_needed then
        if DEBUGGING then
            log_es(logmsg_not_enough_xp, modified_xp, progress_needed)
        end
        return
    end

    -- `raw_xp * modifier == modified_xp` ~> `modifier = modified_xp/raw_xp`

    local modifier = modified_xp/raw_xp

    xp_overflow[id] = raw_xp - progress_needed/modifier

    -- reset initial xp
    initial_xp[e.skill] = 0

    if DEBUGGING then
        log_es("got enough xp to level up %q (id=%i).\n\t\z
            initial_xp: ............. %3.4f\n\t\z
            modified_xp: ............ %3.4f\n\t\z
            modifier: ............... %3.4f\n\t\z
            progress_needed: ........ %3.4f\n\t\z
            progress_needed/modifier: %3.4f\n\t\z
            ----------------------------------\n\t\z
            xp_overflow: ............ %3.4f == %3.4f - %3.4f\n\t\z 
            xp_overflow (%%): ........ %3.4f%%\n", 
            tes3.getSkillName(id), id,
            raw_xp, 
            modified_xp, 
            modifier, 
            progress_needed, 
            progress_needed/modifier,
            -----------
            xp_overflow[id], raw_xp, progress_needed/modifier,
            (100 * xp_overflow[id]) / (math.floor(tes3.mobilePlayer:getSkillProgressRequirement(id)) / modifier)
        )
    end

    -- the extra xp is the total xp we were supposed to get, with only the requirements towards progressing the next level being modified
    -- this is so that modifiers dont get applied twice
    -- this code could be simplified to be ` initial_xp * (1 - progress_needed/final_xp)`, but i think that's less clear than what's going on here
    -- and it's harder to debug
    
end


-- runs everytime a skill is leveled up
-- checks if the skill that we're leveling up had any bonus xp to add, and then adds it
---@param e skillRaisedEventData
local function skill_raised(e)
    local id = e.skill
    local extra_xp = xp_overflow[id]

    if not extra_xp then return end

    if extra_xp <= 0 then
        if DEBUGGING then
            log_sr("extra_xp was %3.4f, so setting it to nil and returning.", extra_xp)
        end
        xp_overflow[id] = nil
        return
    end
    -- we dont need to subtract a term since player progress will always be 0 upon leveling up
    if DEBUGGING then
        log_sr("%q (id=%i) was raised to level %i. adding %3.4f extra xp once levelup finishes.\n",
            tes3.getSkillName(id), id, e.level, extra_xp
        )
    end
    xp_overflow[id] = nil
    tes3.mobilePlayer:exerciseSkill(id, extra_xp)
end


-- =============================================================================
-- SKILL MODULE COMPATIBILITY
-- =============================================================================


---@param e SkillsModule.exerciseSkillEventData
local function sm_get_initial_xp(e)
    sm_initial_xp[e.skill.id] = e.progress
    if DEBUGGING then
        log_es("exercising %q (id=%q). setting initial_xp = %3.4f", e.skill.name, e.skill.id, sm_initial_xp[e.skill.id])
    end
end


---@param e SkillsModule.exerciseSkillEventData
local function sm_exercise_skill(e)
    -- only do things when xp is big enough
    if e.progress < XP_CUTOFF then return end
    
    local skill = e.skill
    local id = e.skill.id
    local raw_xp = sm_initial_xp[id]

    if not raw_xp or raw_xp <= 0 then return end

    -- let's just pretend this isn't a private method :)
    ---@diagnostic disable-next-line: invisible
    local progress_needed = skill:getProgressRequirement() - skill.progress

    local modified_xp = e.progress

    -- nothing to do if we dont have enough xp to level up
    if modified_xp < progress_needed then
        if DEBUGGING then
            log_es(logmsg_not_enough_xp, modified_xp, progress_needed)
        end
        return
    end

    -- `raw_xp * modifier == modified_xp` ~> `modifier = modified_xp/raw_xp`
    local modifier = modified_xp/raw_xp

    -- the extra xp is the total xp we were supposed to get, with only the requirements towards progressing the next level being modified
    -- this is so that modifiers dont get applied twice
    -- this code could be simplified to be ` initial_xp * (1 - progress_needed/final_xp)`, but i think that's less clear than what's going on here
    -- and it's harder to debug
    sm_xp_overflow[id] = raw_xp - progress_needed/modifier

    sm_initial_xp[id] = 0

    if DEBUGGING then
        log_es("got enough xp to levelup %q (id=%q).\n\t\z
            initial_xp: ............. %3.4f\n\t\z
            modified_xp: ............ %3.4f\n\t\z
            modifier: ............... %3.4f\n\t\z
            progress_needed: ........ %3.4f\n\t\z
            progress_needed/modifier: %3.4f\n\t\z
            ----------------------------------\n\t\z
            xp_overflow: ............ %3.4f == %3.4f - %3.4f\n\t\z 
            xp_overflow (%%): ........ %3.4f%%\n", 
            skill.name, id,
            raw_xp, 
            modified_xp, 
            modifier, 
            progress_needed, 
            progress_needed/modifier,
            -------------------
            sm_xp_overflow[id], raw_xp, progress_needed/modifier, ---@diagnostic disable-next-line: invisible
            100 * modifier * sm_xp_overflow[id] / skill:getProgressRequirement()
        )
    end

end


-- runs everytime a skill is leveled up
-- checks if the skill that we're leveling up had any bonus xp to add, and then adds it
---@param e SkillsModule.skillRaisedEventData
local function sm_skill_raised(e)
    
    local skill = e.skill
    local extra_xp = sm_xp_overflow[skill.id]

    if not extra_xp then return end

    if extra_xp <= 0 then
        if DEBUGGING then 
            log_sr("extra_xp was %3.4f, so setting it to nil and returning.", extra_xp)
        end
        xp_overflow[skill.id] = nil
        return
    end
    -- we dont need to subtract a term since player progress will always be 0 upon leveling up
    if DEBUGGING then
        log_sr("%q (id=%q) was raised to level %i. adding %3.4f extra xp once levelup finishes.\n",
            skill.name, skill.id, e.level, extra_xp
        )
    end
    xp_overflow[skill.id] = nil
    skill:exercise(extra_xp)
end


local function initialize()
    for _, id in pairs(tes3.skill) do
        initial_xp[id] = 0
    end
    -- use livecoding if we're debugging
    if DEBUGGING and livecoding then

        livecoding.registerEvent(tes3.event.exerciseSkill, get_initial_xp, {priority=INITIAL_XP_PRIORITY})
        livecoding.registerEvent(tes3.event.exerciseSkill, exercise_skill, {priority=EXERCISE_SKILL_PRIORITY})
        livecoding.registerEvent(tes3.event.skillRaised, skill_raised, {priority=SKILL_RAISED_PRIORITY})

        livecoding.registerEvent("SkillsModule:exerciseSkill", sm_get_initial_xp, {priority=INITIAL_XP_PRIORITY})
        livecoding.registerEvent("SkillsModule:exerciseSkill", sm_exercise_skill, {priority=EXERCISE_SKILL_PRIORITY})
        livecoding.registerEvent("SkillsModule:skillRaised", sm_skill_raised, {priority=SKILL_RAISED_PRIORITY})
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

        event.register("SkillsModule:exerciseSkill", sm_get_initial_xp, {priority=INITIAL_XP_PRIORITY})
        event.register("SkillsModule:exerciseSkill", sm_exercise_skill, {priority=EXERCISE_SKILL_PRIORITY})
        event.register("SkillsModule:skillRaised", sm_skill_raised, {priority=SKILL_RAISED_PRIORITY})
    end

    
end
if DEBUGGING and livecoding then
    initialize()
end

event.register(tes3.event.initialized, initialize)