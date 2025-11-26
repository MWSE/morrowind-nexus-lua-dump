local self = require('openmw.self')
local AI = require('openmw.interfaces').AI
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local I = require('openmw.interfaces')

local Performer = require('scripts.Bardcraft.performer')
local Data = require('scripts.Bardcraft.data')

local fleeTimer = 0

local lastRestockTime = nil
local lastRestockItems = {}

return {
    engineHandlers = {
        onSave = function()
            local data = Performer:onSave()
            data.lastRestockTime = lastRestockTime
            data.lastRestockItems = lastRestockItems
            return data
        end,
        onLoad = function(data)
            Performer:onLoad(data)
            if data then
                lastRestockTime = data.lastRestockTime
                lastRestockItems = data.lastRestockItems or {}
            end
        end,
        onActive = function()
            core.sendGlobalEvent('BC_HandleRestock', { actor = self, lastRestockTime = lastRestockTime, lastRestockItems = lastRestockItems })
            local bardInfo = Data.BardNpcs[self.recordId]
            if not bardInfo then return end
            local skillStat = I.SkillFramework.getSkillStat('bardcraft')
            if bardInfo.startingLevel and skillStat.base < bardInfo.startingLevel then
                skillStat.base = bardInfo.startingLevel
                skillStat.progress = 0
            end
            Performer:setSheathedInstrument(bardInfo.sheathedInstrument, true)
            if bardInfo.knownSongs then
                for _, info in ipairs(bardInfo.knownSongs) do
                    local song = Performer.getSongBySourceFile(info.song)
                    if song then
                        Performer:addKnownSong(song, info.confidences)
                    end
                end
            end
            Performer:resetAnim()
            Performer:resetVfx()
            Performer:setSheatheVfx()
            if bardInfo.home and self.cell.name == bardInfo.home.cell and #AI.getTargets('Follow') <= 0 then
                core.sendGlobalEvent('BC_SendHome', { actor = self })
            end
        end,
        onUpdate = function(dt)
            if dt == 0 then return end

            if Performer.playing and self.type.getStance(self) ~= self.type.STANCE.Nothing then
                core.sendGlobalEvent('BO_StopPerformance')
            end

            fleeTimer = math.min(fleeTimer + dt, 1)
            if fleeTimer < 1 then return end
            fleeTimer = 0

            if self.type.record(self).class ~= 'r_bc_bard' or self.type.isDead(self) or not self.type.isInActorsProcessingRange(self) then
                return
            end

            local currPackage = AI.getActivePackage()
            if not currPackage or currPackage.type ~= 'Combat' then
                self.type.stats.dynamic.health(self).current = util.clamp(self.type.stats.dynamic.health(self).current + 0.1, 0, self.type.stats.dynamic.health(self).base)
            end

            if AI.isFleeing() then
                for _, actor in pairs(nearby.actors) do
                    actor:sendEvent('BC_FleeingBard', { actor = self })
                end
            end
        end,
    },
    eventHandlers = {
        BO_ConductorEvent = function(data)
            Performer.handleConductorEvent(data)
        end,
        BC_ResetPerformer = function(data)
            Performer:resetAllStats()
        end,
        BC_ForgetSong = function(data)
            local id = data.id
            if id then
                Performer:forgetSong(id)
            end
        end,
        BC_ResetVFX = function()
            Performer:setSheatheVfx()
            if Performer.playing then
                Performer:resetVfx()
            end
        end,
        BC_RestockHandled = function(data)
            if data then
                lastRestockTime = data.lastRestockTime
                lastRestockItems = data.lastRestockItems or {}
            end
        end,
    }
}