-- Enchant Transfer — Настройки (MENU) для OpenMW 0.49
-- Показывает привязку клавиши через renderer='inputBinding' к Boolean ACTION.

local I     = require('openmw.interfaces')
local input = require('openmw.input')

local L10N       = 'EnchantXfer'
local PAGE_KEY   = 'Enchant Transfer'              -- ключ страницы (внутренний), оставляем стабильным
local GROUP_KEY  = 'SettingsGlobalEnchantXfer'     -- ключ группы (внутренний)
local ACTION_KEY = 'EnchantXfer_OpenMenu'          -- уникальное имя действия

local function ensureActionRegistered()
  -- Должно существовать в MENU, чтобы строка настройки могла привязать клавишу (идемпотентно).
  if not input.actions[ACTION_KEY] then
    input.registerAction({
      key          = ACTION_KEY,
      l10n         = L10N,
      name         = '',
      description  = '',
      type         = input.ACTION_TYPE.Boolean,
      defaultValue = false,
    })
  end
end

local function registerSettings()
  I.Settings.registerPage{
    key = PAGE_KEY, l10n = L10N,
    name = 'Перенос зачарования',
    description = 'Настройка горячей клавиши для открытия окна переноса зачарования.',
  }

  I.Settings.registerGroup{
    key = GROUP_KEY, page = PAGE_KEY, l10n = L10N,
    name = 'Горячая клавиша',
    description = 'Выберите клавишу для открытия окна переноса зачарования.',
    permanentStorage = true,
    settings = {
      {
        key = 'OpenMenuBinding',
        renderer = 'inputBinding',
        name = 'Открыть меню',
        description = 'Нажмите для открытия окна переноса зачарования.',
        default = '', -- inputBinding ожидает СТРОКУ; пустая строка = без привязки
        argument = {
          key  = ACTION_KEY,
          type = 'action',
        },
      },
    },
  }
end

return {
  engineHandlers = {
    onInit = function()
      ensureActionRegistered()
      registerSettings()
    end,
  },
}
