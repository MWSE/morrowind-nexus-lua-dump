local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local core = require('openmw.core')
local util = require('openmw.util')

    local player = self
    local playerlocation={}
    local playercell={}


--mwscript adds custom spell on sleep if certain journal stages met
--lua grabs current location upon sleep and stores, teleports PC to intended destination and removes temp spell
local function onFrame()
  if types.Actor.activeSpells(player):isSpellActive('detd_PCsleeps_dream1a') == true and playercell[1]==nil then
    playerlocation[1] = player.position
    playercell[1] = player.cell.name
    types.Actor.spells(self):remove('detd_PCsleeps_dream1a')
    core.sendGlobalEvent('KD_Teleport', { target = self.object, position = util.vector3( 3416.178, 2361.969, 15194.559), cell = "A Disturbing Dream" })

  end

  if types.Actor.activeSpells(player):isSpellActive('detd_PCsleeps_dream2') == true and playercell[2]==nil then
    playerlocation[2] = player.position
    playercell[2] = player.cell.name
    types.Actor.spells(self):remove('detd_PCsleeps_dream2')
    core.sendGlobalEvent('KD_Teleport', { target = self.object, position = util.vector3( 4150.526, 5595.308, 14816.161), cell = "A Second Disturbing Dream" })

  end

  if types.Actor.activeSpells(player):isSpellActive('detd_PCsleeps_dream3') == true and playercell[3]==nil then
    playerlocation[3] = player.position
    playercell[3] = player.cell.name
    types.Actor.spells(self):remove('detd_PCsleeps_dream3')
    core.sendGlobalEvent('KD_Teleport', { target = self.object, position = util.vector3( 3918.398, 3760.345, 14329.185), cell = "A Third Disturbing Dream" })

  end

  if types.Actor.activeSpells(player):isSpellActive('detd_PCsleeps_dream4') == true and playercell[4]==nil then
    playerlocation[4] = player.position
    playercell[4] = player.cell.name
    types.Actor.spells(self):remove('detd_PCsleeps_dream4')
    core.sendGlobalEvent('KD_Teleport', { target = self.object, position = util.vector3( 3859.445, 4097.344, 12117.257), cell = "A Fourth Disturbing Dream" })

  end
end



local function onSave()
	return{playerlocationSaved=playerlocation, playercellSaved=playercell}
end

local function onLoad(data)
	if data.playerlocationSaved then
		playerlocation=data.playerlocationSaved
	end
	if data.playercellSaved then
		playercell=data.playercellSaved
	end
end



return {
  engineHandlers = {
    onQuestUpdate = function(questId, stage)
      print(questId, stage)
        if questId == 'a1_dreams' and stage == 1 then
            core.sendGlobalEvent('KD_Teleport', { target = self.object, position = playerlocation[1], cell = playercell[1] })
        end

        if questId == 'a1_dreams' and stage == 5 then
          core.sendGlobalEvent('KD_Teleport', { target = self.object, position = playerlocation[2], cell = playercell[2] })
        end

        if questId == 'a1_dreams' and stage == 10 then
          core.sendGlobalEvent('KD_Teleport', { target = self.object, position = playerlocation[3], cell = playercell[3] })
        end

        if questId == 'a1_dreams' and stage == 15 then
          core.sendGlobalEvent('KD_Teleport', { target = self.object, position = playerlocation[4], cell = playercell[4] })
        end
      end
  ,
  onFrame=onFrame,
	onSave=onSave,
	onLoad=onLoad,
  }
}