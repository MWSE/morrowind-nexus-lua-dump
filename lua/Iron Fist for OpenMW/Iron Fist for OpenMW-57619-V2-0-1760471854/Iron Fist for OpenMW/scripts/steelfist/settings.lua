-- scripts/steelfist/settings.lua
-- Registers the UI and pushes values to GLOBAL whenever they change (or on entering game).
-- Uses the same keys/events as the last working version.

local I       = require('openmw.interfaces')
local storage = require('openmw.storage')
local async   = require('openmw.async')
local menu    = require('openmw.menu')
local core    = require('openmw.core')

local UI_GROUP_KEY = 'SettingsGlobalIronFist'
local PAGE_KEY     = 'IronFistPage'
local EVENT_APPLY  = 'IronFistApplySettings'

local function log(fmt, ...) print(('[IronFist][settings] ' .. fmt):format(...)) end

I.Settings.registerPage {
  key = PAGE_KEY,
  l10n = 'IronFist',
  name = 'Iron Fist',
  description = 'Unarmed bonus from gauntlets based on weight class, condition, STR/H2H, and base armor. Optional gauntlet wear and enchant on hit.',
}

I.Settings.registerGroup {
  key = UI_GROUP_KEY,
  page = PAGE_KEY,
  l10n = 'IronFist',
  name = 'Damage & Wear',
  description = 'Configure Iron Fist.',
  permanentStorage = true, -- required for MENU scripts
  settings = {
    { key='enabled',      name='Enabled',                 renderer='checkbox', default=true },

    -- Calibrated “sane” defaults (MWSE-ish feel)
    { key='base',         name='Base Scalar',             renderer='number',   default=1.0,   argument={ min=0, max=50, step=0.5 } },
    { key='skillWeight',  name='H2H Weight',              renderer='number',   default=1.0,   argument={ min=0, max=5, step=0.05 } },
    { key='strWeight',    name='Strength Weight',         renderer='number',   default=1.0,   argument={ min=0, max=5, step=0.05 } },
    { key='condFloor',    name='Condition Floor',         renderer='number',   default=0.10,  argument={ min=0, max=1, step=0.01 } },

    -- Weight class feel
    { key='heavyMult',    name='Heavy Multiplier',        renderer='number',   default=1.50,  argument={ min=0, max=5, step=0.05 } },
    { key='mediumMult',   name='Medium Multiplier',       renderer='number',   default=1.00,  argument={ min=0, max=5, step=0.05 } },
    { key='lightMult',    name='Light Multiplier',        renderer='number',   default=0.50,  argument={ min=0, max=5, step=0.05 } },
    { key='clothingMult', name='Clothing Multiplier',     renderer='number',   default=0.35,  argument={ min=0, max=5, step=0.05 } },

    -- Only base armor contribution (your request)
    { key='armorBaseFactor', name='Base Armor to Damage', renderer='number',   default=0.00,  argument={ min=0, max=5, step=0.05 } },

    -- Durability
    { key='detEnabled',   name='Damage Gauntlet Condition', renderer='checkbox', default=true },
    { key='detChance',    name='Deterioration Chance (%)',  renderer='number',   default=20,  argument={ min=0, max=100, step=1 } },
    { key='detScale',     name='Condition per Bonus Damage',renderer='number',   default=1.0, argument={ min=0, max=5, step=0.05 } },

    -- Enchant on hit
    { key='castEnchantOnHit',     name='Cast Enchant on Hit',   renderer='checkbox', default=true },
    { key='consumeEnchantCharge', name='Consume Enchant Charge',renderer='checkbox', default=true },

    { key='debug',        name='Debug Logging',             renderer='checkbox', default=false },
  },
}

local function readUI()
  local P = storage.playerSection(UI_GROUP_KEY)
  return {
    enabled        = P:get('enabled'),
    base           = P:get('base'),
    skillWeight    = P:get('skillWeight'),
    strWeight      = P:get('strWeight'),
    condFloor      = P:get('condFloor'),
    heavyMult      = P:get('heavyMult'),
    mediumMult     = P:get('mediumMult'),
    lightMult      = P:get('lightMult'),
    clothingMult   = P:get('clothingMult'),
    armorBaseFactor= P:get('armorBaseFactor'),
    detEnabled     = P:get('detEnabled'),
    detChance      = P:get('detChance'),
    detScale       = P:get('detScale'),
    castEnchantOnHit     = P:get('castEnchantOnHit'),
    consumeEnchantCharge = P:get('consumeEnchantCharge'),
    debug          = P:get('debug'),
  }
end

local function sendApply()
  if menu.getState() ~= menu.STATE.Running then
    log('Game not running; will apply when entering game.')
    return
  end
  local payload = readUI()
  core.sendGlobalEvent(EVENT_APPLY, payload)
  log('Applied (base=%.2f, baseArmor=%.2f, cast=%s, drain=%s)',
      payload.base or -1, payload.armorBaseFactor or -1,
      tostring(payload.castEnchantOnHit), tostring(payload.consumeEnchantCharge))
end

-- Push whenever user changes a setting while a game is running
storage.playerSection(UI_GROUP_KEY):subscribe(async:callback(function()
  if menu.getState() == menu.STATE.Running then sendApply() end
end))

return {
  engineHandlers = {
    onInit = function() if menu.getState() == menu.STATE.Running then sendApply() end end,
    onStateChanged = function() if menu.getState() == menu.STATE.Running then sendApply() end end,
  },
}
