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
  --print(questId)
end

return {
  eventHandlers = { showPlayerMsg = showPlayerMsg}
  }