---@class translations
local this = {}

--- Fetches a localized string based on a given key
---@public
---@param key TRANSLATION_KEY The translation key to use
---@return string translation The localized string
function this.get(key)
    return mwse.loadTranslations("tauer.dynamic-conversations")(key)
end

return this
