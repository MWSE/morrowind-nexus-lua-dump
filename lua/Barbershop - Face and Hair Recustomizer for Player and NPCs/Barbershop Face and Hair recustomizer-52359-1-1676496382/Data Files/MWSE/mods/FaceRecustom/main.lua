local index = 0
local hairIndex = 0
local apply = 0
local heads = {}
local hairs = {}

--fetch config file
local confPath = "barber_config"
local configDefault = {
	disabled = false
}
local config = mwse.loadConfig(confPath, configDefault)

if not config then
    config = { blocked = {} }
end


local function contains(set, key)
    return set[key] ~= nil
end

local function reset(e)

	if config.disabled then
		return
	end
	
	local p
	
	if tes3.menuMode() then
		return
	end
	
	if ( e.isShiftDown ) then
		p = tes3.player
	elseif ( e.isAltDown ) then
		local rayhit = tes3.rayTest {position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}};

		if rayhit and rayhit.reference then	
			if rayhit.reference.object.objectType == tes3.objectType.npc then
				p = rayhit.reference
			end
		else
			return
		end
	else
		return
	end
	
	if ( p == nil ) then
		return
	end
	
	-- reset all the data and return npc to original looks
--	p.data.lackFace.faceIndex = nil
--	p.data.lackFace.hairIndex = nil
	p.data.lackFace = nil
	
	index = 0
	hairIndex = 0
	
	p:updateEquipment()
end

local function changeFace(e) -- change index for target's face
	if config.disabled then
		return
	end
	
	local p
	
	if tes3.menuMode() then
		return
	end
	
	if ( e.isShiftDown ) then --target player
		p = tes3.player
	elseif ( e.isAltDown ) then -- target what player is looking at
		local rayhit = tes3.rayTest {position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}};

		if rayhit and rayhit.reference then	
			if rayhit.reference.object.objectType == tes3.objectType.npc then
				p = rayhit.reference
			end
		else
			return
		end
	else
		return
	end
	
	if ( p == nil ) then
		return
	end
	
	if ( e.isControlDown ) then
		index = index - 1
	else
		index = index + 1
	end

	p.data.lackFace = p.data.lackFace or {}
	p.data.lackFace.faceIndex = index
	
--	tes3.messageBox("index: %s", index)
	
	p:updateEquipment()
end

local function changeHair(e) --change index for targets hair
	if config.disabled then
		return
	end
	
	local p
	
	if tes3.menuMode() then
		return
	end
	
	if ( e.isShiftDown ) then
		p = tes3.player
	elseif ( e.isAltDown ) then
		local rayhit = tes3.rayTest {position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}};

		if rayhit and rayhit.reference then	
			if rayhit.reference.object.objectType == tes3.objectType.npc then
				p = rayhit.reference
			end
		else
			return
		end
	else
		return
	end
	
	if ( p == nil ) then
		return
	end
	
	if ( e.isControlDown ) then
		hairIndex = hairIndex - 1
	else
		hairIndex = hairIndex + 1
	end

	p.data.lackFace = p.data.lackFace or {}
	p.data.lackFace.hairIndex = hairIndex
	
	--tes3.messageBox("index: %s", hairIndex)
	
	p:updateEquipment()
end

local function assignHead(e)
	if ( e.reference.data.lackFace == nil ) then
		--tes3.messageBox("No change")
		return
	elseif ( e.reference.data.lackFace.faceIndex == nil ) then
		return
	end


	local faces = {}
	
    if ( e.index == tes3.activeBodyPart.head and e.bodyPart.partType == 0 ) then	   
	
		-- for obj in tes3.iterateObjects() do
			-- if obj.part ~= nil then
				-- if obj.partType == 0 then
					-- if obj.part == 0 then
						-- if (obj.raceName ~= nil) then
							-- if obj.raceName:lower() == e.reference.object.race.id:lower() then
								-- table.insert(faces, obj)
							-- end
						-- end
					-- end
				-- end
			-- end
		-- end
		
		local raceName
		
		if ( e.reference.object.female ) then
			raceName = e.reference.object.race.id:lower() .. "f"
		else
			raceName = e.reference.object.race.id:lower() .. "m"
		end
		
		faces = heads[raceName]
		e.reference.data.lackFace.faceIndex = e.reference.data.lackFace.faceIndex % table.getn(faces)
		index = e.reference.data.lackFace.faceIndex
		
		if ( faces[e.reference.data.lackFace.faceIndex] ~= nil ) then
		--	tes3.messageBox("Part ID: %s", faces[e.reference.data.lackFace.faceIndex].id)
			e.bodyPart = faces[e.reference.data.lackFace.faceIndex]
		end
		
    end
	
end

local function assignHair(e)
	if ( e.reference.data.lackFace == nil ) then
		--tes3.messageBox("No change")
		return
	elseif ( e.reference.data.lackFace.hairIndex == nil ) then
		return
	end

	local rhairs = {}
	
    if ( e.index == tes3.activeBodyPart.hair and e.bodyPart.partType == 0 ) then	   
		local raceName
		
		if ( e.reference.object.female ) then
			raceName = e.reference.object.race.id:lower() .. "f"
		else
			raceName = e.reference.object.race.id:lower() .. "m"
		end
		
		rhairs = hairs[raceName]
		e.reference.data.lackFace.hairIndex = e.reference.data.lackFace.hairIndex % table.getn(rhairs)
		hairIndex = e.reference.data.lackFace.hairIndex
		
		if ( rhairs[e.reference.data.lackFace.hairIndex] ~= nil ) then
		--	tes3.messageBox("Part ID: %s", rhairs[e.reference.data.lackFace.hairIndex].id)
			e.bodyPart = rhairs[e.reference.data.lackFace.hairIndex]
		end
		
    end
	
end


local function initialized()
	
	-- populate arrays with faces and hairs for selection
	for obj in tes3.iterateObjects() do
		if obj.part ~= nil then
			if obj.partType == 0 then -- its a skin
				if obj.part == 0 then -- its a head
					if (obj.raceName ~= nil) then -- some mods add face with no race that break it
						local racename
						if (obj.female) then
							racename = obj.raceName:lower() .. "f"
						else
							racename = obj.raceName:lower() .. "m"
						end
						if contains(heads, racename) then
							table.insert(heads[racename], obj)
						--	mwse.log("Adding %s to %s", racename, obj.id) 
						else
							heads[racename] = {}
							--mwse.log("Adding %s", racename) 
							table.insert(heads[racename], obj)
							--mwse.log("Adding %s to %s", racename, obj.id) 
						end		
					end
				elseif obj.part == 1 then -- its a hair
					if (obj.raceName ~= nil) then
						local racename
						if (obj.female) then
							racename = obj.raceName:lower() .. "f"
						else
							racename = obj.raceName:lower() .. "m"
						end
						if contains(hairs, racename) then
							table.insert(hairs[racename], obj)
					--		mwse.log("Adding %s to %s", racename, obj.id) 
						else
							hairs[racename] = {}
					--		mwse.log("Adding %s", racename) 
							table.insert(hairs[racename], obj)
					--		mwse.log("Adding %s to %s", racename, obj.id) 
						end		
					end				
				end
			end
		end
	end
	
	event.register(tes3.event.bodyPartAssigned, assignHead)
	event.register(tes3.event.bodyPartAssigned, assignHair)
	event.register(tes3.event.keyDown, changeFace, { filter = tes3.scanCode.p } )
	event.register(tes3.event.keyDown, changeHair, { filter = tes3.scanCode.l } )
	event.register(tes3.event.keyDown, reset, { filter = tes3.scanCode.x } )
	
	print("[Barbershop: Face and Hair Recustomizer] Face and Hair Recustomizer Initialized")
end

event.register(tes3.event.initialized, initialized)

local function registerModConfig()
    --get EasyMCM
    local EasyMCM = require("easyMCM.EasyMCM")
    --create template
    local template = EasyMCM.createTemplate("Barbershop: Face and Hair Recustomizer")
    --Have our config file save when MCM is closed
    template:saveOnClose(confPath, config)
    --Make a page
    local page = template:createSideBarPage{
        sidebarComponents = {
            EasyMCM.createInfo{ text = "Barbershop: Face and Hair Recustomizer\nby AlandroSul \n \nControls: \n\nP to change face\nL to change hair\nX to return to default appearance\nHold alt with any of these to target NPC in your crosshair\nHold shift with any of these to target player\nHold control in conjuction with any of these to cycle backwards through heads/hairs rather than forwards" },
        }
    }
    --Make a category inside our page
    local category = page:createCategory("Settings")

    --Make some settings
    category:createButton({
	
        buttonText = "Disable/Enable Recustomizing",
        description = "Disable Recustomizing to lock current appearances if you're worried about changing them by accident",
        callback = function(self)
            config.disabled = not config.disabled
			tes3.messageBox("Customization Disabled: %s", config.disabled)
        end
    })

    --Register our MCM
    EasyMCM.register(template)
end

--register our mod when mcm is ready for it
event.register("modConfigReady", registerModConfig)