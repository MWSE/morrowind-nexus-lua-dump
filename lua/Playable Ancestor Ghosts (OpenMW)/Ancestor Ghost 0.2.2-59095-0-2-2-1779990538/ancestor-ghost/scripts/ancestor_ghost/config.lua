-- Shared IDs (must match tools/build_esp.mjs).

local M = {
  RACE_ID = 'ancestor_ghost',

  settingsPageKey = 'AncestorGhost',
  settingsGroupKey = 'SettingsAncestorGhost',
  settingNormalWeaponsKey = 'normalWeaponsImmunity',
  settingLevitateKey = 'ghostlyLevitate',
  settingDiseaseResistKey = 'commonDiseaseImmunity',
  settingUndeadFriendlyKey = 'undeadFriendly',
  settingDefaults = {
    normalWeaponsImmunity = 100,
    ghostlyLevitate = false,
    commonDiseaseImmunity = true,
    undeadFriendly = false,
  },

  LEGACY_WRAITH_ABILITIES = {
    'ag_wraith',
  },

  LEGACY_GHOSTLY_NATURE_SPELLS = {
    'ag_ghostly_nature',
    'ag_immunity_norm_100',
    'ag_immunity_norm_50',
    'ag_ghostly_nature_100',
    'ag_ghostly_nature_50',
    'ag_ghostly_nature_0',
    'ag_ghostly_nature_100_lev',
    'ag_ghostly_nature_100_ground',
    'ag_ghostly_nature_50_lev',
    'ag_ghostly_nature_50_ground',
    'ag_ghostly_nature_0_lev',
    'ag_ghostly_nature_0_ground',
  },
}

function M.ghostlyNatureSpellId(immunityMag, levitate, diseaseResist)
  local mag = immunityMag
  if mag ~= 0 and mag ~= 50 then
    mag = 100
  end
  local levSuffix = levitate and '_lev' or '_ground'
  local disSuffix = diseaseResist and '_dis' or '_nodis'
  return ('ag_ghostly_nature_%d%s%s'):format(mag, levSuffix, disSuffix)
end

-- Twelve Ghostly Nature abilities: immunity (100/50/0) × levitate × disease resist.
M.GHOSTLY_NATURE_VARIANTS = {}
for _, mag in ipairs({ 100, 50, 0 }) do
  for _, levitate in ipairs({ true, false }) do
    for _, diseaseResist in ipairs({ true, false }) do
      M.GHOSTLY_NATURE_VARIANTS[#M.GHOSTLY_NATURE_VARIANTS + 1] =
        M.ghostlyNatureSpellId(mag, levitate, diseaseResist)
    end
  end
end

return M
