local camera   = require('openmw.camera')
local core     = require('openmw.core')
local nearby   = require('openmw.nearby')
local self_obj = require('openmw.self')
local util     = require('openmw.util')
local input    = require('openmw.input')
local types    = require('openmw.types')
local ui       = require('openmw.ui')
local I        = require('openmw.interfaces')
local storage  = require('openmw.storage')
local async    = require('openmw.async')

local CFG = {
  scanRadius         = core.getGMST('iMaxActivateDist'),
  maxListEntries     = 10,
  onlyInThirdPerson  = false,
  preferActors       = true,
  pickupAllHoldTime  = 3.0,
  pickupAllBarDelay  = 0.3,  -- seconds of hold before pick-all bar appears
  openHoldTime       = 1.0,   -- seconds to hold chooseit before UI opens
  dismissDistance    = 64,    -- units walked before UI auto-closes
  filterHarvestedPlants = true,  -- hide organic containers that are resolved+empty (GH harvested plants)
  controllerDpadUp   = input.CONTROLLER_BUTTON.DPadUp,
  controllerDpadDown = input.CONTROLLER_BUTTON.DPadDown,
  debug              = true,
}

I.Settings.registerPage({
   key         = 'ACTIVATE',
   l10n        = 'BTPs',
   name        = 'Better Third Person Selection',
   description = 'Better Third Person Selection',
})

input.registerAction {
   key          = 'activateit',
   type         = input.ACTION_TYPE.Boolean,
   l10n         = 'BTPs',
   name         = 'Activation Key',
   description  = 'Key used to interact with the highlighted object',
   defaultValue = false,
}

input.registerAction {
   key          = 'chooseit',
   type         = input.ACTION_TYPE.Boolean,
   l10n         = 'BTPs',
   name         = 'Choose item Key',
   description  = 'Hold to open selection UI; tap again to close',
   defaultValue = false,
}

input.registerAction {
   key          = 'selectit',
   type         = input.ACTION_TYPE.Boolean,
   l10n         = 'BTPs',
   name         = 'Select item Key',
   description  = 'Key used to cycle to next object',
   defaultValue = false,
}


I.Settings.registerGroup({
   key              = 'SettingsBTPs_group',
   page             = 'ACTIVATE',
   l10n             = 'BTPs',
   name             = 'Activation Key',
   permanentStorage = true,
   settings = {
       {
           key         = 'activateit',
           renderer    = 'inputBinding',
           name        = 'Activation Key',
           description = 'Key used to interact with the highlighted object',
           default     = 'E',
           argument    = { type = 'action', key = 'activateit' },
       },
       {
           key         = 'chooseit',
           renderer    = 'inputBinding',
           name        = 'Choose item Key',
           description = 'Hold to open selection UI; tap again to close',
           default     = 'LeftShift',
           argument    = { type = 'action', key = 'chooseit' },
       },
       {
           key         = 'selectit',
           renderer    = 'inputBinding',
           name        = 'Select item Key',
           description = 'Key used to cycle to next object',
           default     = 'LeftAlt',
           argument    = { type = 'action', key = 'selectit' },
       },
       {
           key         = 'onlyInThirdPerson',
           renderer    = 'checkbox',
           name        = 'Only in Third Person',
           description = 'If enabled, selection UI only activates in third person camera mode',
           default     = false,
       },
   },
})

-- read persistent settings; nil = first run, fall back to CFG defaults
local btpsSection = storage.playerSection('SettingsBTPs_group')
CFG.onlyInThirdPerson = btpsSection:get('onlyInThirdPerson') or CFG.onlyInThirdPerson

-- live update when user changes settings in Options
btpsSection:subscribe(async:callback(function(_, key)
    if key == 'onlyInThirdPerson' then
        CFG.onlyInThirdPerson = btpsSection:get('onlyInThirdPerson')
        if CFG.debug then print("[BTPS] onlyInThirdPerson changed to " .. tostring(CFG.onlyInThirdPerson)) end
    end
end))

-- startup diagnostic: log all resolved CFG values and API constants so
-- mismatches between assumptions and actual OpenMW values are caught immediately
do
    print("[BTPS] === STARTUP ===")
    print("[BTPS] input.CONTROLLER_BUTTON.DPadUp   = " .. tostring(input.CONTROLLER_BUTTON.DPadUp))
    print("[BTPS] input.CONTROLLER_BUTTON.DPadDown = " .. tostring(input.CONTROLLER_BUTTON.DPadDown))
    print("[BTPS] input.CONTROLLER_BUTTON.DPadLeft = " .. tostring(input.CONTROLLER_BUTTON.DPadLeft))
    print("[BTPS] input.CONTROLLER_BUTTON.DPadRight= " .. tostring(input.CONTROLLER_BUTTON.DPadRight))
    print("[BTPS] CFG.controllerDpadUp   = " .. tostring(CFG.controllerDpadUp))
    print("[BTPS] CFG.controllerDpadDown = " .. tostring(CFG.controllerDpadDown))
    print("[BTPS] CFG.scanRadius         = " .. tostring(CFG.scanRadius) .. " (iMaxActivateDist)")
    print("[BTPS] CFG.openHoldTime       = " .. tostring(CFG.openHoldTime))
    print("[BTPS] CFG.dismissDistance    = " .. tostring(CFG.dismissDistance))
    print("[BTPS] CFG.filterHarvestedPlants = " .. tostring(CFG.filterHarvestedPlants))
    print("[BTPS] CFG.debug              = " .. tostring(CFG.debug))
    print("[BTPS] === END STARTUP ===")
end

-- runtime state
local pickerOpen    = false
local objectList    = {}
local selectedIndex = 1
local uiLayout      = nil
						   

local holdTimer     = 0.0
local holdTriggered = false
local activatePrev  = false

local selectPrev    = false

-- toggle-mode open state
local openHoldTimer    = 0.0
local openHoldDone     = false  -- true after hold completed; suppresses first release
local choosePrev       = false
local openPosition     = nil    -- player position when UI was opened
local openingBarLayout = nil

local nothingFoundLayout = nil

-- ─── helpers ──────────────────────────────────────────────────────────────────

local function isThirdPerson()
  local m = camera.getMode()
  return m == camera.MODE.ThirdPerson or m == camera.MODE.Preview
end

local function shouldRun()
  return (not CFG.onlyInThirdPerson) or isThirdPerson()
end

local function isInteractable(obj)
  if not obj or obj == self_obj then return false end
  local t = obj.type
				   
  if t == types.NPC or t == types.Creature or t == types.Door then
							 
							 
      return true
  end
  if t == types.Container then
      if CFG.filterHarvestedPlants then
          -- only organic containers (plants) are filtered — chests/barrels always show
          local recOk, rec = pcall(function() return types.Container.record(obj) end)
          if recOk and rec and rec.isOrganic then
              local cOk, content = pcall(function() return types.Container.content(obj) end)
              if not cOk then
                  if CFG.debug then print("[BTPS] isInteractable: Container.content() failed for " .. tostring(obj.recordId)) end
              elseif content:isResolved() then
                  local iOk, items = pcall(function() return content:getAll() end)
                  if iOk and items and #items == 0 then
                      if CFG.debug then print("[BTPS] isInteractable: skipping harvested plant " .. tostring(obj.recordId)) end
                      return false
                  end
              end
          end
      end
      return true
  end
  if t == types.Light then
      local ok, rec = pcall(function() return types.Light.record(obj) end)
      if not ok or not rec then return false end
      return rec.isCarriable == true
  end
  if t == types.Activator then return true end
  return t == types.Weapon
      or t == types.Armor
      or t == types.Clothing
      or t == types.Book
      or t == types.Potion
      or t == types.Ingredient
      or t == types.Miscellaneous
      or t == types.Lockpick
      or t == types.Probe
      or t == types.Repair
      or t == types.Apparatus
      or t == types.Ammo
      or t == types.Key
      or t == types.Scroll
end

-- true for loose world items that activateBy picks up, or organic containers (GH harvest)
local function isPickable(obj)
  local t = obj.type
  if t == types.Container then
      local ok, rec = pcall(function() return types.Container.record(obj) end)
      return ok and rec and rec.isOrganic == true
  end
  if t == types.Light then
      local ok, rec = pcall(function() return types.Light.record(obj) end)
      return ok and rec and rec.isCarriable == true
  end
  return t == types.Weapon
      or t == types.Armor
      or t == types.Clothing
      or t == types.Book
      or t == types.Potion
      or t == types.Ingredient
      or t == types.Miscellaneous
      or t == types.Lockpick
      or t == types.Probe
      or t == types.Repair
      or t == types.Apparatus
      or t == types.Ammo
      or t == types.Key
      or t == types.Scroll
end

local function getObjectName(obj)
  local ok, name = pcall(function()
      return obj.type.record(obj).name
  end)
  if ok and name and name ~= "" then return name end
  return tostring(obj.recordId or "???")
end

local function distanceTo(obj)
  local ok, pos = pcall(function() return obj.position end)
  if not ok or not pos then return 99999 end
  return (self_obj.position - pos):length()
end

local function getIconPath(obj)
  local t = obj.type
						
  if t == types.NPC       then return "icons/npc_icon.dds"       end
							 
  if t == types.Door      then return "icons/door_icon.dds"      end
								  
  if t == types.Container then return "icons/container_icon.dds" end
								 
  if t == types.Creature  then return "icons/creature_icon.dds"  end
								  
  if t == types.Activator then return "icons/activator_icon.dds" end
	 

  local ok, rec = pcall(function() return obj.type.record(obj) end)
  if not ok or not rec then return "icons/noicon.dds" end

  local iconField = nil
  pcall(function() iconField = rec.icon end)

  if not iconField or type(iconField) ~= "string" or iconField:match("^%s*$") then
      return "icons/noicon.dds"
  end

  local path = string.lower(string.gsub(iconField, '\\', '/'))
  if path == "" then return "icons/noicon.dds" end
  return path
end

local function gatherObjects()
  local list = {}
  local seen = {}
  local function tryAdd(obj)
      if seen[obj.id] then return end
      seen[obj.id] = true
      if isInteractable(obj) and distanceTo(obj) <= CFG.scanRadius then
          table.insert(list, obj)
      end
  end
  for _, obj in ipairs(nearby.actors)     do tryAdd(obj) end
  for _, obj in ipairs(nearby.items)      do tryAdd(obj) end
  for _, obj in ipairs(nearby.doors)      do tryAdd(obj) end
  for _, obj in ipairs(nearby.containers) do tryAdd(obj) end
  for _, obj in ipairs(nearby.activators) do tryAdd(obj) end
  table.sort(list, function(a, b)
      if CFG.preferActors then
          local aActor = (a.type == types.NPC or a.type == types.Creature)
          local bActor = (b.type == types.NPC or b.type == types.Creature)
          if aActor ~= bActor then return aActor end
      end
      return distanceTo(a) < distanceTo(b)
  end)
  while #list > CFG.maxListEntries do table.remove(list) end
  if CFG.debug then print("[BTPS] gatherObjects: found " .. #list .. " object(s)") end
  return list
end

-- maintains stable order while picker is open:
-- removes objects that left range, appends newly appeared objects at end
local function refreshObjectListStable()
  -- build fresh nearby set keyed by id (items not in world won't appear here)
  local nearbyById = {}
  for _, obj in ipairs(nearby.actors)     do nearbyById[obj.id] = obj end
  for _, obj in ipairs(nearby.items)      do nearbyById[obj.id] = obj end
  for _, obj in ipairs(nearby.doors)      do nearbyById[obj.id] = obj end
  for _, obj in ipairs(nearby.containers) do nearbyById[obj.id] = obj end
  for _, obj in ipairs(nearby.activators) do nearbyById[obj.id] = obj end

  -- keep existing in stable order; use fresh ref from nearby
  local inList  = {}
  local filtered = {}
  for _, obj in ipairs(objectList) do
      local fresh = nearbyById[obj.id]  -- nil if picked up / out of range / gone
      if fresh and isInteractable(fresh) and distanceTo(fresh) <= CFG.scanRadius then
          table.insert(filtered, fresh)
          inList[obj.id] = true
      end
  end

  -- append new objects at end (no re-sort)
  for id, obj in pairs(nearbyById) do
      if not inList[id] and isInteractable(obj) and distanceTo(obj) <= CFG.scanRadius then
          table.insert(filtered, obj)
          inList[id] = true
      end
  end

  while #filtered > CFG.maxListEntries do table.remove(filtered) end
  return filtered
end

-- ─── UI ───────────────────────────────────────────────────────────────────────

local ICON_SIZE  = 32
local ICON_PAD   = 4
local ROW_HEIGHT = 36
local BAR_WIDTH  = 220

local function buildUI()
  if uiLayout then uiLayout:destroy(); uiLayout = nil end
  if #objectList == 0 then return end

  local rows = {}

  table.insert(rows, {
      type  = ui.TYPE.Text,
      props = {
          text      = "-- Nearby Objects --",
          textSize  = 15,
          textColor = util.color.rgb(1, 0.85, 0.25),
      },
  })

  for i, obj in ipairs(objectList) do
      local sel      = (i == selectedIndex)
      local txtColor = sel and util.color.rgb(1, 1, 0)
                            or util.color.rgb(0.75, 0.75, 0.75)
      local label    = string.format("%s%s  [%d]",
                           sel and "> " or "  ",
                           getObjectName(obj),
                           math.floor(distanceTo(obj)))
									   

					  
      local rowContent = ui.content({
              {
                  type  = ui.TYPE.Image,
                  props = {
                      position = util.vector2(0, 0),
                      size     = util.vector2(ICON_SIZE, ICON_SIZE),
                      resource = ui.texture({ path = getIconPath(obj) }),
                      color    = sel and util.color.rgb(1, 1, 1)
                                      or util.color.rgb(0.6, 0.6, 0.6),
                  },
              },
              {
                  type  = ui.TYPE.Text,
                  props = {
                      position  = util.vector2(ICON_SIZE + ICON_PAD, 8),
                      text      = label,
                      textSize  = 14,
                      textColor = txtColor,
                  },
              },
          })
							  
									   
																 
								   
			
		  
							  
								   
					   
									
								 
									   
				
			
      table.insert(rows, {
          type    = ui.TYPE.Widget,
          props   = { size = util.vector2(320, ROW_HEIGHT) },
          content = rowContent,
      })
  end

  -- hold-to-pick-all progress bar (only after dead zone)
  if holdTimer > CFG.pickupAllBarDelay and not holdTriggered then
      local progress  = math.min(holdTimer / CFG.pickupAllHoldTime, 1.0)
      local fillWidth = math.floor(BAR_WIDTH * progress)

      local barColor
      if progress < 0.5 then
          local t = progress * 2
          barColor = util.color.rgb(1, 0.85 * t + (1 - t), (1 - t) * 0.8)
      else
          local t = (progress - 0.5) * 2
          barColor = util.color.rgb(1 - t, 0.85 + 0.15 * t, t * 0.3)
      end

      local secsLeft = math.ceil(CFG.pickupAllHoldTime - holdTimer)
      local barLabel = string.format("Hold to pick ALL: %ds", secsLeft)

      local barContent = ui.content({
          {
              type  = ui.TYPE.Widget,
              props = {
                  position = util.vector2(0, 0),
                  size     = util.vector2(BAR_WIDTH, 10),
              },
          },
          {
              type  = ui.TYPE.Image,
              props = {
                  position = util.vector2(0, 0),
                  size     = util.vector2(fillWidth, 10),
                  resource = ui.texture({ path = "textures/white.dds" }),
                  color    = barColor,
              },
          },
          {
              type  = ui.TYPE.Text,
              props = {
                  position  = util.vector2(0, 14),
                  text      = barLabel,
                  textSize  = 12,
                  textColor = barColor,
              },
          },
      })

      table.insert(rows, {
          type    = ui.TYPE.Widget,
          props   = { size = util.vector2(BAR_WIDTH, 30) },
          content = barContent,
      })
  end

  table.insert(rows, {
      type  = ui.TYPE.Text,
      props = {
          text      = "Scroll/D-Pad = cycle   Activate = pick up or use   Hold Activate 3s = pick ALL   tap Highlight or walk away = close",
          textSize  = 11,
          textColor = util.color.rgb(0.5, 0.5, 0.5),
      },
  })

  uiLayout = ui.create({
      layer = "HUD",
      type  = ui.TYPE.Flex,
      props = {
          relativePosition = util.vector2(0.02, 0.35),
          anchor           = util.vector2(0, 0),
          vertical         = true,
      },
      content = ui.content(rows),
  })
end

-- opening-hold progress bar (shown before picker is open)
local function buildOpeningBar()
  if openingBarLayout then openingBarLayout:destroy() end
  local progress  = math.min(openHoldTimer / CFG.openHoldTime, 1.0)
  local fillWidth = math.floor(BAR_WIDTH * progress)
  local barColor  = util.color.rgb(0.4, 0.8, 1.0)

  openingBarLayout = ui.create({
      layer = "HUD",
      type  = ui.TYPE.Flex,
      props = {
          relativePosition = util.vector2(0.02, 0.35),
          anchor           = util.vector2(0, 0),
          vertical         = true,
      },
      content = ui.content({
          {
              type  = ui.TYPE.Text,
              props = {
                  text      = "Hold to open selection...",
                  textSize  = 12,
                  textColor = barColor,
              },
          },
          {
              type    = ui.TYPE.Widget,
              props   = { size = util.vector2(BAR_WIDTH, 14) },
              content = ui.content({
                  {
                      type  = ui.TYPE.Widget,
                      props = { position = util.vector2(0, 0), size = util.vector2(BAR_WIDTH, 10) },
                  },
                  {
                      type  = ui.TYPE.Image,
                      props = {
                          position = util.vector2(0, 0),
                          size     = util.vector2(fillWidth, 10),
                          resource = ui.texture({ path = "textures/white.dds" }),
                          color    = barColor,
                      },
                  },
              }),
          },
      }),
  })
end

local function destroyOpeningBar()
  if openingBarLayout then openingBarLayout:destroy(); openingBarLayout = nil end
end

local function showNothingFound()
  if nothingFoundLayout then nothingFoundLayout:destroy() end
  nothingFoundLayout = ui.create({
      layer = "HUD",
      type  = ui.TYPE.Flex,
      props = {
          relativePosition = util.vector2(0.02, 0.38),  -- below opening bar position
          anchor           = util.vector2(0, 0),
          vertical         = true,
      },
      content = ui.content({
          {
              type  = ui.TYPE.Text,
              props = {
                  text      = "Nothing nearby.",
                  textSize  = 15,
                  textColor = util.color.rgb(0.6, 0.6, 0.6),
              },
          },
      }),
  })
end

local function destroyNothingFound()
  if nothingFoundLayout then nothingFoundLayout:destroy(); nothingFoundLayout = nil end
end

-- ─── picker lifecycle ─────────────────────────────────────────────────────────

local function openPicker()
  if pickerOpen then return end
  objectList = gatherObjects()
  selectedIndex = 1
  if #objectList == 0 then
      if CFG.debug then print("[BTPS] openPicker: no interactable objects nearby, showing feedback") end
      showNothingFound()
      return
  end
  if CFG.debug then print("[BTPS] openPicker: opening with " .. #objectList .. " object(s)") end
  pickerOpen   = true
  openPosition = self_obj.position
  buildUI()
end

local function closePicker()
  if not pickerOpen then return end
  pickerOpen    = false
  objectList    = {}
  holdTimer     = 0.0
  holdTriggered = false
  openHoldTimer = 0.0
  openHoldDone  = false
  openPosition  = nil
  destroyOpeningBar()
  if uiLayout then uiLayout:destroy(); uiLayout = nil end
end

local function pickupAllItems()
  for _, obj in ipairs(objectList) do
      if isPickable(obj) then
          if CFG.debug then print("[BTPS] pickupAllItems: picking up '" .. getObjectName(obj) .. "'") end
          pcall(function() obj:activateBy(self_obj) end)
      else
          if CFG.debug then print("[BTPS] pickupAllItems: skipping non-pickable '" .. getObjectName(obj) .. "' (" .. tostring(obj.type) .. ")") end
      end
  end
  closePicker()
end

local function getCrosshairObject()
  local ok, result = pcall(function()
      local from    = camera.getPosition()
      local dir     = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
      local maxDist = core.getGMST("iMaxActivateDist") + camera.getThirdPersonDistance()
      return nearby.castRenderingRay(from, from + dir * maxDist, { ignore = self_obj })
  end)
  if not ok then
      if CFG.debug then print("[BTPS] getCrosshairObject: ray failed — " .. tostring(result)) end
      return nil
  end
  if not result or not result.hitObject then return nil end
  if CFG.debug then print("[BTPS] getCrosshairObject: hit '" .. tostring(result.hitObject.recordId) .. "'") end
  return result.hitObject
end

local function onActivatePressed()
  if not pickerOpen then return end
  if #objectList > 0 then
      local target = objectList[selectedIndex]
      if target then
          local crosshair = getCrosshairObject()
          local crosshairId = crosshair and crosshair.id
          if CFG.debug then
              print("[BTPS] onActivatePressed: target='" .. getObjectName(target)
                  .. "' dist=" .. math.floor(distanceTo(target))
                  .. " crosshair=" .. tostring(crosshairId))
          end
          local crosshairInteractable = crosshair and isInteractable(crosshair)
          if CFG.debug then
              print("[BTPS] onActivatePressed: crosshairId=" .. tostring(crosshairId)
                  .. " interactable=" .. tostring(crosshairInteractable))
          end
          if crosshairId == target.id then
              -- crosshair matches selection: engine handles it, defer
              if CFG.debug then print("[BTPS] onActivatePressed: crosshair matches — deferring to engine") end
          elseif crosshairInteractable then
              -- crosshair is a different interactable (NPC, item, door…): user is activating that, stay quiet
              if CFG.debug then print("[BTPS] onActivatePressed: crosshair is different interactable — suppressing") end
              return
          else
              -- crosshair nil or hits non-interactable geometry: BTPS activates selection
              if CFG.debug then print("[BTPS] onActivatePressed: no interactable in crosshair — activating") end
              target:activateBy(self_obj)
          end
          local t = target.type
          if t == types.NPC or t == types.Creature then
              if CFG.debug then print("[BTPS] onActivatePressed: NPC/Creature interaction — closing picker") end
              closePicker()
              return
          end
      else
          if CFG.debug then print("[BTPS] onActivatePressed: selectedIndex=" .. selectedIndex .. " but target is nil") end
      end
  end
								 
																   
														   
end

-- dir: -1 = previous, +1 = next
local function cycleSelection(dir)
  if not pickerOpen then
      if CFG.debug then print("[BTPS] cycleSelection(" .. dir .. ") called but picker not open — ignored") end
      return
  end
  selectedIndex = selectedIndex + dir
  if selectedIndex < 1 then selectedIndex = #objectList end
  if selectedIndex > #objectList then selectedIndex = 1 end
  if CFG.debug then
      local name = objectList[selectedIndex] and getObjectName(objectList[selectedIndex]) or "nil"
      print("[BTPS] cycleSelection(" .. dir .. "): index=" .. selectedIndex .. " name='" .. name .. "'")
  end
  buildUI()
end

local function onMouseWheel(wheelDelta)
  cycleSelection(wheelDelta > 0 and -1 or 1)
						 
										
																
	   
										
																
	  
			
end

-- ─── per-frame logic ──────────────────────────────────────────────────────────

local function onFrame(dt)
  if not shouldRun() then
														   
									  
				  
										  
      closePicker()
      destroyOpeningBar()
      destroyNothingFound()
      openHoldTimer = 0.0
      openHoldDone  = false
      return
  end

  local chooseNow = input.getBooleanActionValue('chooseit')

  if not pickerOpen then
      if chooseNow then
          openHoldTimer = openHoldTimer + dt
          buildOpeningBar()
          if openHoldTimer >= CFG.openHoldTime and not openHoldDone then
              if CFG.debug then print("[BTPS] onFrame: hold threshold reached, opening picker") end
              openHoldDone = true
              destroyOpeningBar()
              openPicker()
          end
      else
          if openHoldTimer > 0 then
              destroyOpeningBar()
              openHoldTimer = 0.0
          end
          openHoldDone = false
          destroyNothingFound()
      end
  else
      if openHoldDone and not chooseNow then
          -- first release after hold-open: clear flag, do NOT close this frame
          if CFG.debug then print("[BTPS] onFrame: hold-open release ignored, clearing openHoldDone") end
          openHoldDone = false
      elseif not openHoldDone and not chooseNow and choosePrev then
          -- subsequent tap: close
          if CFG.debug then print("[BTPS] onFrame: tap-close triggered") end
          closePicker()
      -- distance-based dismiss
      elseif openPosition and (self_obj.position - openPosition):length() > CFG.dismissDistance then
          if CFG.debug then
              print("[BTPS] onFrame: distance dismiss triggered (" .. math.floor((self_obj.position - openPosition):length()) .. " units)")
          end
          closePicker()
      else
          -- refresh list: stable order, remove gone, append new
          local newList = refreshObjectListStable()
          local changed = #newList ~= #objectList
          if not changed then
              for i = 1, #newList do
                  if newList[i].id ~= objectList[i].id then changed = true; break end
              end
          end
          objectList = newList
          if changed then
              selectedIndex = math.min(selectedIndex, math.max(#objectList, 1))
              if #objectList == 0 then
                  closePicker()
              else
                  buildUI()
              end
          end
      end
  end

  choosePrev = chooseNow
end

local function onInputUpdate(dt)
  if not pickerOpen then
      activatePrev  = false
      selectPrev    = false
      holdTimer     = 0.0
      holdTriggered = false
      return
  end

  local activateNow = input.getBooleanActionValue('activateit')
  local selectNow   = input.getBooleanActionValue('selectit')

  -- hold-to-pick-all
  if activateNow then
      holdTimer = holdTimer + dt
      if holdTimer >= CFG.pickupAllHoldTime and not holdTriggered then
          holdTriggered = true
          pickupAllItems()
          holdTimer = 0.0
      else
          buildUI()
      end
  else
      if holdTimer > 0 then
          holdTimer     = 0.0
          holdTriggered = false
          buildUI()
      end
  end

  if not activateNow and activatePrev and not holdTriggered then
      onActivatePressed()
  end

  activatePrev = activateNow

  -- keyboard cycle: selectit only (getBooleanActionValue unreliable for gamepad
  -- when HUD is active — controller D-pad handled in onControllerButtonPress)
  if selectNow and not selectPrev then
      if CFG.debug then print("[BTPS] selectit edge → cycleSelection(1)") end
      cycleSelection(1)
									  
		  
				
  end
  selectPrev = selectNow
end

-- ─── exports ──────────────────────────────────────────────────────────────────

return {
  interfaceName = "BetterThirdPersonSelection",
  interface = {
      getTarget = function()
          if pickerOpen and #objectList > 0 then return objectList[selectedIndex] end
          return nil
      end,
      isActive  = function() return pickerOpen end,
													 
														
  },
  engineHandlers = {
      onFrame      = function(dt) onFrame(dt); onInputUpdate(dt) end,
      onMouseWheel = onMouseWheel,
      onControllerButtonPress = function(button)
          if button == nil then
              print("[BTPS] WARNING: onControllerButtonPress received nil — wrong handler signature or OpenMW API changed")
              return
          end
          if CFG.debug then
              print("[BTPS] onControllerButtonPress: button=" .. tostring(button)
                  .. (button == CFG.controllerDpadUp   and " (=DPadUp)"   or "")
                  .. (button == CFG.controllerDpadDown and " (=DPadDown)" or ""))
          end
          if pickerOpen then
              if button == CFG.controllerDpadDown then
                  cycleSelection(1)
                  return true  -- consume: block engine + other scripts
              end
              if button == CFG.controllerDpadUp then
                  cycleSelection(-1)
                  return true
              end
          end
      end,
  },
}
