local ui = require('openmw.ui')
local util = require('openmw.util')
local self = require("openmw.self")
local core = require('openmw.core')
local settingsBase = require('scripts.xaade.autosave.settingsBase')

local scriptVersion = 2
local lastCellName = 'lastCellName'
local countChanges = 0
local lastCellExterior = false
local lastSaveSlot = 0
local validCell = false


local function isSneaking()

	return self.controls.sneak
end

local function updateLastValues(newCellName, newCellExterior)
	lastCellName = newCellName
	lastCellExterior = newCellExterior
	validCell = true
end

local function requestSave()
	print('sending event')
	lastSaveSlot = lastSaveSlot + 1
	if lastSaveSlot > settingsBase.getNavigationAutosaveSetting('numberOfSaves') then
		lastSaveSlot = 1
	end
	self.type.sendMenuEvent(self, 'omw_cflare_autosave_save', { saveSlot = lastSaveSlot })
end

local function onUpdate(dt)
	
    local c = self.cell
	local newCellName = c.name
	local newCellExterior = c.isExterior
	local cellExteriorInteriorMovement = newCellExterior ~= lastCellExterior or (newCellExterior == false and settingsBase.getNavigationAutosaveSetting('interiorSave') == true)
	
	
	if isSneaking() == true then
		print('is sneaking')
	end
	if validCell and newCellName ~= lastCellName and cellExteriorInteriorMovement then
		requestSave()
	end
	updateLastValues(newCellName, newCellExterior)
end

local function onSave()
    return {
		version = scriptVersion,
		currentCellName = lastCellName,
		currentCellExterior = lastCellExterior,
		lastSaveSlot = lastSaveSlot,
	}
end

local function onLoad(data)
    if not data or not data.version or data.version < 1 then
        print('Was saved with an old version of the script, initializing to default')
        lastCellName = ''
		lastCellExterior = false
		validCell = false
        return
    end
	if data.version > scriptVersion then
        error('Required update to a new version of the script')
	end
	if data.version == 1 then
        print(string.format('Updating from version %d to %d', 1, scriptVersion))
		lastCellName = data.currentCellName
		lastCellExterior = data.currentCellExterior
		lastSaveSlot = 0
		validCell = true
		print(string.format('Loaded with last cell name %s and exterior is %s', lastCellName, lastCellExterior))
	elseif data.version == scriptVersion then
		lastCellName = data.currentCellName
		lastCellExterior = data.currentCellExterior
		lastSaveSlot = data.lastSaveSlot
		validCell = true
		print(string.format('Loaded with last cell name %s and exterior is %s', lastCellName, lastCellExterior))
	else 
        print(string.format('Updating from version %d to %d', data.version, scriptVersion))
        lastCellName = ''
		lastCellExterior = false
		validCell = false
	end
end

return {
    engineHandlers = {
		onUpdate = onUpdate,
		onSave = onSave,
		onLoad = onLoad,
    },
}