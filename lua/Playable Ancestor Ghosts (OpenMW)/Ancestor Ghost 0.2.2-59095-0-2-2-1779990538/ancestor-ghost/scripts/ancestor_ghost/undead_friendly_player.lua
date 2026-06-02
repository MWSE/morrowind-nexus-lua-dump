-- PLAYER script only: sync undead-friendly setting to the global pacify handler.

local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local config = require('scripts.ancestor_ghost.config')
local playerSettings = require('scripts.ancestor_ghost.player_settings')

local M = {}

function M.syncToGlobal()
  local enabled = false
  local rec = types.NPC.record(self)
  if rec and rec.race == config.RACE_ID then
    enabled = playerSettings.readFromStorage().undeadFriendly == true
  end
  core.sendGlobalEvent('AG_UndeadFriendlySync', { enabled = enabled })
end

return M
