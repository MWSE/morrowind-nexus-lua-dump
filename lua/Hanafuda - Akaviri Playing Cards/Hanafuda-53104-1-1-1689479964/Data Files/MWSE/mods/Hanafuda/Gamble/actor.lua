---@class Gamble.Actor
local this = {}
local logger = require("Hanafuda.logger")
local special = require("Hanafuda.Gamble.special")
local settings = require("Hanafuda.Gamble.settings")
local i18n = mwse.loadTranslations("Hanafuda")

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return boolean
function this.CanBarter(mobile)
    local ai = mobile.object.aiConfig
    local barters = {
        "bartersAlchemy",
        "bartersApparatus",
        "bartersArmor",
        "bartersBooks",
        "bartersClothing",
        "bartersEnchantedItems",
        "bartersIngredients",
        "bartersLights",
        "bartersLockpicks",
        "bartersMiscItems",
        "bartersProbes",
        "bartersRepairTools",
        "bartersWeapons",
    }
    for _, value in ipairs(barters) do
        if ai[value] == true then
            return true
        end
    end
    return false
end

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return integer
function this.GetActorGold(mobile)
    local gold = math.max(mobile.barterGold, 0)

    local goldId = {
        ["Gold_001"] = true,
        ["Gold_005"] = true,
        ["Gold_010"] = true,
        ["Gold_025"] = true,
        ["Gold_100"] = true,
    }

    local items = mobile.inventory
    for _, item in ipairs(items) do
        if goldId[item.object.id] then
            gold = gold + item.object.value * math.abs(item.count) -- possible negative
        end
    end
    return gold
end

---@param mobile tes3mobileActor
---@return boolean
local function ActorHasServiceMenu(mobile)
    if mobile.isDead then
        return false
    end
    return true
end

---@param mobile tes3mobileNPC
local function HasServiceMenuByClass(mobile)
    local classes = {
        -- pc and npc classes
        ["acrobat"] = false,
        ["agent"] = false, -- speechcraft is good
        ["archer"] = false,
        ["assassin"] = false,
        ["barbarian"] = false,
        ["bard"] = true,
        ["battlemage"] = false,
        ["crusader"] = false,
        ["healer"] = false,
        ["knight"] = false,
        ["mage"] = false,
        ["monk"] = false,
        ["nightblade"] = false,
        ["pilgrim"] = false,
        ["rogue"] = true,
        ["scout"] = false,
        ["sorcerer"] = false,
        ["spellsword"] = false,
        ["thief"] = true,
        ["warrior"] = false,
        ["witchhunter"] = false,
        -- npc only classes
        ["alchemist"] = false,
        ["apothecary"] = false,
        ["bookseller"] = true,
        ["buoyant armiger"] = false,
        ["caravaner"] = false,
        ["champion"] = false,
        ["clothier"] = false,
        ["commoner"] = false,
        ["dreamer"] = false,
        ["drillmaster"] = false,
        ["enchanter"] = false,
        ["enforcer"] = false,
        ["farmer"] = false,
        ["gondolier"] = false,
        ["guard"] = false,
        ["guild guide"] = false,
        ["herder"] = false,
        ["hunter"] = false,
        ["mabrigash"] = false,
        ["master-at-arms"] = false,
        ["merchant"] = true,
        ["miner"] = false,
        ["necromancer"] = false,
        ["noble"] = false,
        ["ordinator"] = false,
        ["ordinator guard"] = false,
        ["pauper"] = false,
        ["pawnbroker"] = true,
        ["priest"] = false,
        ["publican"] = true,
        ["savant"] = true,
        ["sharpshooter"] = false,
        ["shipmaster"] = false,
        ["slave"] = false,
        ["smith"] = false,
        ["smuggler"] = true,
        ["trader"] = true,
        ["warlock"] = false,
        ["wise woman"] = false,
        ["witch"] = false,
        -- tribunals
        ["caretaker"] = false,
        ["gardener"] = false,
        ["journalist"] = false,
        ["king"] = false,
        ["queen mother"] = false,
        -- bloodmoon
        ["shaman"] = false,
        -- mod
        ["gambler"] = true,
    }
    -- modded class?
    local class = mobile.object.class.id:lower()
    logger:debug("npc class: " .. class)
    local v = classes[class]
    if v == nil then
        -- Some classes have service as a suffix, so look for it by forward matching.
        -- It may be easier to support mods than to cover them all in a table.
        for key, value in pairs(classes) do
            if class:startswith(key) then
                v = value
                break
            end
        end
    end
    return (v == nil) or (v == true) -- ignored only false
end

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return boolean
function this.HasServiceMenu(player, opponent)
    if not ActorHasServiceMenu(opponent) then
        logger:debug("service is not allowed opponent condition")
        return false
    end

    local types = {
        [tes3.actorType.creature] =
        ---@param a tes3mobileCreature
        ---@return boolean
            function(a)
                if not special.IsAllowdCreature(a) then
                    logger:debug("service is not allowed creature")
                    return false
                end
                return true
            end,
        [tes3.actorType.npc] =
        ---@param a tes3mobileNPC
        ---@return boolean
            function(a)
                if special.IsAllowdNPC(a) then
                    logger:debug("service allowd by special npc")
                    return true
                end
                if not HasServiceMenuByClass(a) then
                    logger:debug("service is not allowd by class")
                    return false
                end
                return true
            end,
        [tes3.actorType.player] =
        ---@param a tes3mobilePlayer
        ---@return boolean
            function(a)
                -- possible?
                return false
            end,
    }
    if types[opponent.actorType] then
        return types[opponent.actorType](opponent)
    end
    return false
end

---@param mobile tes3mobileActor
---@return boolean
---@return string? -- reason
local function ActorCanPerformService(mobile)
    local condition = {
        -- "attacked", -- seems inconvinient flag
        "inCombat",
        "isAttackingOrCasting",
        "isDead",
        "isDiseased",
        "isFlying",
        "isJumping",
        "isKnockedDown",
        "isKnockedOut",
        "isParalyzed",
        "isPlayerHidden",
        "isReadyingWeapon",
        "isSneaking",
        "isSwimming",
        "weaponDrawn", -- weaponReady, castReady?
    }
    for _, value in ipairs(condition) do
        if mobile[value] then
            logger:trace(value)
            return false, value
        end
    end
    return true
end

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileCreature|tes3mobileNPC
---@return boolean
local function CanPerformServiceByFight(player, opponent)
    -- May be varied by any factor. 30~80
    local baseFight = settings.fightThreshold.base
    local threshold = baseFight
    return opponent.fight <= threshold
end

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileNPC
---@return boolean
local function CanPerformServiceByDisposition(player, opponent)
    -- May be varied by any factor.
    local baseDisposition = settings.dispositionThreshold.base
    local threshold = baseDisposition
    return opponent.object.disposition >= threshold
end

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileNPC
---@return boolean
local function CanPerformServiceByFaction(player, opponent)
    local faction = opponent.object.faction
    if faction then

        local factions = {
            ["ashlanders"] =
            ---@return boolean
                function()
                    return faction.playerJoined
                end,
            ["blades"] =
            ---@return boolean
                function()
                    return faction.playerJoined
                end,
            ["clan aundae"] =
            ---@return boolean
                function()
                    return player.hasVampirism
                end,
            ["clan berne"] =
            ---@return boolean
                function()
                    return player.hasVampirism
                end,
            ["clan quarra"] =
            ---@return boolean
                function()
                    return player.hasVampirism
                end,
            ["hlaalu"] =
            ---@return boolean
                function()
                    if faction.playerJoined and not faction.playerExpelled then
                        return (faction.playerRank + settings.factionRankBias) >= opponent.object.baseObject.factionRank
                    end
                    return false
                end,
            ["morag tong"] =
            ---@return boolean
                function()
                    return faction.playerJoined and not faction.playerExpelled
                end,
            ["redoran"] =
            ---@return boolean
                function()
                    if faction.playerJoined and not faction.playerExpelled then
                        return (faction.playerRank + settings.factionRankBias) >= opponent.object.baseObject.factionRank
                    end
                    return false
                end,
            ["telvanni"] =
            ---@return boolean
                function()
                    if faction.playerJoined and not faction.playerExpelled then
                        return (faction.playerRank + settings.factionRankBias) >= opponent.object.baseObject.factionRank
                    end
                    return false
                end,
        }
        local id = faction.id:lower()
        if factions[id] then
            return factions[id]()
        end
    end
    return true
end

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer?
---@param opponent tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer?
---@return boolean -- can perform
---@return string? -- reason
---@return boolean? -- byOpponent
function this.CanPerformService(player, opponent)
    if player == nil or opponent == nil then
        return false, nil, nil
    end

    local condition, reason = ActorCanPerformService(player)
    if not condition then
        logger:trace("not perform by player condition")
        return condition, reason, false
    end
    condition, reason = ActorCanPerformService(opponent)
    if not condition then
        logger:trace("not perform by opponent condition")
        return condition, reason, true
    end
    if not CanPerformServiceByFight(player, opponent) then
        logger:trace("not perform by fight")
        return false, "fight", true
    end

    local types = {
        [tes3.actorType.creature] =
        ---@param a tes3mobileCreature
        ---@return boolean
        ---@return string?
        ---@return boolean?
            function(a)
                -- no disposition
                return true
            end,
        [tes3.actorType.npc] =
        ---@param a tes3mobileNPC
        ---@return boolean
        ---@return string?
        ---@return boolean?
            function(a)
                if not CanPerformServiceByFaction(player, a) then
                    logger:trace("not perform by faction")
                    return false, "faction", true
                end
                if not CanPerformServiceByDisposition(player, a) then
                    logger:trace("not perform by disposition")
                    return false, "disposition", true
                end
                return true
            end,
        [tes3.actorType.player] =
        ---@param a tes3mobilePlayer
        ---@return boolean
        ---@return string?
        ---@return boolean
            function(a)
                -- possible?
                return false, nil, false
            end,
    }
    if types[opponent.actorType] then
        return types[opponent.actorType](opponent)
    end
    return false, nil, nil
end

---@param reason string
---@param name string
---@return string?
function this.GetRefusedReasonText(reason, name)
    local condition = {
        ["attacked"] = "gamble.refusedReason.combat",
        ["inCombat"] = "gamble.refusedReason.combat",
        ["isAttackingOrCasting"] = "gamble.refusedReason.combat",
        ["isDead"] = "gamble.refusedReason.dead",
        ["isDiseased"] = "gamble.refusedReason.diseased",
        ["isFlying"] = "gamble.refusedReason.floating",
        ["isJumping"] = "gamble.refusedReason.floating",
        ["isKnockedDown"] = "gamble.refusedReason.knocked",
        ["isKnockedOut"] = "gamble.refusedReason.knocked",
        ["isParalyzed"] = "gamble.refusedReason.paralyzed",
        ["isPlayerHidden"] = "gamble.refusedReason.hidden",
        ["isReadyingWeapon"] = "gamble.refusedReason.combat",
        ["isSneaking"] = "gamble.refusedReason.sneaking",
        ["isSwimming"] = "gamble.refusedReason.swimming",
        ["weaponDrawn"] = "gamble.refusedReason.combat",
        ["fight"] = "gamble.refusedReason.fight",
        ["faction"] = "gamble.refusedReason.faction",
        ["disposition"] = "gamble.refusedReason.disposition",
    }
    local key = condition[reason]
    if key then
        return i18n(key, {name = name})
    end
    return nil -- or fallback text
end

-- fate
---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return number
function this.CalculateLucky(mobile)
    return settings.CalculateAbility(mobile, settings.luckyAbility)
end

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return number
function this.CalculateCheatAbility(mobile)
    return settings.CalculateAbility(mobile, settings.cheatAbility)
end

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return number
function this.CalculateSpotAbility(mobile)
    return settings.CalculateAbility(mobile, settings.spotAbility)
end

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return number
function this.CalculateGreedy(mobile)
    return settings.CalculateAbility(mobile, settings.greedyAbility)
end

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return number
function this.CalculateGambleAbility(mobile)
    return settings.CalculateAbility(mobile, settings.gambleAbility)
end

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return number
function this.CalculateBettingAbility(mobile)
    return settings.CalculateAbility(mobile, settings.bettingAbility)
end

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return number
function this.CalculateBettingOddsModifier(player, opponent)
    local playerBetting = this.CalculateBettingAbility(player) * settings.bettingModifier -- [0, 1] * mod
    local opponentBetting = this.CalculateBettingAbility(opponent) * settings.bettingModifier -- [0, 1] * mod
    local dispositionModifier = 0
    if opponent.actorType == tes3.actorType.npc then
        local disposition = math.clamp(opponent.object.disposition, 0, 100)
        local range = settings.bettingDispositionRange
        dispositionModifier = math.remap(disposition, range.current.min, range.current.max, range.out.min, range.out.max) -- [-params, params]
    end
    local bettingModifier = dispositionModifier + playerBetting - opponentBetting -- [-1, 1] * mod + disposition
    bettingModifier = math.clamp(bettingModifier, -1, 1)
    bettingModifier = 1 + bettingModifier -- [0, 2]
    logger:debug("playerBetting %f", playerBetting)
    logger:debug("opponentBetting %f", opponentBetting)
    logger:debug("dispositionModifier %f", dispositionModifier)
    logger:debug("Betting Modifier %f", bettingModifier)
    return bettingModifier
end

---@param mobile tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
function this.GetAIBrain(mobile)
    local gamble = this.CalculateGambleAbility(mobile)
    local greedy = this.CalculateGreedy(mobile)
    logger:debug("gamble %f, greedy %f", gamble, greedy)
    local params = settings.CalculateRandomBrainParams(gamble, greedy)
    params.logger = logger
    local brain = require("Hanafuda.KoiKoi.brain.randomBrain").new(params)
    return brain
end

return this
