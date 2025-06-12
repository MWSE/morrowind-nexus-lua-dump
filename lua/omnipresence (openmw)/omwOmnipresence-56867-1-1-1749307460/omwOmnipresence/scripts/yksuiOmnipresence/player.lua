local I     = require('openmw.interfaces')
local async = require('openmw.async')
local input = require('openmw.input')
local self  = require('openmw.self')
local ui    = require('openmw.ui')
local util  = require('openmw.util')
local sendGlobalEvent  = require('openmw.core').sendGlobalEvent
local setControlSwitch = require('openmw.types').Player.setControlSwitch
local colorHeader = util.color.rgb(223/255, 201/255, 159/255)
local colorNormal = util.color.rgb(202/255, 165/255,  96/255)
local v2 = util.vector2

local numShow = 23
local lenLine = 27
local yText = 16
local xPad, yPad = 4, 2
local border = 8

local active, cellTable
local choice, result, freq
local query, tally, slate, root

local function initRoot()
   sendGlobalEvent('yksuiReqCellTable', self)
   local xText, yTextPad = lenLine * yText, yText + yPad
   local xyMenu = v2(border + xPad + xText + xPad + border, border + yPad + yTextPad + yPad + yPad + yTextPad * numShow + yPad + border)
   local xyText = v2(xText, yText)
   local xy1    = v2(1, 1)
   local xyHalf = xy1 / 2
   local px, py = border + xPad, border + yPad
   query = {
      type = ui.TYPE.Text,
      props = {
         autoSize = false,
         position = v2(px, py),
         size = xyText,
         text = "",
         textColor = util.color.hex('ffffff'),
         textSize = yText,
   }}
   py = py + yText
   tally = {
      type = ui.TYPE.Text,
      props = {
         anchor = xy1,
         position = v2(px + xText, py),
         text = "",
         textColor = colorNormal,
         textSize = yText,
   }}
   py = py + yPad * 3
   slate = {}
   for i = 1, numShow do
      slate[i] = {
         type = ui.TYPE.Text,
         props = {
            autoSize = false,
            position = v2(px, py),
            size = xyText,
            text = "",
            textColor = colorNormal,
            textSize = yText,
      }}
      py = py + yTextPad
   end
   local content = {
      { type = ui.TYPE.Image,
        props = {
           alpha = ui._getMenuTransparency(),
           resource = ui.texture{path="black"},
           size = xyMenu,
      }},
      query,
      tally,
   }
   table.move(slate, 1, numShow, 4, content)
   root = ui.create {
      type = ui.TYPE.Widget,
      layer = 'DrowningBar',
      content = ui.content(content),
      props = {
         anchor = xyHalf,
         relativePosition = xyHalf,
         size = xyMenu,
         visible = true,
   }}
end

-- root:update < upRoot < upTally < upSlate < upResult
local function upRoot(successor)
   if choice then slate[choice].props.textColor = colorNormal end
   choice = successor
   if choice then slate[choice].props.textColor = colorHeader end
   root:update()
end

local function upTally(successor)
   tally.props.text = result and tostring(#result) or ""
   upRoot(successor)
end

local function upSlate(successor)
   local res = result or {}
   for i, row in ipairs(slate) do
      row.props.text = res[i] or ""
   end
   upTally(successor)
end

local function modeOff()
   active = false
   root.layout.props.visible = false
   query.props.text = ""
   result = nil
   upSlate()
   I.Controls.overrideUiControls(false)
   I.Controls.overrideCombatControls(false)
   I.Controls.overrideMovementControls(false)
   setControlSwitch(self, 'playermagic', true)
   setControlSwitch(self, 'playercontrols', true)
   setControlSwitch(self, 'playerviewswitch', true)
   sendGlobalEvent('Unpause', 'yksuiOmnipresence')
end

local function modeOn()
   sendGlobalEvent('Pause', 'yksuiOmnipresence')
   setControlSwitch(self, 'playerviewswitch', false)
   setControlSwitch(self, 'playercontrols', false)
   setControlSwitch(self, 'playermagic', false)
   I.Controls.overrideMovementControls(true)
   I.Controls.overrideCombatControls(true)
   I.Controls.overrideUiControls(true)
   if root then
      root.layout.props.visible = true
      root:update()
   else
      initRoot()
   end
   active = true
end

local function isBetter(c, d)
   local fc = freq[c] or 0
   local fd = freq[d] or 0
   return fc == fd
      and #c < #d
      or  fc > fd
end

local function queryFilter(q, to, from)
   local i = 1
   for _, s in ipairs(from or to) do
      if s:find(q) then
         to[i] = s
         i = i + 1
      end
   end
   for j = #to, i, -1 do
      to[j] = nil
   end
   return to
end

local function upResult(qs)
   local n, qw = 0, {}
   for q in qs:gmatch("[^ ]+") do
      n = n + 1
      qw[n] = q
   end
   if n == 0 then -- sorting only
      table.sort(cellTable, isBetter)
      result = table.move(cellTable, 1, #cellTable, 1, {})
   elseif result then -- incremental filtering
      queryFilter(qw[n], result)
   else -- filtering and sorting
      result = queryFilter(qw[1], {}, cellTable)
      for i = 2, n do queryFilter(qw[i], result) end
      table.sort(result, isBetter)
   end
   upSlate(1)
end

local function onKeyPress(key)
   -- print("==== key:", key.code, key.symbol)
   local keycode = key.code
   if 4 <= keycode and keycode <= 39 then -- alphanumeric
      -- TODO consider allowing !&'(),-.:_
      query.props.text = query.props.text .. key.symbol
      if result then upResult(query.props.text)
      else           root:update()
      end
   elseif keycode == 44 then -- space
      local qs = query.props.text
      if qs:sub(#qs) ~= " " then
         query.props.text = qs .. " "
         upResult(qs)
      end
   elseif keycode == 42 then -- backspace
      result = nil -- invalidate incremental filtering
      local qs = query.props.text
      qs = key.withAlt
         and (qs:match("(.* )[^ ]+ ?$") or "")
         or  (qs:sub(1, qs:sub(#qs) == " " and -3 or -2))
      query.props.text = qs
      if qs:sub(#qs) == " " then upResult(qs)
      elseif     qs  ==  "" then upSlate()
      else                       upTally()
      end
   elseif keycode == 40 then -- enter
      local sel = choice and result and result[choice]
      if sel then
         sendGlobalEvent('yksuiReqMoveToCell', { obj=self, to=cellTable[sel] })
         freq[sel] = (freq[sel] or 0) + 1
         modeOff()
      end
   elseif keycode == 47 or keycode == 82 then -- [ up
      if choice and 1 < choice then
         upRoot(choice - 1)
      end
   elseif keycode == 48 or keycode == 81 then -- ] down
      if choice and choice < numShow and result and choice < #result then
         upRoot(choice + 1)
      end
   elseif keycode == 41 then -- esc
      modeOff()
   end
end

input.registerActionHandler(
   'Run', async:callback(function(on)
         if on and self.controls.sneak and not active then
            modeOn()
         end
end))

return {
   engineHandlers = {
      onKeyPress = function(key)
         if active then
            onKeyPress(key)
         end
      end,
      onInit = function() freq = {} end,
      onLoad = function(data) freq = data end,
      onSave = function() return freq end,
   },
   eventHandlers = {
      yksuiResCellTable = function(res)
         cellTable = res
      end,
   },
}
