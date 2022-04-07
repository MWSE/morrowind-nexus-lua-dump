local function staffValues(item)
local value = item.value
local isStaff
local multiplier
if item.type ~= tes3.weaponType.bluntTwoWide then
  isStaff = false
else
  isStaff = true
end
if value == nil then return end
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
print("Staff Casting : initialized")
end)