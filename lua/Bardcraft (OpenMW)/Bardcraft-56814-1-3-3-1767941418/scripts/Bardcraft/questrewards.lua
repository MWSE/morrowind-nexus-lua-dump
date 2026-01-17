local self = require('openmw.self')
local ui = require('openmw.ui')
local core = require('openmw.core')
local ambient = require('openmw.ambient')

local QuestRewards = require('scripts.Bardcraft.data.common').QuestRewards

local l10n = core.l10n('Bardcraft')

return {
    engineHandlers = {
        onQuestUpdate = function(questId, stage)
            local reward = QuestRewards[questId]
            if reward and reward.stage == stage then
                ui.showMessage(l10n(reward.msg))
                local item = reward.item
                core.sendGlobalEvent('BC_GiveItem', { item = item, actor = self })
                ambient.playSoundFile('sound/Fx/item/item.wav')
            end
        end
    }
}