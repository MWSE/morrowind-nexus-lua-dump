



local input = require('openmw.input')
local localiation = require('openmw.core')
local I = require("openmw.interfaces")
local settings = I.Settings
local DB = require("scripts.ArshvirGoraya.tabToClose.dbug")

l10n = "tabToClose"
local localize = localiation.l10n(l10n, "en")


local settingsPage = {}
settingsPage.description = localize("ModDescription")
settingsPage.name = localize("ModName")
settingsPage.key = "tabToClosePage"
settingsPage.l10n = l10n
settings.registerPage(settingsPage)

local settingsSection_CloseKey = {}
settingsSection_CloseKey.order = 1
settingsSection_CloseKey.l10n = l10n
settingsSection_CloseKey.name = localize("SectionName_CloseKey")
settingsSection_CloseKey.description = localize("SectionDescription_CloseKey")
settingsSection_CloseKey.key = "tabToCloseSection_CloseKey"
settingsSection_CloseKey.page = settingsPage.key
settingsSection_CloseKey.permanentStorage = false

local RendererEnum = {
   textLine = "textLine",
   checkbox = "checkbox",
   number = "number",
   select = "select",
   color = "color",
   inputBinding = "inputBinding",
}
local setting_closeKey = {}
setting_closeKey.renderer = RendererEnum.select
setting_closeKey.name = localize("SettingsName_KeyChoice")





local setting_closeKeyTable = {
   selectKey = localize("KeyChoices_SelectKey"),
   customKey = localize("KeyChoices_CustomKey"),
}

local setting_closeKeyList = {
   localize("KeyChoices_CustomKey"),
   localize("KeyChoices_SelectKey"),
}
setting_closeKey.argument = {
   l10n = l10n,
   items = setting_closeKeyList,
}
setting_closeKey.default = localize("KeyChoices_SelectKey")
setting_closeKey.description = localize("SettingsDescription_KeyChoice", {
   KeyChoices_SelectKey = localize("KeyChoices_SelectKey"),
   KeyChoices_CustomKey = localize("KeyChoices_CustomKey"),
   SettingsName_CustomKey = localize("SettingsName_CustomKey"),
   SettingsName_SelectKey = localize("SettingsName_SelectKey"),
})
setting_closeKey.key = "tabToCloseSetting_CloseKey"

local setting_selectKey = {}
setting_selectKey.renderer = RendererEnum.select
setting_selectKey.name = localize("SettingsName_SelectKey")
setting_selectKey.description = localize("SettingsDescription_SelectKey", {
   SettingsName_KeyChoice = localize("SettingsName_KeyChoice"),
   KeyChoices_SelectKey = localize("KeyChoices_SelectKey"),
})
setting_selectKey.key = "tabToCloseSetting_SelectKey"

local input_KeyNames = {}
local input_KeyTable = {}
for k, v in pairs(input.KEY) do
   table.insert(input_KeyNames, k)
   input_KeyTable[k] = v
end

setting_selectKey.default = input.getKeyName(input.KEY.Tab)
setting_selectKey.argument = {
   l10n = l10n,
   items = input_KeyNames,
}





local customKey = {}
customKey.defaultValue = false
customKey.description = localize("KeyDescription_CustomKey")
customKey.name = localize("SettingsName_CustomKey")
customKey.key = "TabToClose_CustomKey"
customKey.l10n = l10n
customKey.type = input.ACTION_TYPE.Boolean
input.registerAction(customKey)

local setting_customKey = {}
setting_customKey.renderer = RendererEnum.inputBinding
setting_customKey.name = localize("SettingsName_CustomKey")
setting_customKey.description = localize("SettingsDescription_CustomKey", {
   SettingsName_KeyChoice = localize("SettingsName_KeyChoice"),
   KeyChoices_CustomKey = localize("KeyChoices_CustomKey"),
   SettingsName_SelectKey = localize("SettingsName_SelectKey"),
})
setting_customKey.key = "tabToCloseSetting_CustomKey"
setting_customKey.default = "tab"
setting_customKey.argument = {
   key = customKey.key,
   type = "action",
}


settingsSection_CloseKey.settings = {
   setting_closeKey,
   setting_selectKey,
   setting_customKey,
}
settings.registerGroup(settingsSection_CloseKey)


local settingsSection_UI = {}
settingsSection_UI.order = 2
settingsSection_UI.l10n = l10n
settingsSection_UI.name = localize("SectionName_UI")
settingsSection_UI.description = localize("SectionDescription_UI", { SectionName_CloseKey = localize("SectionName_CloseKey") })
settingsSection_UI.key = "tabToCloseSection_UI"
settingsSection_UI.page = settingsPage.key
settingsSection_UI.permanentStorage = false

local defaultUI = {
   Book = true,
   Container = true,
   Rest = true,
   Journal = true,
   QuickKeysMenu = true,
   Scroll = true,
   Interface = true,
   Repair = true,
}

settingsSection_UI.settings = {}
for k, _ in pairs(I.UI.MODE) do
   local modeName = tostring(k)
   local setting_UI = {}
   setting_UI.renderer = RendererEnum.checkbox
   setting_UI.name = localize("SettingsUI_" .. modeName)
   setting_UI.default = false or defaultUI[modeName]
   if setting_UI.default then
      DB.log("tab to close on : ", modeName)
   end
   setting_UI.key = "tabToCloseSetting_UI_" .. modeName
   table.insert(settingsSection_UI.settings, setting_UI)
end
settings.registerGroup(settingsSection_UI)





local storage = require("openmw.storage")
local closeKey = storage.playerSection(settingsSection_CloseKey.key)
local closeKeySelect = closeKey.get(closeKey, setting_closeKey.key)
local selectedFoundInList = false
for _, v in ipairs(setting_closeKeyList) do
   if closeKeySelect == v then
      DB.log("selected was found in list, no need to reset to default")
      selectedFoundInList = true
      break
   end
end
if not selectedFoundInList then
   closeKey.set(closeKey, setting_closeKey.key, setting_closeKey.default)
   closeKeySelect = setting_closeKey.default
end


local selectKeyPressedPreviousFrame = false
local selectKeyPressedThisFrame = false


local customKeyPressedPreviousFrame = false
local customKeyPressedThisFrame = input.getBooleanActionValue(customKey.key)


local selectKeyJustPressed = false
local customKeyJustPressed = false

local storage_UISection = storage.playerSection(settingsSection_UI.key)
local function closeUITrigger()
   DB.log("Detected UI: " .. tostring(I.UI.getMode()))
   for k, _ in pairs(I.UI.MODE) do
      local modeName = tostring(k)
      local selectedUI = storage_UISection.get(storage_UISection, "tabToCloseSetting_UI_" .. modeName)
      if selectedUI and modeName == I.UI.getMode() then
         DB.log("Closing UI: " .. modeName)
         I.UI.setMode(nil)
         return
      end
   end
end




return {

   engineHandlers = {











      onFrame = function()
         closeKeySelect = closeKey.get(closeKey, setting_closeKey.key)
         if closeKeySelect == setting_closeKeyTable.selectKey then
            local selectedKey = closeKey.get(closeKey, setting_selectKey.key)
            selectKeyPressedThisFrame = input.isKeyPressed(input_KeyTable[selectedKey])
            selectKeyJustPressed = selectKeyPressedThisFrame and not selectKeyPressedPreviousFrame
            if selectKeyJustPressed then
               closeUITrigger()
            end
            selectKeyPressedPreviousFrame = selectKeyPressedThisFrame

         elseif closeKeySelect == setting_closeKeyTable.customKey then
            customKeyPressedThisFrame = input.getBooleanActionValue(customKey.key)
            customKeyJustPressed = customKeyPressedThisFrame and not customKeyPressedPreviousFrame
            if customKeyJustPressed then
               closeUITrigger()
            end
            customKeyPressedPreviousFrame = customKeyPressedThisFrame
         end
      end,
   },







}
