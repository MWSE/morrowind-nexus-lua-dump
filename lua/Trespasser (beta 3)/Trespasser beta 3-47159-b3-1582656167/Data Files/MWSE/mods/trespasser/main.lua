local _path = 'trespasser'
local _config = require(_path..'.config')
local _functions = require(_path..'.funcs')

local function pr(str,...)
	mwse.log('trespasser b3: '..str,...)
end

local function dpr(str,...)
	if _config.debug then mwse.log('trespasser b3: '..str,...) end
end

local function dbg(check, text, disabled)
	if _config.debug and not disabled then 
		dpr('check %s result: %s', text, check and 'true' or 'false') 
	end
	return check
end

local function is_illegal_time()
	local h = tes3.worldController.hour.value
	return h < _config.night_end or h > _config.night_start
end

local function owner_check(cell)
	for ref in cell:iterateReferences() do
		local found, c = nil, 0
		if ref.object.objectType == tes3.objectType.npc then
			found = ref
			c = c + 1
		end
		if c == 1 then
			return found.object.disposition >= _config.min_owner_disposition
		end
	end
	return false
end

local function find_check(tocheck, t)
	for i,v in ipairs(t) do
		if string.find(tocheck,v) then
			return true
		end
	end
end

local function is_cell_illegal(cell)
	local id = cell.id
	local name = cell.name
	
	if _config.cell_specific[id] then
		dpr('[%s] has specific settings', id)
		local k = _config.cell_specific[id]
		if _functions[k] then
			return _functions[k]()
		end
	end
	
	-- outside cells are always legal
	local is_interior = cell.isInterior
	if not is_interior then 
		return false 
	end
	
	-- some places are always illegal regardless of time
	local always_illegal = find_check(id, _config.always_illegal)
	if always_illegal then
		return true
	end
	
	
	local rest_is_illegal = cell.restingIsIllegal
	local illegal_time = is_illegal_time()
	local in_whitelist = find_check(id, _config.find_whitelist)
	local in_blacklist = find_check(id, _config.find_blacklist)
	local owner_friend = owner_check(cell)
	
	dpr('[%s]', cell.id)
	dpr('illegal_time: %s', illegal_time and true or false)
	dpr('in_whitelist: %s', in_whitelist and true or false)
	dpr('in_blacklist: %s', in_blacklist and true or false)
	dpr('owner_friend: %s', owner_friend and true or false)
	if in_whitelist then
		if in_blacklist then
			return rest_is_illegal and illegal_time
		end
		return false
	end
	
	return rest_is_illegal and illegal_time and not owner_friend
end

local f_sim_ts = tes3.getSimulationTimestamp
local _need_message
local function on_cellChanged(e)
	if not _config.enabled then return end
	local cell = tes3.dataHandler.currentCell
	dpr('testing %s', cell.id)
	if is_cell_illegal(cell) then
		pr('[%s] is illegal cell',cell.id)
		for ref in tes3.dataHandler.currentCell:iterateReferences() do
			if ref.object.objectType == tes3.objectType.npc then
				dpr('setting alarm to 100 for %s',ref.id)
				ref.mobile.alarm = 100
			end
		end
	end
	_need_message = true
end

local _next_trigger
local _skip = 0
local function on_simulate(e)
	if not _config.enabled then return end
	
	local current_cell = tes3.dataHandler.currentCell
	if not current_cell then return end
	
	
	if (_skip % 2) > 0 then 
		_skip = 0
		return 
	end
	_skip = _skip + 1
	
	local now = f_sim_ts() 
	if _need_message then
		if is_cell_illegal(current_cell) then
			tes3.messageBox("You are not supposed to be here!")
		end
		_need_message = nil
	end
	
	if _next_trigger and now < _next_trigger then 
		return 
	end
	
	_next_trigger = nil
	
	if is_cell_illegal(current_cell) and not _cooldown then
		tes3.triggerCrime({
			type = tes3.crimeType.trespass,
			value = 5,
		})
	end
end

function on_crimeWitnessed(e)
	-- if e.type == 'trespass' then
	_next_trigger = f_sim_ts() + (5/60)
	-- end
end

local function on_initialized()
	event.register('cellChanged', on_cellChanged)
	event.register('simulate', on_simulate)
	event.register('crimeWitnessed', on_crimeWitnessed)
	mwse.log('[Trespasser] initialized, version beta 3')
end
event.register('initialized', on_initialized)