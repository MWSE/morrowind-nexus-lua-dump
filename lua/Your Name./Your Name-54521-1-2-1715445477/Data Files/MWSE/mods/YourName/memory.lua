local this = {}
local logger = require("YourName.logger")

-- Creatures have many of the same names with different IDs, but we do not expect to mask them very well, so we will limit ourselves to important them only.
-- Persistence corpses are not included because there is basically no way to know their names.
local alias = {
    -- NPC
    ["hlaalu guard_outside"] = "hlaalu guard",           -- Hlaalu Guard
    ["redoran guard sarethi1"] = "redoran guard male",   -- Redoran Guard (dead)
    ["redoran guard sarethi2"] = "redoran guard male",   -- Redoran Guard (dead)
    ["redoran guard sarethi3"] = "redoran guard male",   -- Redoran Guard
    ["redoran guard sarethi4"] = "redoran guard female", -- Redoran Guard
    ["redoran guard_andasreth"] = "redoran guard male",  -- Redoran Guard (dead)
    ["telvanni guard_stand"] = "telvanni guard",         -- Telvanni Guard
    ["imperial guard_company"] = "imperial guard",       -- Guard
    ["imperial guard_ebonhear"] = "imperial guard",      -- Guard
    ["imperial guard_prisoner"] = "imperial guard",      -- Guard
    ["chargen boat guard 1"] = "imperial guard",         -- Guard
    ["chargen boat guard 2"] = "imperial guard",         -- Guard
    ["chargen boat guard 3"] = "imperial guard",         -- Guard
    ["chargen dock guard"] = "imperial guard",           -- Guard
    ["duke's guard_tomb"] = "duke's guard",              -- Duke's Guard
    ["duke's guard_tomb2"] = "duke's guard",             -- Duke's Guard
    ["ordinator stationary"] = "ordinator wander",       -- Ordinator
    ["ordinator_high fane"] = "ordinator wander",        -- Ordinator
    ["ordinator_wander_hvault"] = "ordinator wander",    -- Ordinator
    ["ordinator_wander_tvault"] = "ordinator wander",    -- Ordinator
    ["ordinator wander_hp"] = "ordinator wander",        -- Ordinator
    ["ordinator wander_ilpe_1"] = "ordinator wander",    -- Ordinator
    ["ordinator wander_ilpe_2"] = "ordinator wander",    -- Ordinator
    ["dreamer_f_01"] = "dreamer",                        -- Dreamer
    ["dreamer_02"] = "dreamer",                          -- Dreamer
    ["dreamer_f_key"] = "dreamer",                       -- Dreamer
    ["dreamer_ranged"] = "dreamer",                      -- Dreamer
    ["dreamer_04"] = "dreamer",                          -- Dreamer
    ["dreamer_05"] = "dreamer",                          -- Dreamer
    ["dreamer_06"] = "dreamer",                          -- Dreamer
    ["dreamer_talker"] = "dreamer",                      -- Dreamer
    ["dreamer_talker01"] = "dreamer",                    -- Dreamer
    ["dreamer_talker02"] = "dreamer",                    -- Dreamer
    ["dreamer_talker03"] = "dreamer",                    -- Dreamer
    ["dreamer_talker04"] = "dreamer",                    -- Dreamer
    ["dreamer_talker05"] = "dreamer",                    -- Dreamer
    ["dreamer_talker06"] = "dreamer",                    -- Dreamer
    ["dreamer_talker07"] = "dreamer",                    -- Dreamer
    ["dreamer_talker08"] = "dreamer",                    -- Dreamer
    ["dreamer_talker09"] = "dreamer",                    -- Dreamer
    ["dreamer_talker10"] = "dreamer",                    -- Dreamer
    ["dreamer_talker11"] = "dreamer",                    -- Dreamer
    ["dreamer_talker12"] = "dreamer",                    -- Dreamer
    ["db_assassin2"] = "db_assassin1",                   -- Assassin
    ["db_assassin3"] = "db_assassin1",                   -- Assassin
    ["db_assassin4"] = "db_assassin1",                   -- Assassin
    ["db_assassin1b"] = "db_assassin1",                  -- Assassin
    ["hels_assassin2"] = "hels_assassin1",               -- Assassin
    ["hels_assassin3"] = "hels_assassin1",               -- Assassin
    ["guard_helseth_attack"] = "guard_helseth",          -- Royal Guard
    ["royal guard_karrod"] = "guard_helseth",            -- Royal Guard
    ["skaal_guard2"] = "skaal_guard",                    -- Skaal Honor Guard
    ["skaal_guard_a1"] = "skaal_guard",                  -- Skaal Honor Guard
    ["skaal_guard_a2"] = "skaal_guard",                  -- Skaal Honor Guard
    ["skaal_guard_a3"] = "skaal_guard",                  -- Skaal Honor Guard
    ["skaal_guard_a4"] = "skaal_guard",                  -- Skaal Honor Guard
    ["skaal_hunter2"] = "skaal_hunter",                  -- Skaal Hunter
    ["skaal_tracker2"] = "skaal_tracker",                -- Skaal Tracker
    ["skaal_tracker3"] = "skaal_tracker",                -- Skaal Tracker
    ["bryngrim_b"] = "bryngrim",                         -- Bryngrim
    ["falx carius2"] = "falx carius",                    -- Captain Falx Carius
    ["tharsten heart-fang2"] = "tharsten heart-fang",    -- Tharsten Heart-Fang
    ["svenja_outside"] = "svenja snow-song",             -- Svenja Snow-Song
    ["thormoor_thirsk"] = "thormoor gray-wave",          -- Thormoor Gray-Wave
    ["thormoor_out"] = "thormoor gray-wave",             -- Thormoor Gray-Wave
    -- creature
    ["ancestor_ghost_vabdas"] = "mansilamat vabdas",     -- Mansilamat Vabdas
    ["dagoth_ur_2"] = "dagoth_ur_1",                     -- Dagoth Ur
    ["almalexia_warrior"] = "almalexia",                 -- Almalexia
    ["glenmoril_witch_cave"] = "glenmoril_raven",        -- Ettiene of Glenmoril Wyrd
    ["glenmoril_witch_altar"] = "glenmoril_raven",       -- Ettiene of Glenmoril Wyrd
    ["glenmoril_witch_altar_2"] = "glenmoril_raven",     -- Ettiene of Glenmoril Wyrd
    ["glenmoril_raven_cave"] = "glenmoril_raven",        -- Ettiene of Glenmoril Wyrd
    ["bm_hircine2"] = "bm_hircine",                      -- Hircine
}

---@class Record
---@field mask integer
---@field lastAccess number

---@class Memory
---@field records {[string]: Record}
local mockData = {
    records = {},
}

-- get aliased id
---@param id string
function this.GetAliasedID(id)
    local a = alias[id]
    if a ~= nil then
        logger:debug("%s alias to %s", id, a)
        return a
    end
    return id
end

---@return Memory
function this.GetMemory()
    if tes3.player and tes3.player.data then
        if tes3.player.data.yourName == nil then
            tes3.player.data.yourName = { records = {} } ---@type Memory
        end
        return tes3.player.data.yourName
    end
    logger:trace("Fallback mock memory")
    return mockData
end

---@return boolean
function this.ClearMemory()
    if tes3.player and tes3.player.data then
        if tes3.player.data.yourName ~= nil then
            tes3.player.data.yourName = nil
            logger:info("Clear Memory")
            return true
        end
        return false
    end
    mockData = {
        records = {},
    }
    logger:trace("Clear mocked memory")
    return false
end

---@param id string
---@return Record? record
function this.ReadMemory(id)
    id = this.GetAliasedID(id)
    local memory = this.GetMemory()
    local record = memory.records[id]
    if record ~= nil then
        logger:trace("Read: %s = %x", id, record.mask)
        return record
    end
    logger:trace("Read: %s does not exist", id)
    return nil
end

---@param id string
---@param mask integer
---@param timestamp number
---@return boolean newrecord
function this.WriteMemory(id, mask, timestamp)
    local memory = this.GetMemory()
    id = this.GetAliasedID(id)
    local record = memory.records[id]
    if record ~= nil then
        logger:trace("Update: %s = %x", id, mask)
        record.mask = mask
        record.lastAccess = timestamp
        return false
    else
        logger:trace("New: %s = %x", id, mask)
        memory.records[id] = { mask = mask, lastAccess = timestamp }
        return true
    end
end

---@param speechcraft number
---@param personality number
---@param luck number
---@param fatigueTerm number
---@return number
local function RememberingTerm(speechcraft, personality, luck, fatigueTerm)
    local speechcraftTerm = speechcraft * 1.0
    local personalityTerm = personality * 0.2
    local luckTerm = luck * 0.1
    return (speechcraftTerm + personalityTerm + luckTerm) * fatigueTerm
end

-- day
this.minTerm = 7
this.maxTerm = 240
---@param speechcraft number
---@param personality number
---@param luck number
---@param fatigueTerm number
---@return number
function this.CalculateRememberingTerm(speechcraft, personality, luck, fatigueTerm)
    local fatigueBase = tes3.findGMST(tes3.gmst.fFatigueBase).value --[[@as number]]
    local fatigueMult = tes3.findGMST(tes3.gmst.fFatigueMult).value --[[@as number]]
    local minimum = RememberingTerm(5, 40, 40, math.max(0, fatigueBase - fatigueMult))
    local maximum = RememberingTerm(100, 100, 100, math.max(0, fatigueBase))
    local current = RememberingTerm(speechcraft, personality, luck, fatigueTerm)
    logger:trace("Remenbering ratio: (speechcraft %d, personality %d, luck %d, fatigueTerm %f) = %f (%f ~ %f)",
        speechcraft, personality, luck, fatigueTerm, current, minimum, maximum)
    -- linear to forgetting curve
    -- This equation is an inversion of the simplified forgetting curve with the time axis replaced by the skill axis.
    -- It lacks evidence, but is easy to handle because it passes through 0 when the skill is 0 and goes to asymptotically of 1.
    -- https://en.wikipedia.org/wiki/Forgetting_curve#Equations
    -- [0, m] -> [min, max]
    local m = 1.0
    local s = 0.7
    local x = math.remap(current, minimum, maximum, 0, m)
    local curve = 1.0 - math.exp(-x / s)
    logger:trace("Forgetting curve: %f", curve)
    local term = math.max(math.remap(curve, 0, 1, this.minTerm, this.maxTerm), 0) -- day
    logger:trace("Remembering Term: %f", term)
    return term
end

---@param mobile tes3mobileNPC
---@param record Record
---@return boolean
function this.TryRemember(mobile, record)
    local remember = this.CalculateRememberingTerm(mobile.speechcraft.current, mobile.personality.current,
        mobile.luck.current, mobile:getFatigueTerm())
    local now = tes3.getSimulationTimestamp()
    local interval = now - record.lastAccess
    interval = interval / 24 -- hour to day
    logger:debug("Interval: %f, Remember: %f", interval, remember)
    return interval <= remember
end

return this
