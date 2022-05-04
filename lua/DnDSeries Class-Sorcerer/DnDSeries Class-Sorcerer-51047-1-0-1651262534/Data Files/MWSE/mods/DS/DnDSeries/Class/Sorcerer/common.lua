local this = {}
local tables=require('DS.DnDSeries.Class.Base.Tables')
local function metaMagicMsgBox(params)
  --[[
      Button = { text, callback}
  ]]--
  local message = params.message
  local buttons = params.buttons
  local function callback(e)
      --get button from 0-indexed MW param
      local button = buttons[e.button+1]
      if button.callback then
          button.callback()
      end
  end
  --Make list of strings to insert into buttons
  local buttonStrings = {}
  for _, button in ipairs(buttons) do
      table.insert(buttonStrings, button.text)
  end
  tes3.messageBox({
      message = message,
      buttons = buttonStrings,
      callback = callback
  })
end
local function spellTooltip(e)
  local spell = e.spell
  local metamagicLabel = {}
  if string.find(spell.id, "[M]", 1, true) then
    table.insert(metamagicLabel, "Maximize")
  end
  if string.find(spell.id, "[En]", 1, true) then
    table.insert(metamagicLabel, "Enpower")
  end
  if string.find(spell.id, "[Ex]", 1, true) then
    table.insert(metamagicLabel, "Extend")
  end
  if string.find(spell.id, "[W]", 1, true) then
    table.insert(metamagicLabel, "Widen")
  end
  if string.find(spell.id, "[Q]", 1, true) then
    table.insert(metamagicLabel, "Quicken")
  end
  if table.empty(metamagicLabel) == true then return end
  local block = e.tooltip:createBlock()
  block.minWidth = 1
  block.maxWidth = 230
  block.autoWidth = true
  block.autoHeight = true
  block.paddingAllSides = 6
  block.flowDirection = "top_to_bottom"
  local label = block:createLabel{text = "Metamagic Applied:"}
  label.wrapText = true
  if table.find(metamagicLabel, "Enpower") ~= nil then
    local Mlabel1 = "[Enpower]"
    local text1 = string.format("%s", Mlabel1)
    local block1 = e.tooltip:createBlock()
    block1.minWidth = 1
    block1.maxWidth = 130
    block1.autoWidth = true
    block1.autoHeight = true
    block1.paddingAllSides = 6
    local label1 = block:createLabel{text = text1}
    label1.wrapText = true
  end
  if table.find(metamagicLabel, "Extend") ~= nil then
    local Mlabel1 = "[Extend]"
    local text1 = string.format("%s", Mlabel1)
    local block1 = e.tooltip:createBlock()
    block1.minWidth = 1
    block1.maxWidth = 130
    block1.autoWidth = true
    block1.autoHeight = true
    block1.paddingAllSides = 6
    local label1 = block:createLabel{text = text1}
    label1.wrapText = true
  end
  if table.find(metamagicLabel, "Maximize") ~= nil then
    local Mlabel1 = "[Maximize]"
    local text1 = string.format("%s", Mlabel1)
    local block1 = e.tooltip:createBlock()
    block1.minWidth = 1
    block1.maxWidth = 130
    block1.autoWidth = true
    block1.autoHeight = true
    block1.paddingAllSides = 6
    local label1 = block:createLabel{text = text1}
    label1.wrapText = true
  end
  if table.find(metamagicLabel, "Widen") ~= nil then
    local Mlabel1 = "[Widen]"
    local text1 = string.format("%s", Mlabel1)
    local block1 = e.tooltip:createBlock()
    block1.minWidth = 1
    block1.maxWidth = 130
    block1.autoWidth = true
    block1.autoHeight = true
    block1.paddingAllSides = 6
    local label1 = block:createLabel{text = text1}
    label1.wrapText = true
  end
  if table.find(metamagicLabel, "Quicken") ~= nil then
    local Mlabel1 = "[Quicken]"
    local text1 = string.format("%s", Mlabel1)
    local block1 = e.tooltip:createBlock()
    block1.minWidth = 1
    block1.maxWidth = 130
    block1.autoWidth = true
    block1.autoHeight = true
    block1.paddingAllSides = 6
    local label1 = block:createLabel{text = text1}
    label1.wrapText = true
  end
end
local function MetaMagicKey(e)
  if tes3.mobilePlayer.inCombat == true then return end
  local Maximize = require('DS.DnDSeries.Class.Sorcerer.Feats.Metamagic-Maximize')
  local Enpower = require('DS.DnDSeries.Class.Sorcerer.Feats.Metamagic-Enpower')
  local Extend = require('DS.DnDSeries.Class.Sorcerer.Feats.Metamagic-Extend')
  local Widen = require('DS.DnDSeries.Class.Sorcerer.Feats.Metamagic-Widen')
  local Quicken = require('DS.DnDSeries.Class.Sorcerer.Feats.Metamagic-Quicken')
      local buttons = {}
      if tes3.mobilePlayer.currentSpell == nil then return end
      local spellId = tes3.mobilePlayer.currentSpell.id
      if spellId == nil then return end
      if (e.isShiftDown  and (e.keyCode == tes3.scanCode.x)) and not tes3.menuMode() then
       for _, id in ipairs(tes3.player.data.DnDSeries.LearnedFeats) do
        if id == "enpower" then
          table.insert(buttons, {
            text = "Enpower",
            callback = function ()
             Enpower.metaMagic(spellId)
            end
          })
      end
      if id == "extend" then
          table.insert(buttons, {
            text = "Extend",
            callback = function ()
             Extend.metaMagic(spellId)
            end
          })
      end
      if id == "maximize" then
          table.insert(buttons,{
            text = "Maximize",
            callback = function()
             Maximize.metaMagic(spellId)
            end
        })
      end
      if id == "quicken" then
          table.insert(buttons, {
           text = "Quicken",
           callback = function ()
            Quicken.metaMagic(spellId)
           end
          })
      end
      if id == "widen" then
          table.insert(buttons, {
            text = "Widen", 
            callback = function ()
             Widen.metaMagic(spellId)
            end
          })
      end
      if table.empty(buttons) == false then
      table.insert(buttons, { text = "Cancel" })
      metaMagicMsgBox{
        message = "Which metamagic do you want to apply",
        buttons = buttons
       }
      end
       end
      end
end
local SorcererFeats = {
     {id="enpower",
      class ="Sorcerer",
      name="Enpowered Magic",
      callback=function ()
        if event.isRegistered("uiSpellTooltip", spellTooltip) == false then
         event.register("uiSpellTooltip", spellTooltip)
        end
        if event.isRegistered("keyDown", MetaMagicKey) == false then
          event.register("keyDown", MetaMagicKey)
        end
      end,
      skill = tes3.skill.conjuration,
      description="Modify the current spell: duplicating its min and max magnitude, for one cast only"},
     {id="extend",
      class ="Sorcerer",
      name="Extended Magic",
      callback=function ()
        if event.isRegistered("uiSpellTooltip", spellTooltip) == false then
         event.register("uiSpellTooltip", spellTooltip)
        end
        if event.isRegistered("keyDown", MetaMagicKey) == false then
          event.register("keyDown", MetaMagicKey)
        end
      end,
      skill = tes3.skill.illusion,
      description="Modify the current spell: duplicating its duration, for one cast only"},
     {id="quicken",
      class ="Sorcerer",
      name="Quicken Magic",
      callback=function ()
        if event.isRegistered("uiSpellTooltip", spellTooltip) == false then
         event.register("uiSpellTooltip", spellTooltip)
        end
        if event.isRegistered("keyDown", MetaMagicKey) == false then
          event.register("keyDown", MetaMagicKey)
        end
      end,
      skill = tes3.skill.mysticism,
      description="Modify the current spell: by casting the spell instantaneously, for one cast only"},
     {id="maximize",
      class ="Sorcerer",
      name="Maximized Magic",
      callback=function ()
        if event.isRegistered("uiSpellTooltip", spellTooltip) == false then
         event.register("uiSpellTooltip", spellTooltip)
        end
        if event.isRegistered("keyDown", MetaMagicKey) == false then
          event.register("keyDown", MetaMagicKey)
        end
      end,
      skill = tes3.skill.destruction,
      description="Modify the current spell: matching its min magnitude to the max magnitude, for one cast only"},
     {id="widen",
      class ="Sorcerer",
      name="Widen Magic",
      callback=function ()
        if event.isRegistered("uiSpellTooltip", spellTooltip) == false then
         event.register("uiSpellTooltip", spellTooltip)
        end
        if event.isRegistered("keyDown", MetaMagicKey) == false then
          event.register("keyDown", MetaMagicKey)
        end
      end,
      skill = tes3.skill.alteration,
      description="Modify the current spell: duplicating its radius, for one cast only"},

}
function this.addFeats()
for _, data in pairs(SorcererFeats) do
  local feats = tables.Feats
    if not table.find(feats, data) then
    table.insert(feats, data)
    end
    tables.Feats =feats
end
end
function this.RegisterEvents()
for _, id in ipairs(tes3.player.data.DnDSeries.LearnedFeats) do
  for _, data in ipairs(tables.Feats) do
    if id == data.id then
      if data.callback then
        data.callback(data)
      end
    end
  end
end
end
function this.isValid(spell)
if spell.objectType == tes3.objectType.spell and
   spell.castType == tes3.spellType.spell then
 return true
else
 return false
end
end
function this.checkCast(e)
if e.caster ~= tes3.player then return end
local spellId = e.source.id
if string.find(spellId, "MetaSpell", 1, true) then
    local Quicken = require('DS.DnDSeries.Class.Sorcerer.Feats.Metamagic-Quicken')
    local newid = spellId:match("%d+")
    local preparedSpell = tes3.player.data.DnDSeries.MetaMagicPreparedSpell
    local num = tonumber(newid)
    mwscript.removeSpell{reference=tes3.mobilePlayer, spell= spellId}
    if not tes3.hasSpell{reference=tes3.mobilePlayer, spell=preparedSpell[num]} then
      tes3.addSpell{reference= tes3.mobilePlayer, spell=preparedSpell[num]}
      tes3.mobilePlayer:equipMagic{source=preparedSpell[num]}
      table.remove(preparedSpell, num)
      tes3.player.data.DnDSeries.MetaMagicPreparedSpell = preparedSpell
    end
    if table.empty(preparedSpell) == true then
      if event.isRegistered("spellCasted", this.checkCast) == true then
      event.unregister("spellCasted", this.checkCast)
      end
      if event.isRegistered("simulate", Quicken.quickenMeta) == true then
        event.unregister("simulate", Quicken.quickenMeta)
      end
      if event.isRegistered("keyDown", Quicken.quickenCast) == true then
        event.unregister("keyDown", Quicken.quickenCast)
      end
    end
end
end
return this