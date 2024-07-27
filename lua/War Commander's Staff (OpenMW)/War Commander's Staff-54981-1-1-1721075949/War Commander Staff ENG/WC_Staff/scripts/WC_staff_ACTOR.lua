--модуль урона актерам, добавляется через глобальный скрипт
--расчет уровна производится в зависимости от наличия огненного щита, сопротивления огню, уязвимости к огню
--поглощение и отражение заклинаний в расчет не принимаются (типа, слишком мощная магия)

local types = require('openmw.types')
local self = require('openmw.self')
local core = require('openmw.core')
local ai = require('openmw.interfaces').AI
local storage = require('openmw.storage')

local doOnce = 0
local AggressivePlayer


return {
    engineHandlers = {
	
	onInit = function(data) AggressivePlayer = data.AggressivePlayer end,	--получения данных об игроке, запустившем огненный шар, для его дальнейшей атаки
	
	onUpdate = function(dt)
			
		if doOnce == 0 then
		local ID = self.recordId --для теста
    
		local Fire_Shield = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FireShield).magnitude
		local Resist_Fire = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.ResistFire).magnitude
		local Weakness_Fire = types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.WeaknessToFire).magnitude
				
		local RW_fire = Fire_Shield + Resist_Fire - Weakness_Fire  -- RW = resist or weakness
		RW_fire = ( 100 - RW_fire) / 100  --пересчет в обратные проценты
		local settings = storage.globalSection('SettingsWCStaff')
		local BaseDamage = settings:get('BaseDamage') --получения базового урона из настроек
		local TestMessage = settings:get('TestMessage')
		local DestructionLVL = types.NPC.stats.skills.destruction(AggressivePlayer).modified  --получение навыка разрушения игрока с учетом одификатора
		--print (string.format('player's DestructionLVL, %s', DestructionLVL))
		DestructionLVL = DestructionLVL / 100
		local damage = BaseDamage * math.max (0, RW_fire)
		local DependDestruction = settings:get('DependDestruction')
		if DependDestruction then damage = damage * DestructionLVL end
		local health = types.Actor.stats.dynamic.health(self)
		health.current = health.current - damage
		if TestMessage then print(string.format('ID Actor %s, fire resistance %s, damage %s', ID, RW_fire, damage)) end  
		--атака на игрока
			if not types.Player.objectIsInstance(self) then --проверка, что актер не является игроком
				if types.Actor.isDead(self) == false then --проверка, что актер немертв
					if not ai.getActiveTarget('Combat') then --проверка, что НПС ни с кем не дерется
					--print (string.format('AggressivePlayer %s', AggressivePlayer)) 
					ai.startPackage({type = 'Combat', target = AggressivePlayer})
					end --конец проверки на драку
				end --конец проверки на жизнь
			end
		doOnce = 1
		--урон нанесен, далее надо открепить скрипт, иначе не будет повторного урона
		core.sendGlobalEvent('RemoveActorScript', {ActorForRemoveScript = self})
		end
	end, --конец onUpdate
	},
	
	eventHandlers = { 
		RemoveActorScript = RemoveActorScript
	}
}