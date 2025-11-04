-- Stable release v1.7

-- Cualquier npc activo que tenga equipada la armadura "indoril cuirass", la armadura "Indoril_MH_Guard_Cuirass" o la armadura "Indoril_Almalexia_Cuirass", ataca al jugador, pero solo cuando el jugador se equipa alguna pieza de sus respectivas armaduras (Indoril, Her Hand o Hand of Almalexia) y se encuentra a cierta distancia.

-- Cuando el jugador escapa a cierta distancia, el npc atacante retorna a su rutina normal.

-- Si el player pertenece a la faccion "Temple" no sera atacado por los ordinators o los high ordinators.

-- Si el player pertenece a la faccion "Hands of Almalexia" no sera atacado por los Hands of Almalexia o los high ordinators. (solo mediante mods)

-- Si el player a sido reconocido por Vivec cono Nererine ("B8_MeetVivec >= 50"), no es atacado por los ordinators.

-- Si el player a matado a Salas Valor ("TR_MissingHand_01" >= 90 o "TR_MissingHand_02" >= 90), no es atacado por los high ordinators o los hand of almalexia. (equivaldria a ser admitido en los hands of almalexia, al tomar el lugar del traidor)

-- CAMBIOS:

-- ninguno

------------------------------------------------------------------------

-- 📦 Importación de módulos esenciales
local self = require("openmw.self")
local ai = require("openmw.interfaces").AI
local nearby = require("openmw.nearby")
local async = require("openmw.async")
local types = require("openmw.types")

-- ⚙️ Configuración centralizada de parámetros
local config = {
    checkInterval = 3,
    initialDelay = 1,
    maxCombatDistance = 3000,
    exclusionCheckDistance = 400
}

-- 🔊 Lista de audios de combate posibles
local aggroSounds = {
    "Sound\\Vo\\ord\\Atk_ORM001.mp3",
    "Sound\\Vo\\ord\\Atk_ORM002.mp3",
    "Sound\\Vo\\ord\\Atk_ORM003.mp3",
    "Sound\\Vo\\ord\\Atk_ORM004.mp3",
    "Sound\\Vo\\ord\\Atk_ORM005.mp3"
}

-- 🧩 Perfiles de armadura por tipo de NPC
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
                if factionId:lower() == "temple" then return true end
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
                local id = factionId:lower()
                if id == "temple" or id == "hands of almalexia" then return true end
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

-- 🔄 Restaurar paquete AI anterior
local function restorePreviousAI()
    ai.startPackage(previousPackage or {
        type = "Wander",
        cancelOther = true,
        duration = 20,
        distance = 1500
    })
    previousPackage = nil
end

-- 🧪 Verifica si el actor tiene alguna pieza de un set de armadura
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

-- 🧪 Verifica si el actor tiene equipada una coraza específica
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

-- 🔍 Verifica si el NPC está en combate
local function isInCombat()
    local pkg = ai.getActivePackage()
    return pkg and pkg.type == "Combat"
end

-- 🧩 Verifica si el jugador viste piezas de los Hands
local function playerWearsHandArmor(player)
    return hasArmorPiece(player, armorProfiles.handofalmalexia.pieces)
end

-- 🧩 Verifica si el jugador pertenece a los Hands
local function isHandOfAlmalexia(player)
    return armorProfiles.handofalmalexia.factionCheck(player)
end

-- 🧩 Verifica si el jugador ha matado a Salas Valor
local function hasKilledSalasValor(player)
    local q1 = types.Player.quests(player)["TR_MissingHand_01"]
    local q2 = types.Player.quests(player)["TR_MissingHand_02"]
    return (q1 and q1.stage or 0) >= 90 or (q2 and q2.stage or 0) >= 90
end

-- 🔧 Lógica principal de agresión por perfil
local function npcAggroTemplate(profile)
    local player = nearby.players[1]
    if not player or not player.position or not player.cell or not self.cell then return end

    -- 🛡️ Exclusión total si el jugador pertenece a los Hands o ha matado a Salas Valor
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

    -- ⚠️ Verificación especial: uso indebido de armadura de los Hands
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

            -- 🔊 Reproduce audio de agresión
            local soundPath = aggroSounds[math.random(#aggroSounds)]
            core.sound.say(soundPath, self, "Where did you get that! The armor you wear is sacred to our Order. You shall be punished with blood!")
        end
    end
end

-- 🔁 Ciclos de chequeo por tipo de NPC
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

-- 🚦 Inicializa el ciclo de chequeo según la coraza equipada por el NPC
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

-- 🚀 Activación inicial del script al cargar el NPC
initializeAggroByCuirass()