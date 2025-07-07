local core = require('openmw.core')
local types = require('openmw.types')
local util = require('openmw.util')
local status, omwself = pcall(require, "openmw.self")
local status, nearby = pcall(require, "openmw.nearby")
local omwdebug = require("openmw.debug")

local fFightDispMult = core.getGMST("fFightDispMult")

-- Generic utility functions --

local module = {}

-- Helper print function
-- Author: mostly ChatGPT
local function uprint(...)
    local args = { ... }
    local lvl = args[#args]
    if type(lvl) ~= "number" then
        lvl = 1
    else
        table.remove(args)
    end
    if lvl <= DebugLevel then
        for i, v in ipairs(args) do
            args[i] = tostring(v)
        end
        local messageHeader = "[Mercy]"
        if omwself then messageHeader = messageHeader .. "[" .. omwself.recordId .. "]" end
        print(messageHeader .. ":", table.concat(args, " "))
    end
end
module.print = uprint

local function round(num, digits)
    local mult = 10^digits
    return util.round(num*mult)/mult
end
module.round = round

local function dtForLerp(dt, strength)
    return 1.0 - math.exp(-strength * dt)
end
module.dtForLerp = dtForLerp

local function foundInList(list, item)
    -- Author: ChatGPT 2024
    for _, value in ipairs(list) do
        if value == item then
            return true
        end
    end
    return false
end
module.foundInList = foundInList

local function stringToHash(str)
    -- Author: ChatGPT 2024
    local hash = 5381

    for i = 1, #str do
        local char = str:byte(i)
        hash = ((hash * 33) + char) % 2 ^ 32 -- Multiply by 33 and add ASCII value
    end

    return hash
end
module.stringToHash = stringToHash

local function tableToString(tbl, indent)
    indent = indent or "  "
    local result = { "\n===> " .. tostring(tbl) .. " <===" }

    for key, value in pairs(tbl) do
        local keyStr = tostring(key)
        local valueStr = tostring(value)
        table.insert(result, indent .. keyStr .. ": " .. valueStr)
    end

    return table.concat(result, "\n")
end
module.tableToString = tableToString

local function dialogRecordInfoToString(info)
    return "==== Dialog record info ===\n" ..
        "filterActorClass: " .. tostring(info.filterActorClass) .. "\n" ..
        "filterActorDisposition: " .. tostring(info.filterActorDisposition) .. "\n" ..
        "filterActorFaction: " .. tostring(info.filterActorFaction) .. "\n" ..
        "filterActorFactionRank: " .. tostring(info.filterActorFactionRank) .. "\n" ..
        "filterActorGender: " .. tostring(info.filterActorGender) .. "\n" ..
        "filterActorId: " .. tostring(info.filterActorId) .. "\n" ..
        "filterActorRace: " .. tostring(info.filterActorRace) .. "\n" ..
        "filterPlayerCell: " .. tostring(info.filterPlayerCell) .. "\n" ..
        "filterPlayerFaction: " .. tostring(info.filterPlayerFaction) .. "\n" ..
        "filterPlayerFactionRank: " .. tostring(info.filterPlayerFactionRank) .. "\n" ..
        "id: " .. tostring(info.id) .. "\n" ..
        "isQuestFinished: " .. tostring(info.isQuestFinished) .. "\n" ..
        "isQuestName: " .. tostring(info.isQuestName) .. "\n" ..
        "isQuestRestart: " .. tostring(info.isQuestRestart) .. "\n" ..
        "questStage: " .. tostring(info.questStage) .. "\n" ..
        "resultScript: " .. tostring(info.resultScript) .. "\n" ..
        "sound: " .. tostring(info.sound) .. "\n" ..
        "text: " .. tostring(info.text)
end
module.dialogRecordInfoToString = dialogRecordInfoToString

-- A sampler that retains samples within specified time window and calculates their mean value
-- Author: mostly ChatGPT
local MeanSampler = {}
function MeanSampler:new(time_window)
    -- Create a new object with initial properties
    local obj = {
        time_window = time_window,
        values = {},
        mean = 0,
        warmedUp = false
    }

    -- Define the sample function for the sampler instance
    function obj:sample(value)
        -- Get the current time
        local current_time = core.getRealTime()


        -- Add the new value and its timestamp to the values array
        table.insert(self.values, { time = current_time, value = value })

        -- Remove values that are older than the specified time window
        local i = 1
        while i <= #self.values do
            if current_time - self.values[i].time > self.time_window then
                table.remove(self.values, i)
            else
                i = i + 1
            end
        end

        self.warmedUp = self.values[#self.values].time - self.values[1].time > self.time_window * 0.75

        -- Calculate the mean of the remaining values
        local sum = nil
        for _, v in ipairs(self.values) do
            if sum then
                sum = sum + v.value
            else
                sum = v.value
            end
        end
        if #self.values > 0 then
            self.mean = sum / #self.values
        else
            self.mean = 0
        end
    end

    -- Set the metatable for the new object to use the class methods
    setmetatable(obj, self)
    self.__index = self

    return obj
end

module.MeanSampler = MeanSampler

local function shallowTableCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
module.shallowTableCopy = shallowTableCopy

local PosToVelSampler = {
    new = function(self, time_window)
        self.positionSampler = MeanSampler:new(time_window)
        self.velocitySampler = MeanSampler:new(time_window)
        self.time_window = time_window
        return self
    end,
    sample = function(self, pos)
        self.positionSampler:sample(pos)
        if #self.positionSampler.values - 1 > 0 then
            local lastPosSample = self.positionSampler.values[#self.positionSampler.values]
            local preLastPosSample = self.positionSampler.values[#self.positionSampler.values - 1]
            local velocity = (lastPosSample.value - preLastPosSample.value) /
                (lastPosSample.time - preLastPosSample.time)
            self.velocitySampler:sample(velocity)
        end
        self.warmedUp = self.velocitySampler.warmedUp
    end,
    mean = function(self)
        return self.velocitySampler.mean
    end
}
module.PosToVelSampler = PosToVelSampler

-- Function that mimics a ternary operator
-- Author: ChatGPT 2024
local function ternary(condition, if_true, if_false)
    if condition then
        return if_true
    else
        return if_false
    end
end
module.ternary = ternary

local function findField(dictionary, value)
    for field, val in pairs(dictionary) do
        if val == value then
            return field
        end
    end
    return nil
end
module.findField = findField

local function cache(fn, delay)
    delay = delay or 0.25 -- default delay is 0.25 seconds
    local lastExecution = 0
    local c1, c2 = nil, nil

    return function(...)
        local currentTime = core.getRealTime()
        if currentTime - lastExecution < delay then
            return c1, c2, "cached"
        end

        lastExecution = currentTime
        c1, c2 = fn(...)
        return c1, c2, "new"
    end
end
module.cache = cache


local function randomDirection()
    -- Author: ChatGPT 2024
    local angle = math.random() * 2 * math.pi
    return util.vector3(math.cos(angle), math.sin(angle), 0)
end
module.randomDirection = randomDirection

local function minHorizontalHalfSize(bounds)
    return math.abs(math.min(bounds.halfExtents.x, bounds.halfExtents.y))
end
module.minHorizontalHalfSize = minHorizontalHalfSize

local function diagonalFlatHalfSize(bounds)
    return util.vector2(bounds.halfExtents.x, bounds.halfExtents.y):length()
end
module.diagonalFlatHalfSize = diagonalFlatHalfSize

local function getActorLookRayPos(actor)
    local bounds = types.Actor.getPathfindingAgentBounds(actor)
    return actor.position + util.vector3(0, 0, bounds.halfExtents.z * 0.75)
end
module.getActorLookRayPos = getActorLookRayPos

local function getDistanceToBounds(actor, target)
    local dist = (target.position - actor.position):length() -
        types.Actor.getPathfindingAgentBounds(target).halfExtents.y -
        types.Actor.getPathfindingAgentBounds(actor).halfExtents.y;
    return dist;
end
module.getDistanceToBounds = getDistanceToBounds


local function lookDirection(actor)
    return actor.rotation:apply(util.vector3(0, 1, 0))
end
module.lookDirection = lookDirection

local function lerp(a, b, t)
    return a + (b - a) * t
end
module.lerp = lerp

local function lerpClamped(a, b, t)
    t = math.max(0, math.min(t, 1))
    return lerp(a, b, t)
end
module.lerpClamped = lerpClamped

local function getSign(val)
    if val == 0 then return 0 end
    return val / math.abs(val)
end
module.getSign = getSign


local function isMarksmanWeapon(weapon)
    if not weapon then return false end
    local weaponRecord = types.Weapon.record(weapon.recordId)
    return weaponRecord.type == types.Weapon.TYPE.MarksmanBow or
        weaponRecord.type == types.Weapon.TYPE.MarksmanCrossbow or
        weaponRecord.type == types.Weapon.TYPE.MarksmanThrown
end
module.isMarksmanWeapon = isMarksmanWeapon

local function isAShield(armor)
    if not armor then return false end
    local armorRecord = types.Armor.record(armor.recordId)
    if not armorRecord then return false end
    return armorRecord.type == types.Armor.TYPE.Shield
end
module.isAShield = isAShield


---- Actor class wrapper --------------------------------------------------------
local Actor = {}
Actor.__index = Actor
Actor.DET_STANCE = {
    Nothing = "Nothing",
    Spell = "Spell",
    Marksman = "Marksman",
    Melee = "Melee"
}

function Actor:new(go, omwClass)
    if not omwClass then omwClass = types.Actor end
    local instance = {
        gameObject = go,
        omwClass = omwClass
    }
    setmetatable(instance, self)
    return instance
end

function Actor:__index(key)
    local value = rawget(Actor, key)
    if value ~= nil then
        return value
    end

    value = self.omwClass[key]
    if type(value) == "function" then
        return function(_, ...)
            return value(self.gameObject, ...)
        end
    elseif type(value) == "table" or type(value) == "userdata" then
        return Actor:new(self.gameObject, value)
    else
        return value
    end
end


function Actor:getDumpableInventoryItems()
    -- data.actor, data.position
    local items = {}
    local inventory = self:inventory()
    --print("Inventory resolved:", inventory:isResolved())
    local invItems = inventory:getAll()

    for i, item in pairs(invItems) do
        if (types.Armor.objectIsInstance(item) or types.Clothing.objectIsInstance(item)) and self:hasEquipped(item) then goto continue end
        table.insert(items, item)
        ::continue::
    end

    return items
end

-- Archetype determining functions
function Actor:isVampire()
    -- Based on Urm's function
    local vampirism = self:activeEffects():getEffect('vampirism')
    local isVampire = not vampirism or vampirism.magnitude > 0
    return isVampire
end

local castingSkills = { "conjuration", "alteration", "destruction", "mysticism", "restoration" }
function Actor:isSpellCaster()
    if not types.NPC.objectIsInstance(self.gameObject) then return false end
    local className = types.NPC.record(self.gameObject.recordId).class
    local majorSkills = types.NPC.classes.record(className).majorSkills
    for _, skillName in ipairs(majorSkills) do
        if foundInList(castingSkills, skillName) then return true end
    end

    return self:isVampire()
end

function Actor:isMarksman()
    local weapons = self:inventory():getAll(types.Weapon)
    for i, weapon in pairs(weapons) do
        if isMarksmanWeapon(weapon) then return true end
    end
end

function Actor:isWarrior()
    return not self:isSpellCaster() and not self:isMarksman()
end

function Actor:getDetailedStance()
    local stance = self:getStance()
    if stance == types.Actor.STANCE.Nothing then
        return Actor.DET_STANCE.Nothing
    elseif stance == types.Actor.STANCE.Spell then
        return Actor.DET_STANCE.Spell
    elseif stance == types.Actor.STANCE.Weapon then
        local weapon = self:getEquipment(types.Actor.EQUIPMENT_SLOT.CarriedRight)
        if isMarksmanWeapon(weapon) then
            return Actor.DET_STANCE.Marksman
        else
            return Actor.DET_STANCE.Melee
        end
    end
end

function Actor:canOpenDoor(door)
    local canOpen = true
    if types.Lockable.isLocked(door) then
        canOpen = false
        local keyRecord = types.Lockable.getKeyRecord(door)
        local inventory = self:inventory()
        if keyRecord and inventory:find(keyRecord.id) then
            -- The door is locked, but actor has a key!
            canOpen = true
        end
    end
    return canOpen
end

function Actor:isParalyzed()
    -- Author: Capo
    local paralysis = self:activeEffects():getEffect(core.magic.EFFECT_TYPE.Paralyze)
    local paralyzed = not omwdebug.isGodMode() and paralysis and paralysis.magnitude > 0
    return paralyzed
end


module.Actor = Actor

--------------------------------------------------------------------------------



local function forEachNearbyActor(distLimit, cb)
    for _, actor in ipairs(nearby.actors) do
        local dist = (omwself.position - actor.position):length()
        if dist < distLimit then
            cb(actor)
        end
    end
end
module.forEachNearbyActor = forEachNearbyActor

local function getSortedAttackTypes(weaponRecord)
    if weaponRecord then
        local attacks = {
            { type = "Chop",   averageDamage = (weaponRecord.chopMinDamage + weaponRecord.chopMaxDamage) / 2 },
            { type = "Slash",  averageDamage = (weaponRecord.slashMinDamage + weaponRecord.slashMaxDamage) / 2 },
            { type = "Thrust", averageDamage = (weaponRecord.thrustMinDamage + weaponRecord.thrustMaxDamage) / 2 }
        }

        table.sort(attacks, function(a, b) return a.averageDamage > b.averageDamage end)

        return attacks
    else
        -- Assume this is hand-to-hand
        local attacks = {
            { type = "Chop",   averageDamage = 1 },
            { type = "Slash",  averageDamage = 1 },
            { type = "Thrust", averageDamage = 1 }
        }
        return attacks
    end
end

module.getSortedAttackTypes = getSortedAttackTypes

local function getGoodAttacks(attacks)
    local bestAttack = attacks[1]
    local goodAttacks = { bestAttack } -- Start with the best attack

    local threshold = 0.33             -- Threshold for damage difference

    for i = 2, #attacks do
        local currentAttack = attacks[i]
        local percentageDifference = math.abs(currentAttack.averageDamage - bestAttack.averageDamage) /
            bestAttack.averageDamage

        if percentageDifference <= threshold then
            table.insert(goodAttacks, currentAttack)
        else
            break -- No need to check further since attacks are sorted by averageDamage
        end
    end

    return goodAttacks
end

module.getGoodAttacks = getGoodAttacks

local function pickWeightedRandomAttackType(attacks)
    -- Author: ChatGPT 2024
    local totalAverageDamage = 0
    for _, attack in ipairs(attacks) do
        totalAverageDamage = totalAverageDamage + attack.averageDamage
    end

    local rand = math.random() * totalAverageDamage
    local cumulativeProbability = 0

    for _, attack in ipairs(attacks) do
        cumulativeProbability = cumulativeProbability + attack.averageDamage
        if rand <= cumulativeProbability then
            return attack
        end
    end

    return attacks[1]
end
module.pickWeightedRandomAttackType = pickWeightedRandomAttackType



local function getFightDispositionBias(omwself, enemyActor)
    local disposition = 50
    if types.NPC.objectIsInstance(omwself) and types.Player.objectIsInstance(enemyActor) then
        disposition = types.NPC.getDisposition(omwself, enemyActor)
    end
    return ((50 - disposition) * fFightDispMult);
end
module.getFightDispositionBias = getFightDispositionBias


local function imAGuard()
    local record = types.NPC.record(omwself)
    return record and record.class == "guard"
end
module.imAGuard = imAGuard


local targetsHistory = {}
local function addTargetsToHistory(targets)
    -- Author: mostly ChatGPT 2024
    local timeLimit = 5
    local now = core.getRealTime()
    for _, target in ipairs(targets) do
        targetsHistory[target] = now
    end
    for target, timestamp in pairs(targetsHistory) do
        if now - timestamp > timeLimit then
            targetsHistory[target] = nil
        end
    end
end
module.addTargetsToHistory = addTargetsToHistory

local function wasMyTarget(actor)
    return targetsHistory[actor]
end
module.wasMyTarget = wasMyTarget

local function isMyFriend(actor)
    local sameType = true
    if types.NPC.objectIsInstance(omwself) and not types.NPC.objectIsInstance(actor) then
        sameType = false
    end
    local fightVal = types.Actor.stats.ai.fight(actor)
    return actor.id ~= omwself.id and not types.Player.objectIsInstance(actor) and sameType and
        not wasMyTarget(actor) and fightVal.modified >= BaseFriendFightVal
end
module.isMyFriend = isMyFriend

local function stringStartsWith(String, Start)
    -- Source: https://stackoverflow.com/questions/22831701/lua-read-beginning-of-a-string
    -- Author: https://stackoverflow.com/users/542190/filmor
    return string.sub(String, 1, string.len(Start)) == Start
end

module.stringStartsWith = stringStartsWith

return module
