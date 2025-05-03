local this = {}

-- Imports
local common = require("Character Sound Overhaul.main")
local soundData = require("Character Sound Overhaul.soundData")

-- Load or create soundstate
local manifest
local fileAddedToManifest, fileRemovedFromManifest = false, false

--Paths
local manifestPath = "mods\\Character Sound Overhaul\\manifest"
local CSOdir = "Data Files\\Sound\\CSO"
local soundDir = "CSO"
local itemsDir = "\\items\\"
local moveDir = "\\movement\\"
local weaponDir = "\\weapons\\"
local miscDir = "\\misc\\"
local magicDir = "\\magic\\"
local magicEffectDir = "\\effects\\"

-- Create sound objects against manifest file
local function createSound(objectId, filename, soundTable, i)
	local timestamp = lfs.attributes("Data Files\\Sound\\" .. filename, "modification")
	local fileunmodified = (manifest[objectId] == timestamp)
	
	local sound = tes3.createObject {
		id = objectId,
		objectType = tes3.objectType.sound,
		filename = filename,
		getIfExists = fileUnmodified
	}
	
	if soundTable then
		table.insert(soundTable, i or #soundTable + 1, sound)
	end
	
	manifest[objectId] = timestamp
	
	if (not fileUnmodified) then
		if (not fileAddedToManifest) then 
			fileAddedToManifest = true
		end
	end
	
    return sound
end

----- Building tables -----

-- Items
local function buildItemSounds()
	for itemType in lfs.dir(CSOdir .. itemsDir) do
		if itemType ~= ".." and itemType ~= "." then
			soundData.items[itemType] = {}
			for action in lfs.dir(CSOdir .. itemsDir .. itemType) do
				if action ~= ".." and action ~= "." then
					soundData.items[itemType][action] = {}
					for soundfile in lfs.dir(CSOdir .. itemsDir .. itemType .. "\\" .. action) do
						if string.endswith(soundfile, ".wav") then
							local objectId = string.sub(itemType .. "_" .. action .. "_" .. soundfile, 1, -5)
							local filename = soundDir .. itemsDir .. itemType .. "\\" .. action .. "\\" .. soundfile
							createSound (objectId, filename, soundData.items[itemType][action])
						end
					end
				end
			end
		end
	end
end

-- Movement
local function buildMoveSounds()
	for moveType in lfs.dir(CSOdir .. moveDir) do
		if moveType ~= ".." and moveType ~= "." then
			soundData.movement[moveType] = {}
			for action in lfs.dir(CSOdir .. moveDir .. moveType) do
				if action ~= ".." and action ~= "." then
					soundData.movement[moveType][action] = {}
					for soundfile in lfs.dir(CSOdir .. moveDir .. moveType .. "\\" .. action) do
						if string.endswith(soundfile, ".wav") then
							local objectId = string.sub(moveType .. "_" .. action .. "_" .. soundfile, 1, -5)
							local filename = soundDir .. moveDir .. moveType .. "\\" .. action .. "\\" .. soundfile
							createSound (objectId, filename, soundData.movement[moveType][action])
						end
					end
				end
			end
		end
	end
end


-- Weapons
local function buildWeaponSounds()
	for weaponType in lfs.dir(CSOdir .. weaponDir) do
		if weaponType ~= ".." and weaponType ~= "." then
			soundData.weapons[weaponType] = {}
			for action in lfs.dir(CSOdir .. weaponDir .. weaponType) do
				if action ~= ".." and action ~= "." then
					soundData.weapons[weaponType][action] = {}
					for soundfile in lfs.dir(CSOdir .. weaponDir .. weaponType .. "\\" .. action) do
						if string.endswith(soundfile, ".wav") then
							local objectId = string.sub(weaponType .. "_" .. action .. "_" .. soundfile, 1, -5)
							local filename = soundDir .. weaponDir .. weaponType .. "\\" .. action .. "\\" .. soundfile
							createSound (objectId, filename, soundData.weapons[weaponType][action])
						end
					end
				end
			end
		end
	end
end


-- Misc
local function buildMiscSounds()
	for miscType in lfs.dir(CSOdir .. miscDir) do
		if miscType ~= ".." and miscType ~= "." then
			soundData.misc[miscType] = {}
			for action in lfs.dir(CSOdir .. miscDir .. miscType) do
				if action ~= ".." and action ~= "." then
					soundData.misc[miscType][action] = {}
					for soundfile in lfs.dir(CSOdir .. miscDir .. miscType .. "\\" .. action) do
						if string.endswith(soundfile, ".wav") then
							local objectId = string.sub(miscType .. "_" .. action .. "_" .. soundfile, 1, -5)
							local filename = soundDir .. miscDir .. miscType .. "\\" .. action .. "\\" .. soundfile
							createSound (objectId, filename, soundData.misc[miscType][action])
						end
					end
				end
			end
		end
	end
end

-- Magic
local function buildMagicSounds()
	for magicType in lfs.dir(CSOdir .. magicDir) do
		if magicType ~= ".." and magicType ~= "." then
			soundData.magic[magicType] = {}
			for action in lfs.dir(CSOdir .. magicDir .. magicType) do
				if action ~= ".." and action ~= "." then
					soundData.magic[magicType][action] = {}
					for soundfile in lfs.dir(CSOdir .. magicDir .. magicType .. "\\" .. action) do
						if string.endswith(soundfile, ".wav") then
							local objectId = string.sub(magicType .. "_" .. action .. "_" .. soundfile, 1, -5)
							local filename = soundDir .. magicDir .. magicType .. "\\" .. action .. "\\" .. soundfile
							createSound (objectId, filename, soundData.magic[magicType][action])
						end
					end
				end
			end
		end
	end
end

--MagicEffects
local function buildMagicEffectSounds()
	for magicEffect in lfs.dir(CSOdir .. magicEffectDir) do
		if magicEffect ~= ".." and magicEffect ~= "." then
			soundData.magicEffects[magicEffect] = {}
			for action in lfs.dir(CSOdir .. magicEffectDir .. magicEffect) do
				if action ~= ".." and action ~= "." then
					soundData.magicEffects[magicEffect][action] = {}
					for soundfile in lfs.dir(CSOdir .. magicEffectDir .. magicEffect .. "\\" .. action) do
						if string.endswith(soundfile, ".wav") then
							local objectId = string.sub(magicEffect .. "_" .. action .. "_" .. soundfile, 1, -5)
							local filename = soundDir .. magicEffectDir .. magicEffect .. "\\" .. action .. "\\" .. soundfile
							createSound (objectId, filename, soundData.magicEffects[magicEffect][action])
						end
					end
				end
			end
		end
	end
end

local function checkForRemovedFiles()
	local removedSounds = {}
	for k, _ in pairs(manifest) do
		if not tes3.getSound(k) then
			table.insert(removedSounds, k)
		end
	end

	if #removedSounds > 0 then
		fileRemovedFromManifest = true
		for _, v in ipairs(removedSounds) do
			manifest[v] = nil
		end
	end
end

function this.build()

	manifest = json.loadfile(manifestPath) or {}

	buildItemSounds()
	buildMoveSounds()
	buildWeaponSounds()
	buildMiscSounds()
	buildMagicSounds()
	buildMagicEffectSounds()
	
	checkForRemovedFiles()
	-- Write manifest file if it was modified
	if fileRemovedFromManifest or fileAddedToManifest then
		json.savefile(manifestPath, manifest)
	end
	manifest = nil
end

return this