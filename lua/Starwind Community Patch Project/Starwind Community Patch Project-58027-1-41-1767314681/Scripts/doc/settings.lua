---@alias DefaultSettingRenderer
---| '"textLine"'
---| '"checkbox"'
---| '"number"'
---| '"select"'
---| '"color"'
---| '"inputBinding"'

---@alias InputBindingType
---| '"action"'
---| '"trigger"'

---@class InputBindingOptions
---@field key string The (table) key of the binding
---@field type InputBindingType The type of binding
---@field disabled boolean? Disables changing the setting from the UI. Defaults to false.

---@class ColorSettingOptions

---@class SelectSettingOptions
---@field l10n string localization context with display values for items. Required.
---@field items string[] list of available setting options. Defaults to empty array.

---@class NumberSettingOptions
---@field integer boolean? Whether to only allow integer values. Defaults to false.
---@field min number? If set, restricts setting values below this number. Defaults to nil.
---@field max number? If set, restricts setting values above this number. Defaults to nil.

---@class CheckboxSettingOptions
---@field l10n string localization context with display values for items. Defaults to 'Interface'
---@field trueLabel string? Localization key to display for the true value. Defaults to 'Yes'
---@field falseLabel string? Localization key to display for the false value. Defaults to 'No'

---@class TextLineOptions

---@alias SettingRendererOptions
---| ColorSettingOptions
---| SelectSettingOptions
---| CheckboxSettingOptions
---| NumberSettingOptions
---| TextLineOptions
---| InputBindingOptions

