local self    = require('openmw.self')
local async   = require('openmw.async')
local nearby  = require('openmw.nearby')
local ai      = require("openmw.interfaces").AI
local types   = require('openmw.types')
local core    = require('openmw.core')
local storage = require('openmw.storage')

local settings = require('scripts.FatigueOutOfCombat.settings')
local settings_section = settings.globalSettings
local function getDistanceSetting()
    return settings_section:get('disatance') or 8000
end

local player = nearby.players[1]
local TEN_MINS = 600
local last_time_combat_w_player = 0

local function isAlly(target_obj)
  local set = storage.globalSection('FatigueOutOfCombat_Allies'):get('set') or {}
  return target_obj and set[target_obj.id] and set[target_obj.id][1] == true
end

local function check()
    local activeTarget_Combat = ai.getActiveTarget("Combat")
    local activeTarget_Pursue = ai.getActiveTarget("Pursue")
    local package = ai.getActivePackage()

    --print("name= ", self.recordId, "target= ", activeTarget_Combat , activeTarget_Pursue, activeTarget_Follow)

    local set_max_stamina
    local now_time = core.getSimulationTime()

    if types.Actor.isDead(self) == false
    and (
        (activeTarget_Combat and (types.Player.objectIsInstance(activeTarget_Combat) or isAlly(activeTarget_Combat)))
        or
        (activeTarget_Pursue and (types.Player.objectIsInstance(activeTarget_Pursue) or isAlly(activeTarget_Pursue)))
    ) then
        local enemy_position = self.position
        local player_position = player.position
        local distance = (enemy_position - player_position):length()

        if distance < getDistanceSetting() then
            set_max_stamina = false
            last_time_combat_w_player = core.getSimulationTime()
            --print("нпс дерется, икрок таргет. дистанция= ", distance)
            --print("package.type= ", package.type)
            player:sendEvent('eventFatigueKeepMaximum', {id=self.id, set_max_stamina=set_max_stamina})
        end
    elseif types.Actor.isDead(self) == false
    and last_time_combat_w_player > 0 and ((now_time - last_time_combat_w_player) < TEN_MINS )
    and (package.type == "Combat" or package.type == "Pursue" or ai.isFleeing()) then
        --print("нпс дерется/убегает, игрок не таргет, но был в последнии 10 минут ")
        --print("package.type= ", package.type)
        local enemy_position = self.position
        local player_position = player.position
        local distance = (enemy_position - player_position):length()
        if distance < getDistanceSetting() then
            set_max_stamina = false
            player:sendEvent('eventFatigueKeepMaximum', {id=self.id, set_max_stamina=set_max_stamina})
        end
    end

    async:newUnsavableSimulationTimer(0.2, check)
end

async:newUnsavableSimulationTimer(0.2, check)