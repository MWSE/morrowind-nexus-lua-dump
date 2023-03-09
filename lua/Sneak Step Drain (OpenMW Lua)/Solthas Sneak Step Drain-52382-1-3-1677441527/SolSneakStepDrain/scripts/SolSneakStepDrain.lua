local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
-- shorthand for convenience
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills

-- settings functions
local function boolSetting(sKey, sDef)
    return {
        key = sKey,
        renderer = 'checkbox',
        name = sKey..'_name',
        description = sKey..'_desc',
        default = sDef,
    }
end
local function numbSetting(sKey, sDef, sInt, sMin, sMax)
    return {
        key = sKey,
        renderer = 'number',
        name = sKey..'_name',
        description = sKey..'_desc',
        default = sDef,
    argument = {
      integer = sInt,
      min = sMin,
      max = sMax,
    },
    }
end
-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
I.Settings.registerPage({
   key = 'SolSneakStepDrain',
   l10n = 'SolSneakStepDrain',
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
local verbose = false
local uiShow = true
local buffBase = 0.5
local maxDrain = 9.0
local maxCharge = 3.0
local chargeInterval = 0.5
local uiXcoord = 0.0
local uiYcoord = 1.0
local uiLength = 72
I.Settings.registerGroup({
  key = 'Settings_SolSneakStepDrain',
  page = 'SolSneakStepDrain',
  l10n = 'SolSneakStepDrain',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled',enabled),
    boolSetting('verbose',verbose),
    boolSetting('uiShow',uiShow),
    numbSetting('buffBase',buffBase, false,0.1,2.0),
    numbSetting('maxCharge',maxCharge, false,1.0,20.0),
    numbSetting('maxDrain',maxDrain, false,1.0,20.0),
    numbSetting('chargeInterval',chargeInterval, false,0.1,1.0),
    numbSetting('uiXcoord',uiXcoord, false,0.0,1.0),
    numbSetting('uiYcoord',uiYcoord, false,0.0,1.0),
    numbSetting('uiLength',uiLength, true,10,1000),
   },
})
local settingsGroup = storage.playerSection('Settings_SolSneakStepDrain')


-- ui junk -- adapted from AttendMe\scripts\AttendMe\hud.lua
local isSneak = false
local util = require('openmw.util')
local uiElement = nil
-- setup ui table thing
local statSize = util.vector2(61, 8)
local statTexture = ui.texture({ path = 'textures/menu_bar_gray.dds' })
local statColors = util.color.rgb(250/255, 250/255, 100/255) -- bright yellow
local uiLayout = {
  layer = 'HUD',
  name = 'sneakBar',
  template = I.MWUI.templates.boxTransparent,
  props = {},
  content = ui.content({
    {
      name = 'box',
      props = {
        size = statSize,
      },
      content = ui.content({
        {
          name = 'image',
          type = ui.TYPE.Image,
          props = {
            size = statSize,
            resource = statTexture,
            color = statColors,
            arrange = ui.ALIGNMENT.Start,
          },
        },
      }),
    },
  }),
}
-- position in bottom left
local hudPosition = util.vector2(0.0, 1.0)
uiLayout.props.relativePosition = hudPosition
uiLayout.props.anchor = hudPosition
--uiLayout.props.position = (util.vector2(1, 1) - hudPosition * 2)
uiLayout.props.position = (util.vector2(1, 1) - hudPosition * 2):emul(util.vector2(13 + 61 + 8, 12 + 15*3))
local function updateUI(current, max)
  -- update bar size
  uiLayout.content.box.content.image.props.size = statSize:emul(util.vector2(math.abs((current+max)/(2*max)), 1)) -- no outline
  -- ui element update / create / destroy logic
  if enabled and ((current ~= 0) or (isSneak and current == 0)) then
    if uiElement then
      uiElement:update()
    else
      uiElement = ui.create(uiLayout)
    end
    else
    if uiElement then 
      uiElement:destroy()
    end
    uiElement = nil
  end
end

-- okayyyyyyyyyyy back to settings now that I've initialized the ui element
-- update settings
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  uiShow = settingsGroup:get('uiShow')
  buffBase = settingsGroup:get('buffBase')
  maxDrain = settingsGroup:get('maxDrain')
  maxCharge = settingsGroup:get('maxCharge')
  chargeInterval = settingsGroup:get('chargeInterval')
  -- update ui settings...
  uiLength = settingsGroup:get('uiLength')
    statSize = util.vector2(uiLength, 8)
    uiLayout.content.box.props.size = statSize
    uiLayout.content.box.content.image.props.size = statSize
  uiXcoord = settingsGroup:get('uiXcoord')
  uiYcoord = settingsGroup:get('uiYcoord')
    hudPosition = util.vector2(uiXcoord, uiYcoord)
    uiLayout.props.relativePosition = hudPosition
    uiLayout.props.anchor = hudPosition
	if uiXcoord == 0.0 and uiYcoord == 1.0 then
	  uiLayout.props.position = (util.vector2(1, 1) - hudPosition * 2):emul(util.vector2(13 + 61 + 8, 12 + 15*3))
	else
	  uiLayout.props.position = (util.vector2(1, 1) - hudPosition * 2)
	end
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- stance effects 
local function sneakMod(modSign,modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    skills.sneak(self).modifier = math.max(0,skills.sneak(self).modifier + modSign*modVal)
  elseif modVal < 0 then
    modVal = math.abs(modVal)
    skills.sneak(self).damage = math.max(0,skills.sneak(self).damage + modSign*modVal)
  end
end
-- get effect of armor etc
local function getWeights()
  -- get athletics and acrobatics, which help you move quietly
  local acrob = skills.acrobatics(self).modified
  local athle = skills.athletics(self).modified
  
  -- shoes
  local weightBoots = 0 -- if nothing equipped
  local weightPants = 0
  local weightShirt = 0
  local armorRatio = 0.7 -- fraction for armor, 1-it is fraction for weapon
  local ratioBoots = 0.6 -- overall fraction: boots
  local ratioPants = 0.2 -- pants
  local ratioShirt = 0.2 -- shirt
  -- armor and clothing records aren't implemented yet in 0.48, so let's test.
  -- shoes
  local recordBoots = types.Actor.equipment(self,types.Actor.EQUIPMENT_SLOT.Boots)
  if recordBoots == nil then -- wearing nothing in slot
    -- no modification
  elseif recordBoots.type.record == nil then -- 0.48 check
    -- find a 0.48 viable workaround.
    ratioBoots = 0.5*ratioBoots -- lower ratio because lower confidence
    weightBoots = 20 -- assume weight
  else
    if recordBoots then -- I don't think I need this since I'm checking for it above
      weightBoots = recordBoots.type.record(recordBoots).weight
    end
  end
  -- pants
  local recordPants = types.Actor.equipment(self,types.Actor.EQUIPMENT_SLOT.Greaves)
  -- Due to limited 0.48 functionality where I'll get slot overlap on assuming the armor slot's weight, I will comment this section out.
  --if recordPants == nil then -- if no greaves, try pants
  --  recordPants = types.Actor.equipment(self,types.Actor.EQUIPMENT_SLOT.Pants)
  --end
  -- what about skirt?
  if recordPants == nil then -- wearing nothing in slot
    -- no modification
  elseif recordPants.type.record == nil then -- 0.48 check
    -- find a 0.48 viable workaround.
    ratioPants = 0.5*ratioPants -- lower ratio because lower confidence
    weightPants = 20 -- assume weight
  else
    if recordPants then
      weightPants = recordPants.type.record(recordPants).weight
    end
  end
  -- shirt 
  local recordShirt = types.Actor.equipment(self,types.Actor.EQUIPMENT_SLOT.Cuirass)
  -- Due to limited 0.48 functionality where I'll get slot overlap on assuming the armor slot's weight, I will comment this section out.
  --if recordShirt == nil then -- if no cuirass, try shirt
  --  recordShirt = types.Actor.equipment(self,types.Actor.EQUIPMENT_SLOT.Shirt)
  --end
  -- what about robe?
  if recordShirt == nil then -- wearing nothing in slot
    -- no modification
  elseif recordShirt.type.record == nil then -- 0.48 check
    -- find a 0.48 viable workaround.
    ratioShirt = 0.5*ratioShirt -- lower ratio because lower confidence
    weightShirt = 20 -- assume weight
  else
    if recordShirt then
      weightShirt = recordShirt.type.record(recordShirt).weight
    end
  end
  -- recalculate total armor ratio, for sake of weapon
  armorRatio = armorRatio*(ratioBoots + ratioPants + ratioShirt)
  
  -- if weapon out, get weight of weapon
  local weightWeapon = 0 -- none, or handtohand
  if types.Actor.stance(self) == types.Actor.STANCE.Weapon then
    local recordWeapon = types.Actor.equipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if recordWeapon then 
      if not types.Lockpick.objectIsInstance(recordWeapon) and not types.Probe.objectIsInstance(recordWeapon) then
        weightWeapon = types.Weapon.record(recordWeapon).weight
      end
    end 
  end

  -- get total modifier / multiplier for each
  local modArmor = math.sqrt(1 + ratioBoots*weightBoots + ratioPants*weightPants + ratioShirt*weightShirt)
  local modWeapon = math.sqrt(1 + weightWeapon)
  local modAcrob = 100/(acrob+50)
  local modAthle = 100/(athle+50)
  return (armorRatio*modArmor + (1-armorRatio)*modWeapon)*modAcrob*modAthle
end

local buffTotal = 0
-- save state to be removed on load
local function onSave()
    return{
      buffTotal = buffTotal
    }
end
local function onLoad(data)
  if data then
    buffTotal = data.buffTotal
    sneakMod(-1,buffTotal)
  end
end

local tickCounter = 0
local chargeTime = 0
local chargeHit = false
local buffType = 0
local perTick = 0
local maxMod = 0
local showVerbose = {1, 0, 1} -- min, neutral, max -- do not start by showing neutral, as that would trigger immediately
return { 
  engineHandlers = { 
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,
    
    onUpdate = function(dt)
  
    if uiShow then
      if chargeHit then -- only update ui if chargetime triggered
        updateUI(buffTotal, maxMod)
      end
    else
      if uiElement then 
        uiElement:destroy()
      end
      uiElement = nil
    end
  
    if enabled then       
      isSneak = self.controls.sneak -- 0.49 sneak check
      if isSneak == nil then
          isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check
      end
    
        if isSneak or buffTotal ~= 0 then
          -- Where to determine max sneak, armor modifier, and timers?
          -- Do it once on the first frame we press sneak? 
          -- Do it only when timer triggers? Probably.
          local mf = self.controls.movement
          local ms = self.controls.sideMovement
          
          if (mf == 0 and ms == 0) then
            buffType = 1 -- not moving = increase sneak value over time
          else
            buffType = 2 -- moving = reduce sneak value over time
          end
          -- if not sneaking... I must return it to neutral
          if (buffTotal < 0 and not isSneak) then
            buffType = -1 -- not sneaking, slowly increase back to neutral
          elseif (buffTotal > 0 and not isSneak) then
            buffType = -2 -- not sneaking, quickly decrease back to neutral
          end
        
          chargeTime = chargeTime + dt -- increment timer only if sneaking
          if chargeTime >= chargeInterval then
          chargeHit = true
          chargeTime = 0
          -- determine max allowed sneak modifier
          maxMod = math.ceil(buffBase*(skills.sneak(self).modified - buffTotal)) -- must subtract out this mod's current modifier
          if math.abs(buffType) == 1 then
            -- if charging, get change per tick as percentage of charge time
            --perTick = math.ceil((maxMod/maxCharge)*chargeInterval/math.sqrt(getWeights()))
            perTick = (maxMod/maxCharge)*chargeInterval/math.sqrt(getWeights())
            --perTick = ((maxMod/maxCharge)*chargeInterval/math.sqrt(getWeights()))
            if buffType < 0 then -- if not sneaking, gain at reduced rate
                perTick = 0.5*perTick -- gain at half rate
            end
            if buffTotal >= 0 then -- add modifier, else remove damage
              -- we want to add modifier, so do not go above max buff
              perTick = math.min(perTick,maxMod-buffTotal)
			  tickCounter = tickCounter + perTick
			  if tickCounter >= 1 then
				perTick = math.floor(tickCounter)
				sneakMod(1,perTick)
				buffTotal = buffTotal+perTick
				tickCounter = tickCounter - perTick
			  end
            else
              -- we want to remove damage, so do not go above 0
              perTick = math.min(perTick,0-buffTotal)           
			  tickCounter = tickCounter + perTick
			  if tickCounter >= 1 then
				perTick = math.floor(tickCounter)
				sneakMod(-1,-perTick)
				buffTotal = buffTotal+perTick
				tickCounter = tickCounter - perTick
			  end
            end
          elseif math.abs(buffType) == 2 then
            -- if releasing, get change per tick as raw drain value
            --perTick = math.ceil(maxDrain*getWeights()*chargeInterval)
            --perTick = math.ceil(100*maxDrain*getWeights()*chargeInterval)/100
            perTick = (maxMod/maxDrain)*chargeInterval*getWeights()
            --perTick = (maxDrain*getWeights()*chargeInterval)
            if buffType < 0 then -- if not sneaking, gain at reduced rate
                perTick = 1.5*perTick -- decrease at double rate
            end
            if buffTotal <= 0 then -- add damage, else remove modifier
              -- we want to add damage, so do not go below negative max buff
              perTick = math.min(perTick,maxMod+buffTotal)
			  tickCounter = tickCounter + perTick
			  if tickCounter >= 1 then
				perTick = math.floor(tickCounter)
				sneakMod(1,-perTick)  
				buffTotal = buffTotal-perTick
				tickCounter = tickCounter - perTick
			  end
            else
              -- we want to remove modifier, so do not go below 0
              perTick = math.min(perTick,0+buffTotal)
			  tickCounter = tickCounter + perTick
			  if tickCounter >= 1 then
				perTick = math.floor(tickCounter)
				sneakMod(-1,perTick)
				buffTotal = buffTotal-perTick
				tickCounter = tickCounter - perTick
			  end
            end
          end
          if verbose then  
			--ui.showMessage('mod '.. tostring(skills.sneak(self).modifier).. ', dmg '.. tostring(skills.sneak(self).damage).. ', buffTotal '.. tostring(buffTotal))
            if showVerbose[3] == 1 and buffTotal == maxMod then
              showVerbose = {1, 1, 0}
              ui.showMessage('SNEAK + '..tostring(maxMod))
            elseif showVerbose[2] == 1 and buffTotal == 0 then
              showVerbose = {1, 0, 1}
              ui.showMessage('SNEAK RESET')
            elseif showVerbose[1] == 1 and buffTotal == -maxMod then
              showVerbose = {0, 1, 1}
              ui.showMessage('SNEAK - '..tostring(maxMod))
            end
          end
          else
          chargeHit = false
          end
        end
      end
    end
  }
}