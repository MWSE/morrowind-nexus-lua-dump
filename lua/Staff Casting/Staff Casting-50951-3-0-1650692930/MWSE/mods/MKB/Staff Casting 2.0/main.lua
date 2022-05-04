
local function staffValues(item)
  local value = item.value
  local isStaff
  local multiplier
  if item.type ~= tes3.weaponType.bluntTwoWide then
    isStaff = false
    multiplier = 1
  else
    isStaff = true
  if value == nil then
    multiplier = 1
    return end
  if value < 50 then
    multiplier = 1.5
  elseif value < 100 then
    multiplier = 2
  elseif value < 200 then
    multiplier = 2.5
  elseif value < 1000 then
    multiplier = 3
  elseif value < 10000 then
    multiplier = 3.5
  elseif value > 9999 then
    multiplier = 4
  end
end
  return multiplier, isStaff
end

local function staffCasting(e)
    local weapon = e.caster.mobile.readiedWeapon.object
    local multiplier, isStaff = staffValues(weapon)
    if e.caster.mobile.weaponReady == false then return end
    if multiplier == nil or isStaff == nil then return end
    if isStaff == true then
    e.castChance = e.castChance*multiplier
    end
end

local function updatingTheSpellMenu()
  local weapon
  local multiplier = 1
  local isStaff
  if tes3.mobilePlayer and tes3.mobilePlayer.readiedWeapon then
    if tes3.mobilePlayer.weaponReady == false then
    multiplier = 1
    else
    weapon = tes3.mobilePlayer.readiedWeapon.object
    multiplier, isStaff = staffValues(weapon)
    end
  else weapon = nil
  end

  local chance = {}
  local cost = {}
  local menu = tes3ui.findMenu("MenuMagic")
  if not menu then return end
    local menuCost = menu:findChild("MagicMenu_spell_costs")
    local menuChance = menu:findChild("MagicMenu_spell_percents")

    for i, child in pairs(menuChance.children) do
      table.insert(chance, i, string.match(child.text, "%d+"))
      --child.text = "/"..chance[i]--*multiplier
      child.visible = false
    end

    for i, child in pairs(menuCost.children) do
        table.insert(cost, i, string.match(child.text, "%d+"))
      child.text = cost[i]..string.format("/%d", math.clamp(chance[i]*multiplier, 0, 100))
    end


end

local function staffTooltip(e)
local multiplier, isStaff = staffValues(e.object)
if multiplier == nil or isStaff == nil then return end
if isStaff == true then
    local text = string.format("Cast Chance Multiplier: %s", multiplier)
    local block = e.tooltip:createBlock()
    block.minWidth = 1
    block.maxWidth = 230
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 6
    local label = block:createLabel{text = text}
    label.wrapText = true
 end
end
event.register("initialized", function()
event.register("spellCast", staffCasting)
event.register("uiObjectTooltip", staffTooltip)
event.register("enterFrame", updatingTheSpellMenu, {priority = -500})
print("Staff Casting : initialized")
end)