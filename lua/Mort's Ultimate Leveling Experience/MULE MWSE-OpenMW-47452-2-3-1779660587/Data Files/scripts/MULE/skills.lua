local core = require('openmw.core')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local T = require('openmw.types')
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')

local mS = require('scripts.MULE.settings')

local module = {}

local levelUpMessages = {
	[2] = "You realize that all your life you have been coasting along as if you were in a dream. Suddenly, facing the trials of the last few days, you have come alive.",
	[3] = "You realize that you are catching on to the secret of success. It's just a matter of concentration.",
	[4] = "It's all suddenly obvious to you. You just have to concentrate. All the energy and time you've wasted -- it's a sin. But without the experience you've gained, taking risks, taking responsibility for failure, how could you have understood?",
	[5] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
	[6] = "You sense yourself more aware, more open to new ideas. You've learned a lot about Morrowind. It's hard to believe how ignorant you were -- but now you have so much more to learn.",
	[7] = "You resolve to continue pushing yourself. Perhaps there's more to you than you thought.",
	[8] = "The secret does seem to be hard work, yes, but it's also a kind of blind passion, an inspiration.",
	[9] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
	[10] = "You woke today with a new sense of purpose. You're no longer afraid of failure. Failure is just an opportunity to learn something new.",
	[11] = "Being smart doesn't hurt. And a little luck now and then is nice. But the key is patience and hard work. And when it pays off, it's SWEET!",
	[12] = "You can't believe how easy it is. You just have to go -- a little crazy. And then, suddenly, it all makes sense, and everything you do turns to gold.",
	[13] = "It's the most amazing thing. Yesterday it was hard, and today it is easy. Just a good night's sleep, and yesterday's mysteries are today's masteries.",
	[14] = "Today you wake up, full of energy and ideas, and you know, somehow, that overnight everything has changed. What a difference a day makes.",
	[15] = "Today you suddenly realized the life you've been living, the punishment your body has taken -- there are limits to what the body can do, and perhaps you have reached them. You've wondered what it is like to grow old. Well, now you know.",
	[16] = "You've been trying too hard, thinking too much. Relax. Trust your instincts. Just be yourself. Do the little things, and the big things take care of themselves.",
	[17] = "Life isn't over. You can still get smarter, or cleverer, or more experienced, or meaner -- but your body and soul just aren't going to get any younger.",
	[18] = "The challenge now is to stay at the peak as long as you can. You may be as strong today as any mortal who has ever walked the earth, but there's always someone younger, a new challenger.",
	[19] = "You're really good. Maybe the best. And that's why it's so hard to get better. But you just keep trying, because that's the way you are.",
	[20] = "You'll never be better than you are today. If you are lucky, by superhuman effort, you can avoid slipping backwards for a while. But sooner or later, you're going to lose a step, or drop a beat, or miss a detail -- and you'll be gone forever.",
	[21] = "The results of hard work and dedication always look like luck to saps. But you know you've earned every ounce of your success."
}

local function getSkillType(state, skillId)
    if state.skills.major[skillId] then return "major" end
    if state.skills.minor[skillId] then return "minor" end
    return "misc"
end

local function bumpAttribute(attrId)
    local attr = T.Actor.stats.attributes[attrId](self)
    attr.base = attr.base + 1

    if attrId == "endurance" and mS.mainStorage:get("alternateHealthSystem") then
        local gain = mS.mainStorage:get("healthPerEndurance")
        local hp = T.Actor.stats.dynamic.health(self)
        hp.base = hp.base + gain
        hp.current = hp.current + gain
    end

    ui.showMessage(string.format("Your %s has improved.", core.stats.Attribute.records[attrId].name))
end

local function applyAttributeProgress(state, attrId, amount)
    if not attrId or amount == 0 then return end
    local cap = mS.mainStorage:get("attributeMaximum")
    local progress = state.attrs.progress[attrId] + amount
    while progress >= 1.0 and T.Actor.stats.attributes[attrId](self).base < cap do
        progress = progress - 1
        bumpAttribute(attrId)
    end
    state.attrs.progress[attrId] = progress
end

local function applyLuckProgress(state, amount)
    local cap = mS.mainStorage:get("attributeMaximum")
    local progress = state.attrs.progress.luck + amount
    local luck = T.Actor.stats.attributes.luck(self)
    while progress >= 1.0 and luck.base < cap do
        progress = progress - 1
        luck.base = luck.base + 1
    end
    state.attrs.progress.luck = progress
end

local function drainSkill(skillId, amount)
    local skill = T.NPC.stats.skills[skillId](self)
    skill.base = skill.base + amount
    if mS.decayStorage:get("skillDecayMessage") then
        local skillName = core.stats.Skill.records[skillId].name
        ui.showMessage(string.format("You have lost %s.", skillName))
    end
end

local function processDecay(state, currentSkillId)
    if not mS.decayStorage:get("skillDecay") then return end

    local today = math.floor(core.getGameTime() / 86400)
    local cutoff = today - mS.decayStorage:get("skillDecayTime")
    local decayMin = mS.decayStorage:get("skillDecayMin")
    local useBase = mS.decayStorage:get("skillDecayUseBase")

    state.skills.lastUsed[currentSkillId] = today

    for skillId, lastDay in pairs(state.skills.lastUsed) do
        if lastDay < cutoff then
            local current = T.NPC.stats.skills[skillId](self).base
            local startVal = state.skills.baseValues[skillId] or 0
            if current > decayMin or (useBase and current > startVal) then
                state.skills.lastUsed[skillId] = today
                drainSkill(skillId, -1)
            end
        end
    end
end

module.classifySkills = function(state)
    local playerRec = T.NPC.record(self)
    local class = T.NPC.classes.record(playerRec.class)

    state.skills.major = {}
    state.skills.minor = {}
    state.skills.misc = {}

    for _, skillId in ipairs(class.majorSkills) do
        state.skills.major[skillId] = true
    end
    for _, skillId in ipairs(class.minorSkills) do
        state.skills.minor[skillId] = true
    end
    for _, skill in ipairs(core.stats.Skill.records) do
        if not state.skills.major[skill.id] and not state.skills.minor[skill.id] then
            state.skills.misc[skill.id] = true
        end
    end
end

module.captureBaseSkills = function(state)
    if next(state.skills.baseValues) ~= nil then return end
    for skillId, getter in pairs(T.NPC.stats.skills) do
        state.skills.baseValues[skillId] = getter(self).base
    end
end

local function onSkillUsed(skillId, options)
    if not mS.mainStorage:get("modEnabled") then return end
    local s = module._state
    if not s or not s.isInitialized then return end

    local rate = mS.expStorage:get(getSkillType(s, skillId) .. "ExpRate") / 100

    if options.skillGain ~= nil then
        options.skillGain = options.skillGain * rate
    end
    if options.scale ~= nil then
        options.scale = options.scale * rate
    end
end

local function onSkillLevelUp(skillId, source, options)
    if not mS.mainStorage:get("modEnabled") then return end
    local s = module._state
    if not s or not s.isInitialized then return end

    -- take over level progression entirely
    options.levelUpProgress = 0
    options.levelUpAttribute = nil

    processDecay(s, skillId)

    local skillType = getSkillType(s, skillId)
    local rate = mS.skillsStorage:get(skillType .. "SkillRate") / 100
    local threshold = mS.skillsStorage:get(skillType .. "SkillThreshold")
    local skillLevel = T.NPC.stats.skills[skillId](self).base + (options.skillIncreaseValue or 1)

    if skillLevel >= threshold then
        if skillId == "acrobatics" then
            rate = rate * mS.mainStorage:get("acrobaticsMod") / 100
        end
        applyAttributeProgress(s, core.stats.Skill.records[skillId].attribute, rate)
    end

    local levelStat = T.Actor.stats.level(self)
    if skillType ~= "misc" then
        levelStat.progress = levelStat.progress + 1
    else
        s.miscSkillsRaised = s.miscSkillsRaised + 1
        local miscThr = mS.skillsStorage:get("miscLevelThreshold")
        if miscThr > 0 and s.miscSkillsRaised >= miscThr then
            s.miscSkillsRaised = 0
            levelStat.progress = levelStat.progress + 1
        end
    end

    if levelStat.progress > 200 then levelStat.progress = 0 end

    if levelStat.progress >= core.getGMST("iLevelupTotal") then
        module.autoLevelUp(s)
    end
end

function module.autoLevelUp(state)
    local levelStat = T.Actor.stats.level(self)
    levelStat.progress = 0
    levelStat.current = levelStat.current + 1

    ui.showMessage(core.getGMST("sLevelUpMsg"))
    local msg = levelUpMessages[math.min(math.max(levelStat.current, 2), 21)]
    if msg then ui.showMessage(msg) end
    ambient.streamMusic("Music/Special/MW_Triumph.mp3")

    applyLuckProgress(state, 0.1 * mS.mainStorage:get("luckPerLevel"))

    local hp = T.Actor.stats.dynamic.health(self)
    local gain
    if mS.mainStorage:get("alternateHealthSystem") then
        gain = mS.mainStorage:get("flatHealthPerLevel")
    else
        gain = math.floor(core.getGMST("fLevelUpHealthEndMult")
            * T.Actor.stats.attributes.endurance(self).base)
    end
    hp.base = hp.base + gain
    hp.current = hp.current + gain
end

module.addHandlers = function(state)
    module._state = state
    I.SkillProgression.addSkillUsedHandler(onSkillUsed)
    I.SkillProgression.addSkillLevelUpHandler(onSkillLevelUp)
end

return module
