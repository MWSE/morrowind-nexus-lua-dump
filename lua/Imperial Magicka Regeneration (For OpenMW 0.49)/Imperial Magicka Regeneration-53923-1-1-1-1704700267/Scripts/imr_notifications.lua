local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local NPC = require('openmw.types').NPC
local async = require('openmw.async')
local guilds = require('scripts.imr_guilds')
local I = require("openmw.interfaces")
local ambient = require('openmw.ambient')

local soundParams = {
    timeOffset=0,
    volume=21,
    scale=false,
    pitch=1,
    loop=false,
 }

-- Getting mod settings
local settings = {
    main = storage.playerSection('NMRSettingsA'),
    additions = storage.playerSection('NMRSettingsB'),
    guilds = storage.playerSection('NMRSettingsGuildsPage'),
}
 
--Variables
local guildPopupCounter = 0
local guildPopupDelay = 10

local lastMagesGuildRank = NPC.getFactionRank(self, "mages guild")
local lastTelvanniRank = NPC.getFactionRank(self, "telvanni")
local lastTribunalRank = NPC.getFactionRank(self, "temple")
local lastImperialCultRank = NPC.getFactionRank(self, "imperial cult")


--Guilds ranks notifications
local function onFrame(dt)
    if settings.guilds:get('NMRGuildsMages') or settings.guilds:get('NMRGuildsTelvanni') or settings.guilds:get('NMRGuildsTemple') or settings.guilds:get('NMRGuildsImperialCult') then
        guildPopupCounter = guildPopupCounter + dt
        --print(guildCounter)
        end
        
        if guildPopupCounter >= guildPopupDelay then
            --Checking to Mages Guild ranks and multipliers
            if settings.guilds:get('NMRGuildsMages') then
                local playerMageRank = NPC.getFactionRank(self, "mages guild")
                if playerMageRank > lastMagesGuildRank then
                    if playerMageRank > 1 then
                        for _, rankInfo in ipairs(I.IMRGUILDS.mageGuildRanks) do
                            if playerMageRank == rankInfo.rank then
                                ui.showMessage("Mages Guild: You've been promoted to " .. rankInfo.name .. "\n\nYou can now regenerate an additional " .. rankInfo.multiplier*100 .. "% of your total Magicka.")
                                if settings.guilds:get('NMRGuildsSounds') then
                                    ambient.playSoundFile("Sound\\imr_notification_mages.mp3", soundParams)
                                end
                                break  -- Stop iterating once the player's rank is found
                            end
                        end
                    end
                    lastMagesGuildRank = playerMageRank
                end
            end

            --Checking to House Telvanni ranks and multipliers
            if settings.guilds:get('NMRGuildsTelvanni') then
                local playerTelvanniRank = NPC.getFactionRank(self, "telvanni")
                if playerTelvanniRank > lastTelvanniRank then
                    if playerTelvanniRank > 1 then
                        
                        for _, rankInfo in ipairs(I.IMRGUILDS.telvanniGuildRanks) do
                            if playerTelvanniRank == rankInfo.rank then
                                -- Print information based on the player's rank
                                ui.showMessage("House Telvanni: You've been promoted to " .. rankInfo.name .. "\n\nYour Magicka regeneration speed is increased by " .. rankInfo.multiplier*100 .. "%.")
                                if settings.guilds:get('NMRGuildsSounds') then
                                    ambient.playSoundFile("Sound\\imr_notification_telvanni.mp3", soundParams)
                                end
                                break  -- Stop iterating once the player's rank is found
                            end
                        end
                    end
                    lastTelvanniRank = playerTelvanniRank
                end
            end
            --Checking to Tribunal Temple ranks and multipliers
            if settings.guilds:get('NMRGuildsTemple') then
                local playerTribunalRank = NPC.getFactionRank(self, "temple")
                if playerTribunalRank > lastTribunalRank and settings.additions:get('NMRFatigueMult') then
                    if playerTribunalRank > 1 then
                        for _, rankInfo in ipairs(I.IMRGUILDS.TempleGuildRanks) do
                            if playerTribunalRank == rankInfo.rank then
                                    ui.showMessage("Tribunal Temple: You've been promoted to " .. rankInfo.name .. "\n\nYour Fatigue penalty to Magicka regeneration is reduced by " .. rankInfo.multiplier*100 .. "%.")
                                    if settings.guilds:get('NMRGuildsSounds') then
                                    ambient.playSoundFile("Sound\\imr_notification_temple.mp3", soundParams)
                                    end
                                break  -- Stop iterating once the player's rank is found
                            end
                        end
                    end
                    lastTribunalRank = playerTribunalRank
                end
            end

            if settings.guilds:get('NMRGuildsImperialCult') then
                local playerImperialRank = NPC.getFactionRank(self, "imperial cult")
                if playerImperialRank > lastImperialCultRank then
                    if playerImperialRank > 1 then
                        for _, rankInfo in ipairs(I.IMRGUILDS.ImperialCultGuildRanks) do
                            if playerImperialRank == rankInfo.rank then
                                    ui.showMessage("Imperial Cult: You've been promoted to " .. rankInfo.name .. "\n\nDivine Resilience: When your Health drops to 30%, your Magicka regenerates " .. rankInfo.multiplier*100 .. "% faster for 10 seconds.")
                                    if settings.guilds:get('NMRGuildsSounds') then
                                        ambient.playSoundFile("Sound\\imr_notification_cult.mp3", soundParams)
                                    end
                                break  -- Stop iterating once the player's rank is found
                            end
                        end
                    end
                    lastImperialCultRank = playerImperialRank
                end
            end

            guildPopupCounter = 0
        end
end

return {
    engineHandlers = {
        dt = dt,
        onFrame = onFrame,
    },
}