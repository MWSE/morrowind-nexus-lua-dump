local conf  = require('scripts.yksuiMagicTimeHud.config')
local I     = require('openmw.interfaces')
local async = require('openmw.async')
local core  = require('openmw.core')
local input = require('openmw.input')
local self  = require('openmw.self')
local time  = require('openmw_aux.time')
local types = require('openmw.types')
local ui    = require('openmw.ui')
local util  = require('openmw.util')
local alignCenter = ui.ALIGNMENT.Center
local colorIcon = util.color.rgb(0.5,0.5,0.5)
local colorText = util.color.rgb(223/255,201/255,159/255)
local getActiveSpells = types.Actor.activeSpells
local mfxRecord = core.magic.effects.records
local v2 = util.vector2

I.Settings.registerPage{key='MagicTimeHudPage',l10n='Interface',name='magic time hud'}
I.Settings.registerGroup{page='MagicTimeHudPage',key='SettingsMagicTimeHud',l10n='Interface',name="scaling factor ",permanentStorage=true,settings={{key='scale',name='0.5 to 8.0',renderer='number',default=1.0,argument={max=8.0,min=0.5}}}}
local scale = require('openmw.storage').playerSection('SettingsMagicTimeHud'):get('scale')

local root, list, numSlots

--    | ==== |   | [] |   | [] |     |             |      | [] |
-- 13 2  61  2 4 2 32 2 4 2 32 2 4 < 2 ... 8 32... 2 > 12 2 61 2 12
local function initRoot()
   local xyOffset = v2(91 + conf.xOffset, 20 + conf.yOffset)
   local xIcon, yText, xSpace = conf.xIcon, conf.yText, conf.xSpace
   local xSlot, xyScreen = xSpace + xIcon, ui.screenSize() / scale
   numSlots = math.floor((xyScreen.x - 255 - conf.xOffset) / xSlot)
   local xyRoot = v2(numSlots * xSlot, xIcon)
   list = {}
   local content = {}
   local px = xyRoot.x - xIcon
   local pyText = math.floor((xIcon - yText) / 2)
   local xyText = v2(xIcon, yText)
   local xyIcon = v2(xIcon, xIcon)
   local blank = ui.texture{path="black"}
   for i = 1, numSlots do
      local icon = {
         type = ui.TYPE.Image,
         props = {
            -- alpha = 0.84,
            color = colorIcon,
            position = v2(px, 0),
            resource = blank,
            size = xyIcon,
            visible = false,
      }}
      local text = {
         type = ui.TYPE.Text,
         props = {
            autoSize = false,
            position = v2(px, pyText),
            size = xyText,
            text = "",
            textAlignH = alignCenter,
            textColor = colorText,
            textShadow = true,
            textSize = yText,
            visible = false,
      }}
      content[i+i-1] = icon
      content[i+i  ] = text
      list[i] = { icon=icon, text=text, id='' }
      px = px - xSpace - xIcon
   end
   root = ui.create {
      type = ui.TYPE.Widget,
      layer = 'HUD',
      content = ui.content(content),
      props = {
         position = xyScreen - xyOffset - xyRoot,
         size = xyRoot,
         visible = I.UI.isHudVisible(),
   }}
end

local prevSlots = 0
local function refresh()
   local i = 1
   for _, as in pairs(getActiveSpells(self)) do
      for _, ase in pairs(as.effects) do
         if ase.duration and -- 48 min = 1 game day
            ase.durationLeft <= 2880 then
            local fx, secsLeft = list[i], math.max(0, ase.durationLeft)
            if secsLeft <= 9 and 0 == math.floor(secsLeft * 2) % 2 then
               fx.icon.props.visible = false
               fx.text.props.visible = false
            else
               fx.icon.props.visible = true
               fx.text.props.visible = true
               fx.text.props.text = secsLeft <= 999
                  and tostring(util.round(secsLeft))
                  or  ""
               if fx.id ~= ase.id then
                  fx.id  = ase.id
                  fx.icon.props.resource = ui.texture{path=mfxRecord[fx.id].icon}
               end
            end
            i = i + 1
            if numSlots < i then
               goto done
   end end end end
   ::done::
   for j = i, prevSlots do
      list[j].icon.props.visible = false
      list[j].text.props.visible = false
   end
   prevSlots = i - 1
   root:update()
end

initRoot()
time.runRepeatedly(refresh, 0.5)
input.registerTriggerHandler(
   'ToggleHUD', async:callback(function()
         root.layout.props.visible = I.UI.isHudVisible()
         root:update()
end))
-- TODO adapt to gui settings: scaling factor, font size, menu transparency
-- TODO hide on black loading screen
