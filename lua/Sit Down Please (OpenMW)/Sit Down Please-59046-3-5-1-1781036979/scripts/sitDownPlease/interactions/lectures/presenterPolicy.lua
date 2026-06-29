-- interactions/lectures/presenterPolicy.lua
---@omw-context none
-- Vanilla faction/cell context rules for lecture presenters.

local M = {}

local function lower(value)
    return value and string.lower(tostring(value)) or ""
end

local function containsAny(text, needles)
    text = lower(text)
    for _, needle in ipairs(needles or {}) do
        if text:find(lower(needle), 1, true) then return true end
    end
    return false
end


local INN_LIKE_CELL_TOKENS = {
    "inn",
    "tavern",
    "tradehouse",
    "cornerclub",
    "public house",
    "strider's nest",
}

function M.cellLooksLikePublicInn(cellName)
    return containsAny(cellName, INN_LIKE_CELL_TOKENS)
end

local function lectureDebugOverride(ctx)
    return ctx and (ctx.calibrationAction == true or ctx.testingOverride == true or ctx.debugForce == true or ctx.targetStationObject ~= nil)
end

local RULES = {
    {
        faction = "mages guild",
        minRank = 4,
        trainerMinRank = 2,
        cell = { "mages guild", "guild of mages", "college", "conservatory" },
        class = { mage = true, sorcerer = true, battlemage = true, enchanter = true, healer = true, spellsword = true },
    },
    {
        faction = "telvanni",
        minRank = 4,
        trainerMinRank = 3,
        cell = { "telvanni", "tel ", "sadrith mora", "teloseras" },
        class = { mage = true, sorcerer = true, battlemage = true, enchanter = true, spellsword = true },
    },
    {
        faction = "temple",
        minRank = 4,
        trainerMinRank = 2,
        cell = { "temple", "ministry", "vivec", "ossuary", "shrine", "chapel", "holamayan", "ghostgate" },
        class = { priest = true, monk = true, healer = true, crusader = true, pilgrim = true },
    },
    {
        faction = "imperial cult",
        minRank = 4,
        trainerMinRank = 2,
        cell = { "imperial cult", "shrine", "chapel", "mission", "ebonheart", "fort" },
        class = { priest = true, monk = true, healer = true, missionary = true },
    },
    {
        faction = "fighters guild",
        minRank = 4,
        trainerMinRank = 2,
        cell = { "fighters guild", "guild of fighters", "training", "arena" },
        class = { drillmaster = true, ["master-at-arms"] = true, ["master at arms"] = true, warrior = true, knight = true, crusader = true },
    },
    {
        faction = "imperial legion",
        minRank = 4,
        trainerMinRank = 2,
        cell = { "legion", "fort", "imperial", "garrison" },
        class = { drillmaster = true, ["master-at-arms"] = true, ["master at arms"] = true, warrior = true, knight = true, guard = true },
    },
    {
        faction = "hlaalu",
        minRank = 4,
        trainerMinRank = 3,
        cell = { "hlaalu", "manor", "council", "balmora", "suran" },
        class = { noble = true, agent = true, merchant = true, trader = true, publican = true },
    },
    {
        faction = "redoran",
        minRank = 4,
        trainerMinRank = 3,
        cell = { "redoran", "manor", "council", "ald-ruhn", "maar gan" },
        class = { noble = true, crusader = true, knight = true, warrior = true },
    },
    {
        faction = "thieves guild",
        minRank = 5,
        trainerMinRank = 3,
        cell = { "thieves guild", "cornerclub", "club", "hideout" },
        class = { thief = true, agent = true, acrobat = true, scout = true },
    },
    {
        faction = "morag tong",
        minRank = 5,
        trainerMinRank = 3,
        cell = { "morag tong", "arena", "guildhall" },
        class = { assassin = true, agent = true, nightblade = true },
    },
    {
        faction = "ashlanders",
        minRank = 4,
        trainerMinRank = 2,
        cell = { "camp", "yurt", "ashlander", "ahemmusa", "erabenimsun", "urshilaku", "zainab" },
        class = { wise_woman = true, ["wise woman"] = true, scout = true, hunter = true, shaman = true },
    },
}

local function actorFactionRank(actor, factionId, typesApi)
    if not (actor and factionId and typesApi and typesApi.NPC and typesApi.NPC.getFactionRank) then return 0 end
    local ok, rank = pcall(typesApi.NPC.getFactionRank, actor, factionId)
    if ok then return tonumber(rank) or 0 end
    return 0
end

local function actorClassMatches(rec, rule)
    local cls = lower(rec and rec.class)
    if cls == "" then return false end
    return rule.class and rule.class[cls] == true
end

local function actorRuleAllowed(actor, rec, rule, ctx)
    local rank = actorFactionRank(actor, rule.faction, ctx.types)
    if rank <= 0 then return false, "wrong_faction" end
    local services = rec and rec.servicesOffered or nil
    local isTrainer = services and services.Training == true
    if rank >= (rule.minRank or 4) then return true, "rank_" .. tostring(rank) end
    if isTrainer and rank >= (rule.trainerMinRank or rule.minRank or 4) and actorClassMatches(rec, rule) then
        return true, "trainer_rank_" .. tostring(rank)
    end
    return false, "rank_too_low"
end

local function cellRules(cellName)
    local matches = {}
    for _, rule in ipairs(RULES) do
        if containsAny(cellName, rule.cell) then matches[#matches + 1] = rule end
    end
    return matches
end

function M.presenterAllowed(actor, rec, stationProfile, ctx)
    ctx = ctx or {}
    local cell = actor and actor.cell or ctx.cell
    local name = ctx.cellName and ctx.cellName(cell) or (cell and cell.name) or ""
    if M.cellLooksLikePublicInn(name) and not lectureDebugOverride(ctx) then
        return false, "station_inn_lectern_debug_only"
    end
    local rules = cellRules(name)
    if #rules == 0 then
        return false, "station_cell_context_unknown"
    end
    for _, rule in ipairs(rules) do
        local ok, reason = actorRuleAllowed(actor, rec, rule, ctx)
        if ok then return true, rule.faction .. ":" .. tostring(reason) end
    end
    return false, "station_wrong_faction_or_rank"
end

return M
