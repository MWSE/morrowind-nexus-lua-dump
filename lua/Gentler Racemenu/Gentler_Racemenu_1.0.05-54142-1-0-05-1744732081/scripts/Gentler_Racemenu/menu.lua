local menu = require('openmw.menu')

return{
	eventHandlers = {
    grm_saveAndQuit = function(data)
			menu.saveGame(data.description, data.slotname)
			menu.quit()
		end,
	}
}
