--This script is based on Solthas "Bow Aim Activate"
--local core = require('openmw.core')
local camera = require('openmw.camera')
local util = require('openmw.util')
local ui = require('openmw.ui')
--local nearby = require('openmw.nearby')
local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local skills = require('openmw.types').NPC.stats.skills
local Weapon = require('openmw.types').Weapon
local input = require('openmw.input')
local dynamic = require('openmw.types').Actor.stats.dynamic

local SniperScoreImage = ui.texture { path = 'icons/robo_wind/sniper_score.png' } --прицел
local element = nil --слой HUD прицела

--функция рендера прицела
local function renderSniperScore()

    local layout = {
        layer = 'HUD',
        props = {
            --size = util.vector2(512, 512),
			size = util.vector2(1, 1) * math.min(ui.screenSize().x, ui.screenSize().y) * 0.75,
            relativePosition = util.vector2(0.5, 0.5),
			--anchor = util.vector2(0.496, 0.517),
			anchor = util.vector2(0.5, 0.5),
        },
        content = ui.content {}
    }
    layout.content:add {
        type = ui.TYPE.Image,
        props = {
            relativeSize = util.vector2(1, 1),
            resource = SniperScoreImage,
			--anchor = (0,5, 0,5),
        },
    }
	if not element then element = ui.create(layout)
	ui.showMessage('Precise aiming mode - ACTIVATE') -- проверочное сообщение
	end
end --конец функции рендера прицела

--функция удаления снайперского прицела
local function DestroySniperScore()
	if element then
	element:destroy()
	element = nil
	--ui.showMessage ('scope destroyed') --проверочное сообщение
	end
end

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
local async = require('openmw.async')
I.Settings.registerPage({
   key = 'Sniper', --мое
   l10n = 'Sniper', --мое
   name = 'name',
   description = 'description',
})
-- default values!
local enabled = true
--local includeThrown = false  -- моё
local fatigueBow = 3.0
local fatigueZoom = 6.0
local enabledFirstPerson = true
--local enabledThirdPerson = true --3лицо
--local combatOffsetX = 0 --3лицо
--local combatOffsetY = 0 --3лицо
--local aimingOffsetX = -10 --3лицо
--local aimingOffsetY = -5 --3лицо
I.Settings.registerGroup({
  key = 'Settings_Sniper', --моё
  page = 'Sniper', --мое
  l10n = 'Sniper', --мое
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled',enabled),
    --boolSetting('includeThrown',includeThrown),  -- моё
    numbSetting('fatigueBow',fatigueBow, false,0,10),
    numbSetting('fatigueZoom',fatigueZoom, false,0,10),
    boolSetting('enabledFirstPerson',enabledFirstPerson),
    --boolSetting('enabledThirdPerson',enabledThirdPerson),
    --numbSetting('combatOffsetX',combatOffsetX, true,-100,100),  --3лицо
    --numbSetting('combatOffsetY',combatOffsetY, true,-100,100),  --3лицо
    --numbSetting('aimingOffsetX',aimingOffsetX, true,-100,100),  --3лицо
    --numbSetting('aimingOffsetY',aimingOffsetY, true,-100,100),  --3лицо
  },
})
local settingsGroup = storage.playerSection('Settings_Sniper') --моё
-- init
local combatOffset = util.vector2(40, -10)
local aimingOffset = util.vector2(10, -20)
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  --includeThrown = settingsGroup:get('includeThrown') --удалить??
  fatigueBow = settingsGroup:get('fatigueBow')
  fatigueZoom = settingsGroup:get('fatigueZoom')
  enabledFirstPerson = settingsGroup:get('enabledFirstPerson')
  --[[enabledThirdPerson = settingsGroup:get('enabledThirdPerson') --3лицо
  combatOffsetX = settingsGroup:get('combatOffsetX')  --3лицо
  combatOffsetY = settingsGroup:get('combatOffsetY')  --3лицо
  aimingOffsetX = settingsGroup:get('aimingOffsetX')  --3лицо
  aimingOffsetY = settingsGroup:get('aimingOffsetY')  --3лицо
    combatOffset = util.vector2(combatOffsetX, combatOffsetY)  --3лицо
    aimingOffset = util.vector2(aimingOffsetX, aimingOffsetY) --]] --3лицо
end
local function init()
    updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))



local function isBowPrepared()
    if Actor.stance(self) ~= Actor.STANCE.Weapon then return false end
    local item = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
    local weaponRecord = item and item.type == Weapon and Weapon.record(item)
    if not weaponRecord then return false end
  local returnType = (weaponRecord.type == Weapon.TYPE.MarksmanBow or weaponRecord.type == Weapon.TYPE.MarksmanCrossbow) -- no thrown
  --if includeThrown then
  --  returnType = (returnType or weaponRecord.type == Weapon.TYPE.MarksmanThrown)
  --end
    return returnType
end


-- hurt logic
local hurtTime = 0
local hurtZoom = 0
local hurtWait = 2 --исходно 2
-- init
local active = false
local counterMin, counterMax = 0, 2   --задержка?  -- исходно = -3, 2; если counterMin переставить в 0 или -1, то удаляется задержка при начале прицеливания
local counter = counterMin
local useAimingOffset = false
return {
  engineHandlers = { 
    -- init settings
    onActive = init,

    onUpdate = function(dt)
      if enabled then
        -- if arrow drawn and you're using a bow specifically... drain fatigue?
        if fatigueBow > 0 then
          -- do isBowPrepared() but specifically for bow
          if Actor.stance(self) == Actor.STANCE.Weapon then
            local usedWeapon = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)
            if (usedWeapon) then -- handtohand
              local weaponRecord = usedWeapon and usedWeapon.type == Weapon and Weapon.record(usedWeapon)
              if weaponRecord then
                -- if bow drawn
                if weaponRecord.type == Weapon.TYPE.MarksmanBow then
                  if input.isActionPressed(input.ACTION.Use) then
                    -- drain fatigue on timer
                    if dynamic.fatigue(self).current > 0 then -- if not out of fatigue
                      hurtTime = hurtTime + dt
                      if hurtTime >= hurtWait then -- if enough time has passed
                        hurtTime = 0
                        --local strength = Actor.stats.attributes.strength(self).modified  --удалена зависимость от силы при расчете выносливости
                        --local fatigueCost =  math.ceil(fatigueBow*math.sqrt(1 + weaponRecord.weight)*100/(strength+50)) --упрощена формула, стоимость по стамине задается только в меню настроек, без учета веса оружия и силы игрока
						local fatigueCost =  fatigueBow
                        dynamic.fatigue(self).current = math.max(0,dynamic.fatigue(self).current - fatigueCost) -- don't set to below 0
                      end
                    end
                  end
                end
              end
            end
          end
        end
		
        if fatigueZoom > 0 and active then -- if zoomed in then check this junk
          -- drain fatigue on timer
          if dynamic.fatigue(self).current > 0 then -- if not out of fatigue
            hurtZoom = hurtZoom + dt
            if hurtZoom >= hurtWait then -- if enough time has passed
              hurtZoom = 0
			  -- we can assume that you have the correct weapon if the zoom is active
			  --local weaponWeight = Weapon.record(Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight)).weight
              --local fatigueCost =  math.ceil(fatigueZoom*100/(skills.marksman(self).modified+50)) --удалена зависимость расхода стамины от навыка лучника, при натянутом прицеле
			  local fatigueCost = fatigueZoom --упрощенная формула, расход стамины задается только вручную
              dynamic.fatigue(self).current = math.max(0,dynamic.fatigue(self).current - fatigueCost) -- don't set to below 0
            end
          end
        end
      
        local bowCheck = (enabledFirstPerson and camera.getMode() == camera.MODE.FirstPerson) --or  -- or для 3лицо
            --(enabledThirdPerson and camera.getMode() == camera.MODE.ThirdPerson)  --3лицо
        --local isSneak = self.controls.sneak -- 0.49 sneak check
        --if isSneak == nil then
        --  isSneak = input.isActionPressed(input.ACTION.Sneak) -- 0.48 sneak check
        --end
        --if active ~= (bowCheck and isBowPrepared() and isSneak and input.isActionPressed(input.ACTION.Activate)) then -- req sneak and activate
        if active ~= (bowCheck and isBowPrepared() and input.isActionPressed(input.ACTION.Activate)) then -- req activate only
          --if active ~= (bowCheck and isBowPrepared() and isSneak) then -- req sneak
          --if active ~= (bowCheck and isBowPrepared()) then -- original
          active = not active
		  
          --[[if active then  --3лицо ???
            --I.Camera.disableThirdPersonOffsetControl()  --3лицо ???
            --camera.setFocalTransitionSpeed(5.0) --3лицо ???
            -- camera.setFocalPreferredOffset(combatOffset) --3лицо ???
          --else  --3лицо ???
            --I.Camera.enableThirdPersonOffsetControl()  --3лицо ???
          end --]]  --3лицо ???
        end
        if self.controls.use == 0 or not active then
          counter = math.max(counterMin, counter - dt * 2.5)
		  if counter == counterMin then DestroySniperScore() end --удаление снайперского прицела в момент возврата зума в исходный
		  
        else
			local weaponSnip = Actor.equipment(self, Actor.EQUIPMENT_SLOT.CarriedRight) --моё
			if weaponSnip and weaponSnip.recordId:find('rw_sniper') then --моё
		    counter = math.min(counterMax, counter + dt * 2.5)  --исходно 2.5
			renderSniperScore()
			else
			DestroySniperScore()
			counter = counterMin
			end -- моё
        end
        local effect = (math.max(0.1, math.exp(math.min(1, counter)-1)) - 0.1) / 0.9
        --effect = effect*math.min(1.5,(0.5 + skills.marksman(self).modified/100)) --исходная формула с зависимостью зума от навыка лучника, упрощено
        effect = effect*1.5 --упрощенная формула для марксмана 100, коэффициет равен 1,5; х1,5 можно было бы внести на 2 строчки выше, но ладно
		camera.setFieldOfView(camera.getBaseFieldOfView() * (1 - 0.5 * effect))
		
		
        --if camera.getMode() ~= camera.MODE.ThirdPerson then effect = 0 end
          --[[if useAimingOffset ~= (effect > 0.4) and active then  --весь блок для 3го лица???
            useAimingOffset = effect > 0.4
          if useAimingOffset then
            camera.setFocalPreferredOffset(aimingOffset)
          else
            camera.setFocalPreferredOffset(combatOffset)
          end
		  end --]]
      end
    end,

  }
}

