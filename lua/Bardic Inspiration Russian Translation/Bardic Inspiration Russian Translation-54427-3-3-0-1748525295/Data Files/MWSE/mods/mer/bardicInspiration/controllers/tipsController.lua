local common = require("mer.bardicInspiration.common")
local messages = require("mer.bardicInspiration.messages.messages")
local voiceLines = require("mer.bardicInspiration.data.voiceLines")

---@class (exact) BardicInspiration.TipsController
---@field tipTimer mwseTimer|nil
---@field totalTips number
---@field maxPatronDistance number
---@field previousVoiceLine string|nil
local TipsController = {
    totalTips = 0,
    maxPatronDistance = 2048,
    previousVoiceLine = nil,
}

function TipsController:_reset()
    self.tipTimer = timer.start{
        duration = self:_generateTipInterval(),
        iterations = 1,
        callback = function()
            self:_doTip()
        end
    }
end

-- Start tip timer
function TipsController:start()
    common.log:debug("\nStarting tip timer")
    self.tipTimer = nil
    self.totalTips = 0
    self:_reset()
end

-- Stop tip timer
function TipsController:stop()
    common.log:debug("Stopping tip timer\n")
    if self.tipTimer then
        self.tipTimer:cancel()
    end
end

-- Get total tips
function TipsController:getTotal()
    common.log:debug("Returning total tips: %d", self.totalTips)
    return self.totalTips
end

-- Internal: Generate tip interval based on skill/luck
function TipsController:_generateTipInterval()
    local luckEffect = math.remap(tes3.mobilePlayer.luck.current, 40, 100, 1.0, common.staticData.maxLuckTipIntervalEffect)
    luckEffect = math.clamp(luckEffect, common.staticData.maxLuckTipIntervalEffect, 1.0)
    local minInterval = common.staticData.baseTipInterval * luckEffect
    return math.random(minInterval, common.staticData.maxTipInterval)
end

local function randomNormal(mean, stddev)
    local u1 = math.random()
    local u2 = math.random()
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return mean + z0 * stddev
end

-- Internal: Determine tip quality
function TipsController:_determineTipQuality()
    local skill = common.skills.performance.value
    common.log:debug("Performance skill: %d", skill)
    local roll = randomNormal(skill, 35)
    common.log:debug("Tip roll: %d", roll)

    local quality
    if roll < 30 then
        quality = "bad"
    elseif roll < 70 then
        quality = "average"
    else
        quality = "good"
    end
    common.log:debug("Tip quality: %s", quality)
    return quality
end

-- Internal: Generate tip amount based on quality
function TipsController:_generateTipAmount(quality)
    local baseTip = common.staticData.baseTip
    local difficultyMulti = common.staticData.difficulties[common.data.currentSongDifficulty or "beginner"].tipMulti
    local skillMulti = math.remap(common.skills.performance.value, 0, 100, 0.5, common.staticData.maxSkillTipEffect)

    local amount = 0
    if quality == "good" then
        amount =  math.random(baseTip * 1.5, baseTip * 2.5) * skillMulti * difficultyMulti
    elseif quality == "average" then
        amount = math.random(baseTip * 0.5, baseTip * 1.5) * skillMulti * difficultyMulti
    end
    return math.ceil(amount)
end

-- Internal: Find a nearby NPC
function TipsController:_findNearbyNPC()
    local npcs = {}
    for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
        if ref ~= tes3.player and ref.position:distance(tes3.player.position) < self.maxPatronDistance then
            table.insert(npcs, ref)
        end
    end
    common.log:debug("Found %d nearby NPCs", #npcs)
    return (#npcs > 0) and table.choice(npcs) or nil
end

-- Internal: Generate tip message
function TipsController:_generateTipMessage(npcName, quality, amount)
    local messageTable = messages[quality .. "Tips"]
    local message = table.choice(messageTable) --[[@as string]]
    message = message:gsub("%%NPC", npcName):gsub("%%G", tostring(amount))
    return message
end

--For the given patron's race/gender, pick a random "flee" voice line
---@param npc tes3reference
function TipsController:_getVoiceLine(npc, quality)
    local qualityLines = voiceLines[quality]
    if not qualityLines then
        common.log:debug("No voice lines for quality: %s", quality)
        return nil
    end
    local race = npc.object.race.id:lower()
    local raceLines = qualityLines[race]
    if not raceLines then
        common.log:debug("No voice lines for race: %s", race)
        return nil
    end
    local sex = npc.object.female and "female" or "male"
    local sexLines = raceLines[sex]
    if not sexLines then
        common.log:debug("No voice lines for sex: %s", sex)
        return nil
    end
    local line = table.choice(sexLines)
    common.log:debug("Selected voice line: %s", line)
    if line == self.previousVoiceLine then
        common.log:debug("Duplicate voice line, selecting a new one")
        return self:_getVoiceLine(npc, quality)
    end
    self.previousVoiceLine = line
    return line
end

-- Internal: Perform the tip action
function TipsController:_doTip()
    local npc = self:_findNearbyNPC()
    if not npc then
        tes3.messageBox(messages.noNPCNearby)
        self:start()
        return
    end

    local quality = self:_determineTipQuality()
    local amount = self:_generateTipAmount(quality)

    if amount > 0 then
        tes3.addItem({ reference = tes3.player, item = "gold_001", count = amount })
        self.totalTips = self.totalTips + amount
    end

    local message = self:_generateTipMessage(npc.object.name, quality, amount)

    local voiceLine = self:_getVoiceLine(npc, quality)
    if voiceLine then
        tes3.say{
            reference = npc,
            soundPath = voiceLine,
        }
    end
    tes3.messageBox(message)

    common.log:debug("NPC %s gave a %s tip of %d gold", npc.object.name, quality, amount)

    self:_reset()
end


-- Stop timer on load event
local function clearOnLoad()
    TipsController:stop()
end

event.register("load", clearOnLoad)

return TipsController
