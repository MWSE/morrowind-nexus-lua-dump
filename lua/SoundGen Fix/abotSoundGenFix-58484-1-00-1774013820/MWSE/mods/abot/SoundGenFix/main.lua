local author = 'abot'
local modName = 'SoundGenFix'
local modPrefix = author..'/'.. modName

event.register('initialized', function ()

local unassignedBethSoundGenDict = {}
for i, v in ipairs({
'bm frost boar0007',
'bm frost giant0007',
'bm rieklings0007',
'bm_werewolf_skaal0004',
'bm_werewolf_skaal0005',
'bm_werewolf_skaal0006',
'default0000',
'default0001',
'default0002',
'default0003',
'default0004',
'default0005',
'default0006',
'default0007',
}) do
	unassignedBethSoundGenDict[v] = i
end

local soundGenTypeDict = table.invert(tes3.soundGenType)
local soundGenerators = tes3.dataHandler.nonDynamicData.soundGenerators
local deadPersistentCreatures = {}
local c = 0
for obj in tes3.iterateObjects(tes3.objectType.creature) do
	---@cast obj tes3creature|tes3creatureInstance
	if obj.persistent
	and obj.health
	and (obj.health <= 0.0001) then
		c = c + 1
		deadPersistentCreatures[c] = obj
	end
end
for _, sndg in ipairs(soundGenerators) do
	---mwse.log('k = %s, sndg = %s, sndg.creature = %s', _, sndg, sndg.creature)
	if (not sndg.creature)
	and (
		(not sndg.id)
		or (not unassignedBethSoundGenDict[sndg.id:lower()])
	) then
		mwse.log([[

>>> %s: WARNING: mod "%s" "%s" soundGen %s"%s" "%s"
has no assigned creature and could trigger its sound semi-randomly!]],
			modPrefix, sndg.sourceMod, soundGenTypeDict[sndg.type],
			sndg.id and sndg.id or '', sndg.sound.id, sndg.sound.filename)
		if c > 0 then
			local cre = deadPersistentCreatures[c]
			mwse.log('try and fix: assigning soundGen to "%s" "%s" persistent dead creature',
				cre.sourceMod, cre.id)
			sndg.creature = cre
			c = c - 1
		end
	end
end
end, {doOnce = true})

