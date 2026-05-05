local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local nearby = require("openmw.nearby")
local async = require("openmw.async")
local types = require("openmw.types")
local core = require("openmw.core")

local config = {
    checkInterval = 3,
    initialDelay = 1,
    maxCombatDistance = 3000,
    exclusionCheckDistance = 400
}

local aggroSounds = {
    "Sound\\Vo\\ord\\Atk_ORM001.mp3",
    "Sound\\Vo\\ord\\Atk_ORM002.mp3",
    "Sound\\Vo\\ord\\Atk_ORM003.mp3",
    "Sound\\Vo\\ord\\Atk_ORM004.mp3",
    "Sound\\Vo\\ord\\Atk_ORM005.mp3"
}

local function hasValidTempleRank(factionId, factionRank, isExpelled)
	if factionId:lower() == "temple" and factionRank >= 6 and not isExpelled then 
		return true 
	end

	return false
end

local armorProfiles = {
    ordinator = {
        cuirass = "indoril cuirass",
        pieces = {
            ["indoril cuirass"] = true, ["indoril helmet"] = true, ["indoril pauldron left"] = true,
            ["indoril pauldron right"] = true, ["indoril boots"] = true, ["indoril left gauntlet"] = true,
            ["indoril right gauntlet"] = true, ["indoril shield"] = true, ["indoril_belt"] = true,
            ["spirit of indoril"] = true, ["succour of indoril"] = true,
        },
        factionCheck = function(player)
            local factions = types.NPC.getFactions(player)
            for _, factionId in ipairs(factions or {}) do
		local factionRank = types.NPC.getFactionRank(player, factionId)
		local isExpelled = types.NPC.isExpelled(player, factionId)
                if hasValidTempleRank(factionId, factionRank, isExpelled) then return true end
            end
            return false
        end,
        questCheck = function(player)
            local quest = types.Player.quests(player)["b8_MeetVivec"]
            return quest and quest.stage >= 50
        end
    },
    herhand = {
        cuirass = "indoril_mh_guard_cuirass",
        pieces = {
            ["indoril_mh_guard_helmet"] = true, ["indoril_mh_guard_cuirass"] = true,
            ["indoril_mh_guard_pauldron_l"] = true, ["indoril_mh_guard_pauldron_r"] = true,
            ["indoril_mh_guard_greaves"] = true, ["indoril_mh_guard_boots"] = true,
            ["indoril_mh_guard_gauntlet_l"] = true, ["indoril_mh_guard_gauntlet_r"] = true,
            ["indoril_mh_guard_shield"] = true,
        },
        factionCheck = function(player)
            local factions = types.NPC.getFactions(player)
            for _, factionId in ipairs(factions or {}) do
		local factionRank = types.NPC.getFactionRank(player, factionId)
		local isExpelled = types.NPC.isExpelled(player, factionId)
                if hasValidTempleRank(factionId, factionRank, isExpelled) or factionId:lower() == "hands of almalexia" then return true end
            end
            return false
        end,
        questCheck = function(player)
            local q1 = types.Player.quests(player)["TR_MissingHand_01"]
            local q2 = types.Player.quests(player)["TR_MissingHand_02"]
            return (q1 and q1.stage or 0) >= 90 or (q2 and q2.stage or 0) >= 90
        end
    },
    handofalmalexia = {
        cuirass = "indoril_almalexia_cuirass",
        pieces = {
            ["indoril_almalexia_helmet"] = true, ["indoril_almalexia_cuirass"] = true,
            ["indoril_almalexia_pauldron_l"] = true, ["indoril_almalexia_pauldron_r"] = true,
            ["indoril_almalexia_greaves"] = true, ["indoril_almalexia_boots"] = true,
            ["indoril_almalexia_gauntlet_l"] = true, ["indoril_almalexia_gauntlet_r"] = true,
            ["indoril_almalexia_shield"] = true,
        },
        factionCheck = function(player)
            local factions = types.NPC.getFactions(player)
            for _, factionId in ipairs(factions or {}) do
                if factionId:lower() == "hands of almalexia" then return true end
            end
            return false
        end,
        questCheck = function(player)
            local q1 = types.Player.quests(player)["TR_MissingHand_01"]
            local q2 = types.Player.quests(player)["TR_MissingHand_02"]
            return (q1 and q1.stage or 0) >= 90 or (q2 and q2.stage or 0) >= 90
        end
    }
}

local previousPackage = nil
local scriptDrivenAggro = false

local function restorePreviousAI()
    ai.startPackage(previousPackage or {
        type = "Wander",
        cancelOther = true,
        duration = 20,
        distance = 1500
    })
    previousPackage = nil
end

local function hasArmorPiece(actor, armorSet)
    local equipped = types.Actor.equipment(actor)
    if not equipped then return false end
    for _, item in pairs(equipped) do
        if item and item.recordId and armorSet[item.recordId:lower()] then
            return true
        end
    end
    return false
end

local function hasCuirass(actor, cuirassId)
    local equipped = types.Actor.equipment(actor)
    if not equipped then return false end
    for _, item in pairs(equipped) do
        if item and item.recordId and item.recordId:lower() == cuirassId then
            return true
        end
    end
    return false
end

local function isInCombat()
    local pkg = ai.getActivePackage()
    return pkg and pkg.type == "Combat"
end

local function playerWearsHandArmor(player)
    return hasArmorPiece(player, armorProfiles.handofalmalexia.pieces)
end

local function isHandOfAlmalexia(player)
    return armorProfiles.handofalmalexia.factionCheck(player)
end

local function hasKilledSalasValor(player)
    local q1 = types.Player.quests(player)["TR_MissingHand_01"]
    local q2 = types.Player.quests(player)["TR_MissingHand_02"]
    return (q1 and q1.stage or 0) >= 90 or (q2 and q2.stage or 0) >= 90
end

local function npcAggroTemplate(profile)
    local player = nearby.players[1]
    if not player or not player.position or not player.cell or not self.cell then return end

    if isHandOfAlmalexia(player) or hasKilledSalasValor(player) then return end

    if self.cell.name ~= player.cell.name then
        if scriptDrivenAggro and isInCombat() then
            restorePreviousAI()
            scriptDrivenAggro = false
        end
        return
    end

    local distance = (self.position - player.position):length()
    if distance > config.maxCombatDistance then
        if scriptDrivenAggro and isInCombat() then
            restorePreviousAI()
            scriptDrivenAggro = false
        end
        return
    end
    if distance > config.exclusionCheckDistance then return end

    local violatesSacredArmor = false
    if playerWearsHandArmor(player) then
        violatesSacredArmor = true
    end

    if not isInCombat() and not violatesSacredArmor and (not hasCuirass(self, profile.cuirass) or profile.factionCheck(player) or profile.questCheck(player)) then
        return
    end

    if hasArmorPiece(player, profile.pieces) or violatesSacredArmor then
        if not isInCombat() then
            previousPackage = ai.getActivePackage()
            ai.startPackage({
                type = "Combat",
                target = player,
                cancelOther = true
            })
            scriptDrivenAggro = true

            local soundPath = aggroSounds[math.random(#aggroSounds)]
            core.sound.say(soundPath, self, "Where did you get that! The armor you wear is sacred to our Order. You shall be punished with blood!")
        end
    end
end

local function npcAggro_ordinator()
    async:newUnsavableSimulationTimer(config.checkInterval, npcAggro_ordinator)
    npcAggroTemplate(armorProfiles.ordinator)
end

local function npcAggro_herhand()
    async:newUnsavableSimulationTimer(config.checkInterval, npcAggro_herhand)
    npcAggroTemplate(armorProfiles.herhand)
end

local function npcAggro_handofalmalexia()
    async:newUnsavableSimulationTimer(config.checkInterval, npcAggro_handofalmalexia)
    npcAggroTemplate(armorProfiles.handofalmalexia)
end

local function initializeAggroByCuirass()
    local equipped = types.Actor.equipment(self)
    if not equipped then return end

    for _, item in pairs(equipped) do
        if item and item.recordId then
            local id = item.recordId:lower()
            if id == armorProfiles.ordinator.cuirass then
                async:newUnsavableSimulationTimer(config.initialDelay, npcAggro_ordinator)
                return
            elseif id == armorProfiles.herhand.cuirass then
                async:newUnsavableSimulationTimer(config.initialDelay, npcAggro_herhand)
                return
            elseif id == armorProfiles.handofalmalexia.cuirass then
                async:newUnsavableSimulationTimer(config.initialDelay, npcAggro_handofalmalexia)
                return
            end
        end
    end
end

initializeAggroByCuirass()