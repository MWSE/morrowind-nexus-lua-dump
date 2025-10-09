-- Global glue for inventory/disposition changes.
local types = require('openmw.types')
local core = require('openmw.core')

local settings = require('scripts.speechcraft_bribe.settings')

local function takeGold(player, amount)
  if amount <= 0 then return true end
  local inv = types.Actor.inventory(player)
  local have = inv:countOf(settings.goldRecordId) or 0
  if have < amount then return false end

  -- Find gold item and remove the specified amount
  local goldItem = inv:find(settings.goldRecordId)
  if goldItem then
    goldItem:remove(amount)
    return true
  end
  return false
end

local function applyDisposition(npc, player, delta)
  if delta == 0 then return end
  -- Only allowed in global scripts or on self
  types.NPC.modifyBaseDisposition(npc, player, delta)
end

return {
  eventHandlers = {
    SpeechcraftBribe_ApplyEffects = function(data)
      local npc = data.npc
      local player = data.player
      local goldTaken = math.max(0, math.floor(data.goldTaken or 0))
      local dispDelta = math.floor(data.dispDelta or 0)
      local message = data.message or ""

      local ok = true
      if goldTaken > 0 then
        ok = takeGold(player, goldTaken)
      end
      if not ok then
        player:sendEvent('ShowMessage', { message = "You do not have enough gold." })
        return
      end

      applyDisposition(npc, player, dispDelta)

      if message ~= "" then
        player:sendEvent('ShowMessage', { message = message })
      end
    end,
  },
}
