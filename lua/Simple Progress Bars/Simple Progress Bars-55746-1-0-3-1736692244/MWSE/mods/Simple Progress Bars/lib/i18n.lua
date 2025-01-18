local this = {}

local function i18nSafe (text)
	return this.i18n(text) or text
end

this.init = function (MDIR)
	this.i18n = mwse.loadTranslations(MDIR)
	return i18nSafe
end

setmetatable(this, {__call = function(table, text)
	return i18nSafe(text)
end})

return this
