
--====================================================================================================================================================================================================
--  This Detects when the player changes spells and sends a global event to the global script with the appropriate info about the current spell
--====================================================================================================================================================================================================



--====================================================================================================
--libaries imported
--====================================================================================================
local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')



--====================================================================================================
--varibles 
--====================================================================================================
local CurrentSpellSelected = {id = 'NothingSelectedYet'}
local SpellChangeCheck = nil





--====================================================================================================
--engine handlers
--====================================================================================================
return {
    engineHandlers = {


		--====================================================================================================
		--Frame by frame logic 
		--====================================================================================================
		onUpdate = function (dt2)

			---------------------------------------
			--these two if statements activate whenever the player changes spells. When the player changes spells, it fires a global
			--event to add all of the spells data to the global script. A nice way of sending all of that info and parsing it without
			--having to send it back and forth between the global and hitdetection scripts. also, it means it only has to be sent once, at a pretty low resource
			--intensive moment in time.
			if CurrentSpellSelected.id ~= types.Actor.getSelectedSpell(self).id then
				
				CurrentSpellSelected = types.Actor.getSelectedSpell(self)
				SpellChangeCheck = 1
			end
			
			if SpellChangeCheck == 1 then
				SpellChangeCheck = 0
				core.sendGlobalEvent('ParseCurrentSelectedSpell',{SpellID = CurrentSpellSelected.id})
			end

		end,

		onInit = function()
			print('Spell Update onInit=====================================================================================================================================')
			CurrentSpellSelected = types.Actor.getSelectedSpell(self)
			core.sendGlobalEvent('ParseCurrentSelectedSpell',{SpellID = CurrentSpellSelected.id})
		end,
			
		onLoad = function()
			print('Spell Update Onload==============================================================================================================================')
			CurrentSpellSelected = types.Actor.getSelectedSpell(self)
			core.sendGlobalEvent('ParseCurrentSelectedSpell',{SpellID = CurrentSpellSelected.id})
		end
    }
}








