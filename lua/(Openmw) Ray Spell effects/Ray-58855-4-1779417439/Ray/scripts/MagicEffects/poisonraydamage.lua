local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')



--=============================================================================================================================================
-- Variables
--=============================================================================================================================================

--Data holder
local EffectDataTable ={}

--Logic variables
local TotalTimer = 0
local IncrementalTimer = 0
local FirstSwitch = 0
local SpellAbsorbCheck = 0
local SpellAbsorbCheck2 = 0
local SpellReflectCheck = 0
local SpellReflectCheck2 = 0
local SecondReflect = 0

--This is the scale factor used to reduce the damage for balance, 0.3 is default and is just here for saftey incase the global function
--doesn't send a scale factor in the sent data
local SCALE_FACTOR = 0.3







--=============================================================================================================================================
-- Hit Target Logic
--=============================================================================================================================================
local function HitTargetWithSpellLocal(PassedData)
	

	
	-- Determine the base damage
	local DamageLocal = math.random(EffectDataTable.MinDamage, EffectDataTable.MaxDamage)
	DamageLocal = DamageLocal*SCALE_FACTOR
	
	local HolderOfReflect = {}
	
	if SpellAbsorbCheck2 == 0 then
		local SpellsOnTarget = types.Actor.activeSpells(EffectDataTable.Target)
		local HolderOfabsorbtion = {}
		for i,k in pairs(SpellsOnTarget) do
			
			for _, effect in pairs(k.effects) do
				if effect.id == 'spellabsorption' then
					table.insert(HolderOfabsorbtion,effect.magnitudeThisFrame)
				end
				if effect.id == 'reflect' then
					table.insert(HolderOfReflect,effect.magnitudeThisFrame)
				end
			end
		end
		
		
		for i,k in pairs(HolderOfabsorbtion)do
			local SpellAbsorbRoll = math.random(0, 100)

			if SpellAbsorbRoll < k and SpellAbsorbCheck == 0 then
				SpellAbsorbCheck = 1
				EffectDataTable.Target:sendEvent('ApplySpellAbsorbtionToTargetActor', EffectDataTable)
			end

		end
	end
	
	SpellAbsorbCheck2 = 1



	if SpellReflectCheck2 == 0 and SecondReflect ~= 1 then
		for i,k in pairs(HolderOfReflect)do
			local SpellReflectRoll = math.random(0, 100)

			if SpellReflectRoll < k and SpellReflectCheck == 0 then
				SpellReflectCheck = 1
				EffectDataTable["SecondReflect"] = 1
				EffectDataTable["Target"] = EffectDataTable.CasterObject
				core.sendGlobalEvent('HitTargetWithSpell', EffectDataTable)

			end

		end
	end

	SpellReflectCheck2 = 1





	
	 
	if SpellReflectCheck == 0 and SpellAbsorbCheck == 0 then
		-- Handle the resistances and weaknesses
		local PoisonResistOnTarget = types.Actor.activeEffects(EffectDataTable.Target):getEffect('resistpoison').magnitude
		local PoisonWeakOnTarget = types.Actor.activeEffects(EffectDataTable.Target):getEffect('weaknesstopoison').magnitude
		local PoisonMultiplier = (PoisonResistOnTarget-PoisonWeakOnTarget)/100
		local DamageAdjusted = math.max(0 , DamageLocal-(DamageLocal*PoisonMultiplier))



		--apply the damage
		EffectDataTable.Target:sendEvent('ApplyDamageToTargetActor', {Damage = DamageAdjusted})

		
		--play the VFX on the actor
		local mgef = core.magic.effects.records[EffectDataTable.EffectIDPassed]
		EffectDataTable.Target:sendEvent('AddVfx', {
		  model = types.Static.record(mgef.hitStatic).model,
		  options = {
			particleTextureOverride = mgef.particle,
			loop = false
		  }
		})
	end
end







--=============================================================================================================================================
-- Engine Handlers
--=============================================================================================================================================


return{
	

    engineHandlers = {
		
		--====================================
		-- Initial Data passed to the script on attachment to the projectile
		--====================================

		onInit = function(data)
			EffectDataTable = data
			EffectDataTable["DamageObject"] = self

			
			if EffectDataTable.ModSettings.SCALE_FACTOR ~= nil then
				SCALE_FACTOR = EffectDataTable.ModSettings.SCALE_FACTOR
			end
			
			if EffectDataTable.SecondReflect ~= nil then
				SecondReflect = EffectDataTable.SecondReflect
			end
			
			--runs the effect the first time
			HitTargetWithSpellLocal()
		end,
		
		
	
		--====================================
		-- Handles the actual running of the effect
		--====================================
		
		onUpdate = function(dt)
			--timers for logic
			TotalTimer = TotalTimer + dt
			IncrementalTimer = IncrementalTimer + dt
			
			-- when duration runs out, remove the script
			if EffectDataTable.Duration == nil then
				core.sendGlobalEvent('HitTargetremoveScript', EffectDataTable)
				return
			end
		
			
			-- when duration runs out, remove the script
			if TotalTimer >= EffectDataTable.Duration then
				core.sendGlobalEvent('HitTargetremoveScript', EffectDataTable)
				return
			end
		

			
			-- run additional spell effects if the duration is more than one
			if IncrementalTimer >= 1 then
				HitTargetWithSpellLocal()
				IncrementalTimer=0
			end
		end
	}
	
	
}
