-- Applies in-game settings to Ancestor Ghost players (ghostly nature variant).

local types = require('openmw.types')
local config = require('scripts.ancestor_ghost.config')
local playerSettings = require('scripts.ancestor_ghost.player_settings')

local function stripLegacySpells(player)
  local spells = types.Actor.spells(player)
  for _, spellId in ipairs(config.LEGACY_GHOSTLY_NATURE_SPELLS) do
    if spells[spellId] then
      spells:remove(spellId)
    end
  end
  for _, spellId in ipairs(config.LEGACY_WRAITH_ABILITIES) do
    if spells[spellId] then
      spells:remove(spellId)
    end
  end
end

local function applyGhostlyNature(player, immunityMag, levitate, diseaseResist)
  local spells = types.Actor.spells(player)
  local target = config.ghostlyNatureSpellId(immunityMag, levitate, diseaseResist)
  for _, spellId in ipairs(config.GHOSTLY_NATURE_VARIANTS) do
    if spellId ~= target and spells[spellId] then
      spells:remove(spellId)
    end
  end
  if not spells[target] then
    spells:add(target)
  end
end

local function ghostlyNatureMatches(player, immunityMag, levitate, diseaseResist)
  local target = config.ghostlyNatureSpellId(immunityMag, levitate, diseaseResist)
  return types.Actor.spells(player)[target] ~= nil
end

-- Returns true when no further apply retries are needed.
local function applyToPlayer(player, settings)
  local rec = types.NPC.record(player)
  if not rec then return false end
  if rec.race ~= config.RACE_ID then return true end

  stripLegacySpells(player)
  settings = settings or playerSettings.readFromStorage()
  applyGhostlyNature(
    player,
    settings.normalWeaponsImmunity,
    settings.levitate,
    settings.diseaseResist
  )

  if not ghostlyNatureMatches(
    player,
    settings.normalWeaponsImmunity,
    settings.levitate,
    settings.diseaseResist
  ) then
    return false
  end
  return true
end

return {
  applyToPlayer = applyToPlayer,
}
