--[[

https://gitlab.com/ptmikheev/openmw-lua-examples

verify:

Into Crate
- confirm player has some ingreds
- place ring in crate
- confirm player has no ingreds
- confirm crate has all the ingreds

Pick up
- drop on ground
- verify rin is back in inventory

]]

Input = require('openmw.input')
Core = require('openmw.core')
Self = require('openmw.self')
Time = require('openmw_aux.time')
T = require('openmw.types')


Player = require('openmw.self').object
Nearby = require('openmw.nearby')

RingRecordId  = require('scripts.StoreIngredients.fn').Symbol.ring_of_ingredients
Settings      = require('scripts.StoreIngredients.fn').Symbol.Settings
PlayerSection = require('scripts.StoreIngredients.fn').Symbol.PlayerSection
RingSettings = require('openmw.storage').playerSection(PlayerSection.SettingsPageG1)

Ring = {
	currentLocationName = '{none}',
	lastLocationName = '{none}',

	lastLoc = nil,
	currentLoc = nil,

	__tostring = function(self)
		return string.format('{ring cur:%s, last:%s}',
			self.currentLocationName,
			self.lastLocationName)
	end,

	notFound = function(self) return self.currentLoc == nil end,

	resetLocations = function(self)
		self.lastLocationName = '{none}'
		self.currentLocationName = '{none}'
	end,

	isNearby = function(self)
		return self.currentLocationName == '{nearby}' and (
			self.lastLocationName == '{none}' or
			self.lastLocationName == '{nearby}')
	end,

	switchedContainers = function(self)
		return self.lastLocationName ~= '{none}' and
			self.lastLocationName ~= self.currentLocationName
	end,

	bothLocationsNone = function(self)
		return self.lastLocationName == '{none}' and
			self.currentLocationName == '{none}'
	end,

	isInContainer = function(self)
		return self.currentLoc and self.currentLoc.type == T.Container
	end,

	setCurrent = function(self, obj, cname)
		if (obj and obj.id) then self.currentLocationName = obj.id end
		if (obj) then self.currentLoc = obj end
		if (cname) then self.currentLocationName = cname end
	end,

	moveToPlayer = function()
		if Ring.currentLoc and Ring.currentLoc.recordId == RingRecordId then
			Ring.currentLoc:activateBy(Player)
			Ring.lastLocationName = '{none}'
			Ring.currentLocationName = 'player'
		end
	end,

}


I = require('openmw.interfaces')




local sect = require('openmw.storage').playerSection
print('openmw.storacte.playerSection = ', type(sect))

I.Settings.registerPage({
	name = 'StoreIngredientsRing',
	key = PlayerSection.SettingsPage,
	l10n = PlayerSection.L10Ncontext,
	description = 'Move the special ring into a container and ingredients from inventory will follow',
})

I.Settings.registerGroup({
	name = 'Ingredients ring settings',
	key = PlayerSection.SettingsPageG1,
	page = PlayerSection.SettingsPage,
	l10n = PlayerSection.L10Ncontext,
	description = nil,
	permanentStorage = false, -- false means store in save file
	settings = {

		{
			key = Settings.AllwaysPickUp,
			description = 'If the ring is placed somewhere, move it back into the inventory',
			name = 'Always pick up ring',
			renderer = 'checkbox',
			default = true,
		},

		{
			key = Settings.Halt,
			description = 'Stops looking for the ring and moving items',
			name = 'Disable ring',
			renderer = 'checkbox',
			default = false,
		},

		{
			key = Settings.PollInterval,
			description = 'How often to detect the ring and move items (must reload)',
			name = 'Interval (sec 1-600)',
			renderer = 'number',
			default = 1,
			argument = { min = 1, max = 600 },
		},

	},
})



-------------------------

local stopFn
local interval = RingSettings:get(Settings.PollInterval)

local function lookForRing()
	Ring.currentLocationName = "{none}"
	Ring.currentLoc = nil

	--[[
		locate the ring
			look for ring in player
			look for ring in containers
			look for ring among nearby items
	]]
	if Ring:notFound() then
		if T.Actor.inventory(Player):find(RingRecordId) then
			-- print('rings', T.Actor.inventory(Player):find(RingRecordId).count)
			Core.sendGlobalEvent('toxRemove1Ring', {})
			Ring:setCurrent(Player)
		end
	end
	if Ring:notFound() then
		-- print('find 2 ')
		for _, e in pairs(Nearby.containers) do
			if T.Container.inventory(e):find(RingRecordId) then
				-- print('find 2 container=', e.recordId)
				Ring:setCurrent(e)
				-- print('find 2 isInCont. ', tostring(Ring:isInContainer()))
				break
			end
		end
	end
	if Ring:notFound() then
		-- print('find 3 ')
		for _, e in pairs(Nearby.items) do
			if e.recordId == RingRecordId then
				Ring:setCurrent(e, '{nearby}')
				-- print('find 3 ring = ', Ring:__tostring())
				-- print('find 3 ring.near?', tostring(Ring:isNearby()))
				break
			end
		end
	end

	-- don't do anything else if it's in the same position as before
	if Ring:bothLocationsNone() then
		return
	end

	-- print('Found somewhere....')

	-- pick up ring if it is laying around nearby
	if Ring:isNearby() and RingSettings:get(Settings.AllwaysPickUp) then
		-- print('NEARBY')
		Ring:moveToPlayer()
	end


	if Ring:switchedContainers() then
		if Ring:isInContainer() then
			Core.sendGlobalEvent(
				'toxStoreIngredients',
				{
					container = Ring.currentLoc,
					actor = Player,
					toPlayer = false
				})
		else
			-- print('not in container ???')
		end
	end

	if Ring.currentLocationName ~= "{none}" then
		Ring.lastLocationName = Ring.currentLocationName
		Ring.lastLoc = Ring.currentLoc
	end

	if RingSettings:get(Settings.Halt) then
		if type(stopFn) == 'function' then stopFn() end
	end
end

local async = require('openmw.async')
RingSettings:subscribe(async:callback(function(section, key)
	if key then
		print('Value is changed:', key, '=', RingSettings:get(key))
	else
		print('All values are changed')
	end

	if key == Settings.Halt then
		Core.sendGlobalEvent('toxStoreIngredientsHalt', {
			isHalted = RingSettings:get(Settings.Halt) })
	end

	if interval ~= RingSettings:get(Settings.PollInterval) then
		if not RingSettings:get(Settings.Halt) then
			if type(stopFn) == 'function' then stopFn() end
			stopFn = Time.runRepeatedly(lookForRing, Time.second * RingSettings:get(Settings.PollInterval))
			print('restarted with interval', tostring(RingSettings:get(Settings.PollInterval)))
		end
	end


end))


stopFn = Time.runRepeatedly(lookForRing, Time.second * RingSettings:get(Settings.PollInterval))


return {
	engineHandlers = {
		onLoad = function(savedData, initData)
			Ring:resetLocations()


			print('STATE')
			print('halt     ', RingSettings:get(Settings.Halt))
			print('interval ', RingSettings:get(Settings.PollInterval))
			print('pick up  ', RingSettings:get(Settings.AllwaysPickUp))
			print('STATE')
		end
	},
}
