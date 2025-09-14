local self = require('openmw.self')
local nearby = require('openmw.nearby')
local ui = require('openmw.ui')

local function showPlayerMsg(data)
  msg = data.msg
  ui.showMessage(msg)
end

local function setQuestStage(data)
  questId = data.questId
  questStage = data.questStage
  print(questId)
end

return {
    -- this fnc is for the LUA side to know that the Altar is ready for operation.
    engineHandlers = {
        onQuestUpdate = function(questId, stage)
          --print(questId)
          --checks if quest is finished
          if (questId == "aetherius_altar_quest" and stage >= 50) then
            
            for idx, item in pairs(nearby.activators) do
              --print(item.recordId)
              if (item.recordId == 'aetherius_altar_activator') then
                item:sendEvent('setEnableAltar', {source=self.object, stage=stage})
              end
            end
          end
        end
    },

  eventHandlers = { showPlayerMsg = showPlayerMsg,
                  playerPrice = playerPrice,
                  setQuestStage = setQuestStage,
                },
  }