local defaultConfig = {
modEnabled = true, -- add a journal note when player stolen good are confiscated
findEvidenceCell = true, -- if enabled, will find evidence chest cell, else the exterior cell nearby
journalNotify = true,
logLevel = 0
}

local author = 'abot'
local modName = 'Stolen Goods'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local modEnabled, findEvidenceCell, journalNotify
local logLevel, logLevel1, logLevel2, logLevel3

local function round(x)
	return math.floor(x + 0.5)
end

-- set in initialized
local prisonMarker, sJournalEntry

local tes3_objectType_container = tes3.objectType.container

local function getStolenGoods()
	local pcCell = tes3.player.cell
	if logLevel3 then
		mwse.log('%s: getStolenGoods() "%s"',
			modPrefix, pcCell.displayName)
	end
	local prisonMarkerRef = tes3.findClosestExteriorReferenceOfObject({object = prisonMarker})
	if not prisonMarkerRef then
		if logLevel1 then
			mwse.log('%s: getStolenGoods() prisonMarkerRef not found from "%s"',
				modPrefix, pcCell.displayName)
		end
		return
	end
	local prisonMarkerCell = prisonMarkerRef.cell
	local dest = prisonMarkerRef.destination
	if not dest then
		if logLevel1 then
			mwse.log('%s: getStolenGoods() prisonMarkerRef.destination = %s',
				modPrefix, dest)
		end
		return
	end
	local evidenceCell = dest.cell
	if not evidenceCell then
		if logLevel1 then
			mwse.log('%s: getStolenGoods() prisonMarkerRef.destination.cell = %s',
				modPrefix, evidenceCell)
		end
		return
	end
	for ref in evidenceCell:iterateReferences(tes3_objectType_container) do
		if ref.id:startswith('stolen_goods') then
			local obj = ref.object
			local inventory = obj.inventory
			if inventory then
				---mwse.log('>>> %s: "%s" "%s" at "%s" "%s"',
					---modPrefix, obj.id, obj.name, ref.cell.displayName, ref.sourceMod)
				local items = inventory.items
				if items
				and (#items > 0) then
					if logLevel1 then
						mwse.log('%s: "%s" "%s" at "%s" "%s"',
							modPrefix, obj.id, obj.name, ref.cell.displayName, ref.sourceMod)
					end
					local destCell, cellName
					if findEvidenceCell then
						destCell = evidenceCell
					else
						destCell = prisonMarkerCell
					end
					if pcCell == destCell then
						cellName = 'the same place'
					else
						cellName = destCell.displayName .. ', the nearest guarded place'
					end
					local s = string.format([[While in %s, the stolen goods in my possession have been confiscated.
Judging by the location, it is most likely my stolen goods could be brought somewhere in %s.
I'd better remember this if I want to get my stuff back.]],
						pcCell.displayName, cellName)
					local s2 = '\n' .. s .. '\n'

					tes3.addJournalEntry({text = s})
					-- addJournalEntry showMessage parameter does not seem to work

					if journalNotify then
						local s3 = 'Your journal has been updated.'
						if sJournalEntry then
							s3 = sJournalEntry.value
						end
						tes3.messageBox(s3)
					end

					if logLevel2 then
						local pos
						if findEvidenceCell then
							pos = ref.position:copy()
							local height = 50
							local bb = ref.baseObject.boundingBox
							if bb then
								height = bb.max.z - bb.min.z + 5
							end
							pos.z = pos.z + height
						else
							pos = prisonMarkerRef.position
						end
						s2 = s2 .. string.format('\nConsole teleportation command:\nplayer->PositionCell %d %s %d 0 "%s"\n',
							round(pos.x), round(pos.y), round(pos.z), destCell.displayName)
					end
					if logLevel3 then
						s2 = s2 .. '\nEvidence Chest content:\n'
						for _, itemStack in ipairs(items) do
							s2 = s2 .. string.format('%5d "%s" "%s"\n',
								itemStack.count, itemStack.object.id, itemStack.object.name)
						end
					end
					if logLevel1 then
						mwse.log(s2)
					end
					os.setClipboardText(s2)
					return
				end -- if items
			end -- if inventory
		end -- if ref.id:startswith
	end -- for ref
	if logLevel1 then
		mwse.log('%s: getStolenGoods() non-empty evidence chest not found', modPrefix)
	end
end

local function ab01stlngdsPT1()
	getStolenGoods()
end

--- @param e postInfoResponseEventData
local function postInfoResponse(e)
	local command = e.command
	if not command then
		return
	end
	local s = string.lower(command)
	if not string.find(s, 'payfine', 1,true) then
		return
	end
	if string.find(s, 'payfinethief', 1, true) then
		return
	end
	if logLevel1 then
		mwse.log('%s: infoResponse("%s") PayFine command detected:\n%s', modPrefix, e.reference, command)
	end
	-- when out of menu get stolen info
	timer.start({duration = 0.5, callback = 'ab01stlngdsPT1'})
end

local function checkRegister()
	if not prisonMarker then
		return
	end
	if event.isRegistered('postInfoResponse', postInfoResponse) then
		if not modEnabled then
			event.unregister('postInfoResponse', postInfoResponse)
		end
	elseif modEnabled then
		event.register('postInfoResponse', postInfoResponse)
	end
end

local function updateFromConfig()
	modEnabled = config.modEnabled
	findEvidenceCell = config.findEvidenceCell
	journalNotify = config.journalNotify
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
end

local function onClose()
	updateFromConfig()
	checkRegister()
	mwse.saveConfig(configName, config, {indent = false})
end

local function modConfigReady()
	updateFromConfig()

	local optionList = {
'Off',
'Low (note)',
'Medium (note + teleport command)',
'High (note + teleport + evidence chest items)'
}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = string.format("%s. %s",
				i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		description = [[Keep journal notes of locations where your stolen goods are confiscated and possibly stored.

The information will also be copied to the Windows clipboard.]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.2
			self.elements.sideToSideBlock.children[2].widthProportional = 0.8
		end
	})

	sideBarPage:createYesNoButton({
		label = 'Mod enabled',
		description = [[You will take some informative journal notes when your stolen goods are confiscated.]],
		configKey = 'modEnabled'
	})

	sideBarPage:createYesNoButton({
		label = 'Find Evidence cell',
		description = [[If enabled, it will find the evidence chest cell, else the more generic cell nearby where the prison marker is.]],
		configKey = 'findEvidenceCell'
	})

	sideBarPage:createYesNoButton({
		label = 'Journal note notify message',
		description = [[If enabled, a notify message will be displayed when the note is added to the Journal.]],
		configKey = 'journalNotify'
	})

	sideBarPage:createDropdown({
		label = 'Log level:',
		options = getOptions(),
		configKey = 'logLevel'
	})

	mwse.mcm.register(template)

end
event.register('modConfigReady', modConfigReady)


event.register('initialized', function ()
	prisonMarker = tes3.getObject('PrisonMarker')
	if not prisonMarker then
		assert(prisonMarker)
		return
	end
	sJournalEntry = tes3.findGMST('sJournalEntry')
	timer.register('ab01stlngdsPT1', ab01stlngdsPT1)
	---updateFromConfig()
	checkRegister()
end, {doOnce = true})