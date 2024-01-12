--local mcm = require('scripts.imr_mcm')
local NPC = require('openmw.types').NPC
local storage = require('openmw.storage')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local I = require('openmw.interfaces')


-- GUILDS BONUSES
local mageGuildRanks = {
    {rank = 1, name = 'Associate', multiplier = 0.00},
    {rank = 2, name = 'Apprentice', multiplier = 0.02},
    {rank = 3, name = 'Journeyman', multiplier = 0.04},
    {rank = 4, name = 'Evoker', multiplier = 0.06},
    {rank = 5, name = 'Conjurer', multiplier = 0.8},
    {rank = 6, name = 'Magician', multiplier = 0.10},
    {rank = 7, name = 'Warlock', multiplier = 0.15},
    {rank = 8, name = 'Wizard', multiplier = 0.20},
    {rank = 9, name = 'Master Wizard', multiplier = 0.25},
    {rank = 10, name = 'Arch-Mage', multiplier = 0.30},
}

local telvanniGuildRanks = {
    {rank = 1, name = 'Hireling', multiplier = 0.00},
    {rank = 2, name = 'Retainer', multiplier = 0.02},
    {rank = 3, name = 'Oathman', multiplier = 0.04},
    {rank = 4, name = 'Lawman', multiplier = 0.06},
    {rank = 5, name = 'Mouth', multiplier = 0.08},
    {rank = 6, name = 'Spellwright', multiplier = 0.10},
    {rank = 7, name = 'Wizard', multiplier = 0.12},
    {rank = 8, name = 'Master', multiplier = 0.14},
    {rank = 9, name = 'Magister', multiplier = 0.16},
    {rank = 10, name = 'Archmagister', multiplier = 0.20},
}

local TempleGuildRanks = {
    {rank = 1, name = 'Layman', multiplier = 0.00},
    {rank = 2, name = 'Novice', multiplier = 0.02},
    {rank = 3, name = 'Initiate', multiplier = 0.04},
    {rank = 4, name = 'Acolyte', multiplier = 0.06},
    {rank = 5, name = 'Adept', multiplier = 0.08},
    {rank = 6, name = 'Curate', multiplier = 0.10},
    {rank = 7, name = 'Disciple', multiplier = 0.12},
    {rank = 8, name = 'Diviner', multiplier = 0.14},
    {rank = 9, name = 'Master', multiplier = 0.16},
    {rank = 10, name = 'Patriarch', multiplier = 0.20},
}

local ImperialCultGuildRanks = {
    {rank = 1, name = 'Layman', multiplier = 0.00},
    {rank = 2, name = 'Novice', multiplier = 2.5},
    {rank = 3, name = 'Initiate', multiplier = 2.8},
    {rank = 4, name = 'Acolyte', multiplier = 3.1},
    {rank = 5, name = 'Adept', multiplier = 3.4},
    {rank = 6, name = 'Disciple', multiplier = 3.7},
    {rank = 7, name = 'Oracle', multiplier = 4.0},
    {rank = 8, name = 'Invoker', multiplier = 4.3},
    {rank = 9, name = 'Theurgist', multiplier = 5.6},
    {rank = 10, name = 'Primate', multiplier = 5.0},
}

--Variables

local telvanniMultiplier = 0
local guildCounter = 0 -- Counter to check for guilds bonuses
local timeToCheckGuilds = 30 -- Periods to check for guilds bonuses

--Bonuses
local magesGuildBonus = 0
local telvanniGuildBonus = 1
local templeGuildBonus = 0
local ImperialCultGuildBonus = 0

--Settings
local settings = {
    main = storage.playerSection('NMRSettingsA'),
    additions = storage.playerSection('NMRSettingsB'),
    guilds = storage.playerSection('NMRSettingsGuildsPage'),
}
 

local function checkMagesGuildBonus()
    return magesGuildBonus
end
local function checkTelvanniBonus()
    return telvanniMultiplier
end
local function checkTempleBonus()
    return templeGuildBonus
end
local function checkCultBonus()
    return ImperialCultGuildBonus
end

--Checking for guilds and adjusting their bonuses

local function onUpdate(dt)
    --print(NPC.getFactionRank(self, "mages guild"))
    if settings.guilds:get('NMRGuildsMages') or settings.guilds:get('NMRGuildsTelvanni') or settings.guilds:get('NMRGuildsTemple') then
        guildCounter = guildCounter + 1
    end
        
    if guildCounter == timeToCheckGuilds then
        --Checking for Mages Guild ranks and multipliers
        if settings.guilds:get('NMRGuildsMages') then
            local playerMageRank = NPC.getFactionRank(self, "mages guild")
            if playerMageRank > 1 then
                for _, rankInfo in ipairs(mageGuildRanks) do
                    if playerMageRank == rankInfo.rank then
                        -- Print information based on the player's rank
                        magesGuildBonus = rankInfo.multiplier
                        --print('Mages Guild Rank:', rankInfo.name)
                        --print('Maximum Magicka to regenerate: +', rankInfo.multiplier , '%')
                        break  -- Stop iterating once the player's rank is found
                    end
                end
            end
        end
        --Checking for House Telvanni ranks and multipliers
        if settings.guilds:get('NMRGuildsTelvanni') then
            local playerTelvanniRank = NPC.getFactionRank(self, "telvanni")
            if playerTelvanniRank > 1 then
                for _, rankInfo in ipairs(telvanniGuildRanks) do
                    if playerTelvanniRank == rankInfo.rank then
                        telvanniMultiplier = 0
                        -- Print information based on the player's rank
                        telvanniGuildBonus = rankInfo.multiplier
                        telvanniMultiplier = telvanniMultiplier + telvanniGuildBonus
                        --print('House Telvanni Rank: ', rankInfo.name)
                        --print('Bonus speed to magicka regeneration: ', rankInfo.multiplier)
                        
                        break  -- Stop iterating once the player's rank is found
                    end
                end
            end
        end
        --Checking for Tribunal Temple ranks and multipliers
        if settings.guilds:get('NMRGuildsTemple') then
            local playerTribunalRank = NPC.getFactionRank(self, "temple")
            if playerTribunalRank > 1 and settings.additions:get('NMRFatigueMult') then
                for _, rankInfo in ipairs(TempleGuildRanks) do
                    if playerTribunalRank == rankInfo.rank then
                        -- Print information based on the player's rank
                        templeGuildBonus = rankInfo.multiplier
                        --print('Temple Rank: ', rankInfo.name)
                        --print('Fatigue influences Magicka regeneration less by : ', rankInfo.multiplier, '%')
                        break  -- Stop iterating once the player's rank is found
                    end
                end
            end
        end            
        guildCounter = 0
    end
end

return {
    engineHandlers = {
        dt = dt,
        onUpdate = onUpdate,
    },
    interfaceName = "IMRGUILDS",
    interface = {
        mageGuildRanks = mageGuildRanks,
        telvanniGuildRanks = telvanniGuildRanks,
        TempleGuildRanks = TempleGuildRanks,
        ImperialCultGuildRanks = ImperialCultGuildRanks,
        magesGuildBonus = checkMagesGuildBonus,
        telvanniGuildBonus = checkTelvanniBonus,
        templeGuildBonus = checkTempleBonus,
        ImperialCultGuildBonus = checkCultBonus, 
    },
    
}