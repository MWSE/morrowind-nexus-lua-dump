local types = require('openmw.types')
local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')

local I = require('openmw.interfaces')
local ui = require('openmw.ui')

-- https://openmw.readthedocs.io/en/latest/reference/lua-scripting/overview.html#language-and-sandboxing

local display = ""

local Actor = types.Actor
local pressed_hotkey = nil
local pressed_cycle = nil
local cycle_pos = 1

local last_hotkey = nil
local setMode = false

local isLoading = false

local function init_cycle()
  cycle_contents = {}
  for i = 1, 9 do
    if cycle_contents[i] == nil then cycle_contents[i] = {} end
  end
end

init_cycle()

local num_map = {}
num_map["1"] = 1
num_map["2"] = 2
num_map["3"] = 3
num_map["4"] = 4
num_map["5"] = 5
num_map["6"] = 6
num_map["7"] = 7
num_map["8"] = 8
num_map["9"] = 9

print("OpenMW Cyclical hotkeys declarations complete")

-- Initiate setHotkeySpell function with mod key '\' input
local function setHotkeySpell(number)
  local chosen_spell = Actor.getSelectedSpell(self)
  if chosen_spell == nil then
    ui.showMessage("Please choose a spell")
    return
  -- else
    -- display = chosen_spell.name .. " Equipped"
    -- ui.showMessage(display)
  end
  if pressed_hotkey == nil then
    pressed_hotkey = number
    pressed_cycle = nil
    ui.showMessage("Please choose a cycle number for hotkey")
    return
  end
  if pressed_cycle == nil then
    pressed_cycle = number

    cycle_contents[pressed_hotkey][pressed_cycle] = chosen_spell
    -- print(cycle_contents)
    display = chosen_spell.name .. " assigned to " .. pressed_hotkey .. ", " .. pressed_cycle
    ui.showMessage(display)

    pressed_cycle = nil
    pressed_hotkey = nil
  end
end

local function setSpell(number)
  local hotkey = number
  if last_hotkey == nil or last_hotkey ~= hotkey then
    cycle_pos = 1
    last_hotkey = hotkey
  else
    if cycle_contents ~= nil and cycle_contents[hotkey] ~= nil and #(cycle_contents[hotkey]) >= (1+cycle_pos) then
      cycle_pos = cycle_pos + 1
    else
      cycle_pos = 1
    end
  end
  if cycle_contents~= nil and cycle_contents[hotkey] ~= nil and cycle_contents[hotkey][cycle_pos] ~= nil then
    Actor.setSelectedSpell(self, cycle_contents[hotkey][cycle_pos])
    Actor.setStance(self, Actor.STANCE.Spell)
    local known_spells = types.Actor.spells(self)
    -- print(type(cycle_contents[hotkey][cycle_pos]) .. " is spell type")
  else
    if cycle_contents[hotkey] == nil then
      cycle_contents[hotkey] = {}
    end
    ui.showMessage("No spell equipped on cycle")
  end

end

local function onKeyRelease(key)

  if key.symbol == '\\'
  then
    setMode = not setMode
    pressed_cycle = nil
    pressed_hotkey = nil
    if setMode and not isLoading then
      ui.showMessage("HOTKEY SETUP mode")
    elseif not setMode and not isLoading then
      ui.showMessage("HOTKEY USE mode")
    else
      ui.showMessage("Hotkeys initialising....")
    end
  end
  
  if not isLoading and (key.code == input.KEY._1 or key.code == input.KEY._2 or key.code == input.KEY._3 or key.code == input.KEY._4 or key.code == input.KEY._5 or key.code == input.KEY._6 or key.code == input.KEY._7 or key.code == input.KEY._8 or key.code == input.KEY._9) then
    local number = num_map[key.symbol]
    if setMode then
      setHotkeySpell(number)
    else
      setSpell(number)
    end
  end
end

local function onSave()
  print("\nSaving OpenMW hotkeys data..")
  local cycle_contents_id = {}
  for i = 1, 9 do
    cycle_contents_id[i] = {}
    for j = 1, 9 do
      if cycle_contents[i] ~= nil and cycle_contents[i][j] ~= nil then
        cycle_contents_id[i][j] = cycle_contents[i][j].id
      end
    end
  end
  return {
      version = 1,
      last_hotkey = last_hotkey,
      cycle_contents_id = cycle_contents_id,
  }
end

local function onLoad(data)
  isLoading = true
  print("\nOpenMw Cyclical Hotkeys Loading starts")
  if data then
    last_hotkey = data.last_hotkey
    local cycle_contents_id = data.cycle_contents_id
    local records = core.magic.spells.records
    local known_spells = types.Actor.spells(self)
    local shift = 0
    if cycle_contents == nil
    then
      init_cycle()
    end
    -- Load Spell Data
    for i = 1, 9 do
      shift = 0
      if cycle_contents_id[i] ~= nil then
        for j = 1, 9-shift do
          if cycle_contents_id[i][j] ~= nil then
            cycle_contents[i][j-shift] = records[cycle_contents_id[i][j]]
            if known_spells[cycle_contents[i][j].id] == nil
            then
              print("\nRemoving Unknown Spell " .. cycle_contents[i][j].name)
              shift = shift + 1
            end
          end
        end
        if #cycle_contents[i] == 1 and shift == 1 then
          cycle_contents[i] = {}
        end
      end
    end
  end
  print("\nOpenMW Cyclical Hotkeys Loading done")
  isLoading = false
end

return {
  engineHandlers = {
      onSave = onSave,
      onLoad = onLoad,
      onKeyRelease = onKeyRelease
  }
}



-- Actor.setSelectedSpell(actor, spell)
-- will set the spells by responding to hotkeys
-- n

--Actor.setStance(actor, stance)
-- set spell stance in case actor uses hotkey to switch to spells

--Actor.spells(actor)
-- returns all given spells of a actor which may be 'nil'


-- functions :
-- A mechanism to bake hotkey assignments into save (onSave + Lua Tables)
-- Load the above ( onLoad )
-- 

-- Flow:
-- (Load) Retrieve hotkey assignments if any
-- hotkey 1- has 9 or dynamic sized map and the same for all 9 hotkeys 
-- -> 81 min hotkeys using cyclical selection and fsm
-- detect onKeyPress for chosen hotkeys and mod menu
-- display on top left what spell is registered
-- Skip UI if needed and use console print for confirmation displays 

-- FSM:
-- mod key -> \
-- Press \ then hotkey number then 1-9 overwrite cycle