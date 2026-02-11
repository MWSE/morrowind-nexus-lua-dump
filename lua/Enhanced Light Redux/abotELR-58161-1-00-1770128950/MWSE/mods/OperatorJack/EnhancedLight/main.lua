---@diagnostic disable: undefined-field

local modPrefix = 'OperatorJack\\EnhancedLight\\main.lua'

local tes3_effect_light = tes3.effect.light
local magicObjects = {tes3.objectType.spell, tes3.objectType.enchantment, tes3.objectType.alchemy}

local tes3_effect_magelight = tes3.effect.magelight
-- safety to be able to load a save with the effect embedded
if not tes3_effect_magelight then
	tes3_effect_magelight = 344
	tes3.claimSpellEffectId('magelight', tes3_effect_magelight)
end

-- replace the Magelight effect from spells, echantments and potions
-- with the original light effect so they don't crash any more
local function fixMagelight()
	local modifiedOnce = false
	for object in tes3.iterateObjects(magicObjects) do
		local effects = object.effects
		if effects then
			local modified = false
			for i = 1, 8 do
				local effect = effects[i]
				if effect
				and (effect.id == tes3_effect_magelight) then
					effect.id = tes3_effect_light
					modified = true
				end
			end
			if modified then
			---and (not object.sourceMod) then
				object.modified = true
				modifiedOnce = true
				mwse.log([[%s fixMageLight():
"%s" "%s" reverted to use standard tes3.effect.light]],
modPrefix, object.id, object.name)
			end
		end
	end
	return modifiedOnce -- true for debugging messages
end

local cleanedStr = 'has been cleaned from tes3.effect.magelight'

local function savedOnce(e)
	local s = ([[
"%s"
"%s"
%s.
If you are going to use this cleaned save
you should now be able to safely remove
"Enhanced Light.esp" from your loading list
and delete the files in "MWSE\Mods\OperatorJack\EnhancedLight\"
folder (apart main.lua if you want to clean other saves).]]):format(e.filename, e.name, cleanedStr)
	mwse.log('%s: %s', modPrefix, s)
	tes3.messageBox(s)
end

local function save()
	if fixMagelight() then
		event.register('saved', savedOnce, {doOnce = true})
	end
end

local function loaded(e)
	if fixMagelight() then
		if e.newGame then
			local s = ([[New game %s]]):format(cleanedStr)
            mwse.log('%s: %s', modPrefix, s)
            tes3.messageBox(s)
			return
		end
		local s = ([[Loaded game "%s"
%s]]):format(e.filename, cleanedStr)
        mwse.log('%s: %s', modPrefix, s)
        tes3.messageBox(s)
	end
end

local function referenceActivated(e)
	local ref = e.reference
	local mob = ref.mobile
	if not mob then
		return
	end
	local a = mob:getActiveMagicEffects({effect = tes3_effect_magelight})
	if a
	and (#a > 0) then
		-- remove the pesky thing and the spell in case
		local s = [["]] .. ref.id .. [[" cleaned from tes3.effect.magelight]]
		mwse.log(modPrefix .. ': referenceActivated() ' .. s)		
		tes3.removeEffects({reference = ref, effect = tes3_effect_magelight})
		tes3.messageBox(s)
	end
end

event.register('initialized', function ()
	event.register('save', save, {priority = -6666666666})
	event.register('loaded', loaded, {priority = 6666666666})
	event.register('referenceActivated', referenceActivated, {priority = 6666666666})
	collectgarbage()
end, {doOnce = true, priority = -6666666666})

