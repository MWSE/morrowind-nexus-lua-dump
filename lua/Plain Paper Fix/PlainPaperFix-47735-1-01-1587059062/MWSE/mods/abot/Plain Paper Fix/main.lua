--[[
Allow to pick up a blank sheet of paper without having to read it in Scroll context and
then click on "TAKE" from the Scroll Interface before getting it.
Differently from standard scripting available mods it does it without having to attach
a local script to the sheet of paper, so you can keep stacking them in the inventory.
Works also for Tamriel Rebuilt Blank Scroll.
You can tweak paper value, weight, enchantCapacity in the loaded() function code.
--]]

local author = 'abot'
local modName = 'Plain Paper Fix'
local modPrefix = author .. '/' .. modName

local sc_paper_plain_id = 'sc_paper plain'
local t_sc_blank_id = 't_sc_blank' -- TR blank scroll

local blanks = {}
blanks[sc_paper_plain_id] = 100 -- store enchant change if > 0
blanks[t_sc_blank_id] = -1 -- do not change enchant value

local function activate(e)
	local player = tes3.player
	if not (e.activator == player) then
		return
	end
	local ref = e.target
	if not ref then
		assert(ref)
		return
	end
	local obj = ref.object
	---assert(obj)
	local id = string.lower(obj.id)
	---assert(id)
	if not blanks[id] then
		return
	end

	local num = ref.stackSize
	if not num then
		num = 1
	end
	if not tes3.hasOwnershipAccess({ target = ref }) then -- crime handling
		local owner = tes3.getOwner(ref)
		local v = obj.value
		if not v then
			v = 1
		end
		local totalValue = v * num
		timer.delayOneFrame(
			function()
				tes3.triggerCrime({type = tes3.crimeType.theft, victim = owner, value = totalValue})
			end
		)
	end

	mwscript.disable({reference = ref, modify = true})
	tes3.playSound({sound = 'Item Book Up'})
	mwscript.addItem({ reference = player, item = id, count = num })
	---tes3.messageBox("adding plain paper")
	mwscript.setDelete({reference = ref})
	return false -- consume event
end
event.register('activate', activate)

local function overridePlainPaperScript()
	-- do nothing
end

local function loaded()
	---mwse.log("%s loaded", modPrefix)
	local obj = tes3.getObject(sc_paper_plain_id)
	if not obj then
		mwse.log("%s loaded: warning %s not found", modPrefix, sc_paper_plain_id)
		return
	end

-- begin tweakables
-- note: changes to obj cannot be done in initialized event, must wait for loaded after initialized (could be 2nd loaded if a new game is started)
	mwse.log("%s loaded: obj = %s", modPrefix, obj)
	obj.value = 3
	obj.weight = 0.05
	obj.enchantCapacity = blanks[sc_paper_plain_id]
	---assert(obj.enchantCapacity == blanks[sc_paper_plain_id]) -- check if something wrong here
-- end tweakables

	local script = obj.script
	if script then
		local scriptId = script.id
		if scriptId then
			---mwse.log("%s loaded: scriptId = %s", modPrefix, scriptId)
			mwse.overrideScript(scriptId, overridePlainPaperScript)
			mwse.log("%s loaded: script %s overridden", modPrefix, scriptId)
		end
	end

	local player = tes3.player
	assert(player)

	for id, _ in pairs(blanks) do
		local c = mwscript.getItemCount({ reference = player, item = id })
		---mwse.log("id = %s, c = %s", id, c)
		
		if c > 0 then
			local params = { reference = player, item = id, count = c }
			-- remove blank item already in player inventory as it could be old version
			---tes3.removeItem(params) -- does not work well
			mwscript.removeItem(params)
			---mwse.log("removeitem %s %s", params.item, params.count)
			-- add new version item back so they hopefully stack
			---tes3.addItem(params)
			timer.delayOneFrame( function () mwscript.addItem(params) end )
			---mwse.log("additem %s %s", params.item, params.count)
		end
	end

end

local function initialized()
	---mwse.log("%s initialized", modPrefix)
	event.register('loaded', loaded) -- do this in initialized so 1st loaded on new game before initialized is skipped
end
event.register('initialized', initialized)
