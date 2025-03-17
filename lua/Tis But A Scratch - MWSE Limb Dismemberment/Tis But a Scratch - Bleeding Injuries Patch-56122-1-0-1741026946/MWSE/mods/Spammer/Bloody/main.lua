-- changes, should work with any modded blood now /abot

local mod = {
name = "Bleeding Injuries",
ver = "1.7",
cf = { magic = tes3.isLuaModActive("Elemental Effects"), fall = false, shield = true, blocked = {}}
}
local cf = mwse.loadConfig(mod.name, mod.cf)

local player, mobilePlayer, firstPersRef
local function loaded()
	player = tes3.player
	mobilePlayer = tes3.mobilePlayer
	firstPersRef = mobilePlayer.firstPersonReference
	if not player.data.spa_bloodyinjury then
		player.data.spa_bloodyinjury = {}
	end
end

local decalTextures = {}
for i = 3, 12 do
	if not (i == 9) then
		local path = string.format("Textures/tr/tr_decal_blood_%02d.dds", i)
		local tex = niSourceTexture.createFromPath(path)
		if tex then
			table.insert(decalTextures, tex)
		else
			mwse.log('Spammer/Bloody: WARNING: unable to create texture from file "%s"', path)
		end
	end
end

-- this should work with any mod changing textures in Morrowind.ini [Blood] section,
-- e.g. Blood Diversity, Piratelord's creatures /abot
-- set in Initialized
local bloodTextures


local arSlot = tes3.armorSlot
local actvBdyPrt = tes3.activeBodyPart

--[[ some info
tes3.armorSlot:
helmet 0
cuirass	1
leftPauldron 2
rightPauldron 3
greaves 4
boots 5
leftGauntlet 6
rightGauntlet 7
shield 8
leftBracer 9
rightBracer 10
]]

--[[
local validArmor = {
    ["helmet"] = 0,
    ["cuirass"] = 1,
    ["greaves"] = 4,
-- these keys below were not armor/clothing slots /abot
    ["leftHand"] = 6,
    ["rightHand"] = 7,
    ["leftArm"] = 9,
    ["rightArm"] = 10
}
]]

local validKeys = {'helmet','cuirass','leftPauldron','rightPauldron','greaves',
	'leftGauntlet','rightGauntlet','leftBracer','rightBracer',}
local validArmor = {}
for _, k in ipairs(validKeys) do
	validArmor[k] = arSlot[k]
end

--[[ some info
tes3.activeBodyPart:
head 0
hair 1
neck 2
chest 3
groin 4
skirt 5
rightHand 6
leftHand 7
rightWrist 8
leftWrist 9
shield 10
rightForearm 11
leftForearm 12
rightUpperArm 13
leftUpperArm 14
rightFoot 15
leftFoot 16
rightAnkle 17
leftAnkle 18
rightKnee 19
leftKnee 20
rightUpperLeg 21
leftUpperLeg 22
rightPauldron 23
leftPauldron 24
weapon 25
tail 26
]]

local bodyParts = {
[arSlot.helmet] = {actvBdyPrt.head},
[arSlot.cuirass] = {actvBdyPrt.chest},
[arSlot.leftPauldron] = {actvBdyPrt.leftHand},
[arSlot.rightPauldron] = {actvBdyPrt.rightHand},
[arSlot.greaves] = {
	actvBdyPrt.leftUpperLeg, actvBdyPrt.rightUpperLeg, actvBdyPrt.leftKnee, actvBdyPrt.rightKnee
},
[arSlot.leftGauntlet] = {actvBdyPrt.leftHand},
[arSlot.rightGauntlet] = {actvBdyPrt.rightHand},
[arSlot.leftBracer] = {actvBdyPrt.leftForearm},
[arSlot.rightBracer] = {actvBdyPrt.rightForearm}
}

local tes3_niType_NiTriShape = tes3.niType.NiTriShape
local ni_propertyType_texturing = ni.propertyType.texturing

local function addDecal(sceneNode, decal)
	local texturingProperty
	for node in table.traverse({sceneNode}) do
		if node:isInstanceOfType(tes3_niType_NiTriShape) then
			if not node.alphaProperty then
				texturingProperty = node.texturingProperty
				if texturingProperty
				and texturingProperty.canAddDecal then
					-- we have to detach/clone the property
					-- because it could have multiple users
					texturingProperty = node:detachProperty(ni_propertyType_texturing):clone()
					texturingProperty:addDecalMap(decal)
					node:attachProperty(texturingProperty)
					node:updateProperties()
                    node:updateEffects()
				end
			end
		end
	end
end

---@param ref tes3reference
---@param index number
---@param sceneNode niNode
local function addRefDecal(ref, index, sceneNode)
	local data = ref.data
	if not data then
		return
	end
	if not data.spa_bloodydontrandom then
		data.spa_bloodydontrandom = {}
	end
	local decal = table.getset(data.spa_bloodydontrandom, index, decalTextures[math.random(#decalTextures)])
	addDecal(sceneNode, decal)
end

---@param index number
---@param sceneNode niNode
local function addCreaDecal(index, sceneNode)
	addDecal(sceneNode, bloodTextures[index + 1])
end

---@param texturingProperty niTexturingProperty
local function iterEffectDecals(texturingProperty)
	return coroutine.wrap(function()
		for i, map in ipairs(texturingProperty.maps) do
			local texture = map and map.texture
			local fileName = texture and texture.fileName
			if fileName then
				for _, v in pairs(decalTextures) do
					if v.fileName == fileName then
						coroutine.yield(i, map)
						break
					end
				end
			end
		end
	end)
end

---@param ref tes3reference
---@param sceneNode niNode
local function removeDecal(ref, sceneNode)
	if ref.mobile.health.normalized < 0.75 then
		return
	end
	local texturingProperty
	for node in table.traverse({sceneNode}) do
		if node:isInstanceOfType(tes3_niType_NiTriShape) then
			texturingProperty = node:getProperty(ni_propertyType_texturing)
			if texturingProperty then
				for i in iterEffectDecals(texturingProperty) do
					texturingProperty:removeDecalMap(i)
				end
			end
		end
	end
	ref.data.spa_bloodydontrandom = {}
	ref.data.spa_bloodyinjury = {}
end

local tes3_effect_restoreHealth = tes3.effect.restoreHealth
local tes3_effect_absorbHealth = tes3.effect.absorbHealth

---@param e spellResistEventData
local function spellResist(e)
	local effect = e.effect
	local target = e.target
	local effectId = effect.id
	local ok = false
	if effectId == tes3_effect_restoreHealth then
		ok = true
	elseif effectId == tes3_effect_absorbHealth then
		if not (target == e.caster) then
			if e.resistedPercent < 75 then
				ok = true
			end
		end
	end	
	if not ok then
		return
	end
	local spa_bloodyinjury = target.data.spa_bloodyinjury
	if spa_bloodyinjury
	and ( #spa_bloodyinjury > 0 ) then
		local d = effect.duration
		if (not d)
		or (d < 0.2) then
			d = 0.2
		end
		local refHandle = tes3.makeSafeObjectHandle(target)
		timer.start({duration = d, callback =
			function ()
			if not refHandle then
				return
			end
			if not refHandle:valid() then
				return
			end
			local r = refHandle:getObject()
			if not r then
				return
			end
			removeDecal(target, target.sceneNode)
			if target == player then
				removeDecal(player, firstPersRef.sceneNode)
			end
		end})
	end
end

local function menuEnter()
	tes3ui.updateInventoryCharacterImage()
end

local function menuExit()
	removeDecal(player, player.sceneNode)
	removeDecal(player, firstPersRef.sceneNode)
end

local blacklistWeapons = {
[tes3.weaponType.marksmanBow] = true,
[tes3.weaponType.arrow] = true,
[tes3.weaponType.marksmanCrossbow] = true,
[tes3.weaponType.marksmanThrown] = true
}

local tes3_effect_shield = tes3.effect.shield
local tes3_objectType_armor = tes3.objectType.armor
local tes3_objectType_creature = tes3.objectType.creature
local tes3_objectType_npc = tes3.objectType.npc
local tes3_activeBodyPart_weapon = tes3.activeBodyPart.weapon
local tes3_activeBodyPartLayer = tes3.activeBodyPartLayer

local unprotected = {}

---@param e damagedEventData
local function damaged(e)
	local source = e.source
	if (source == "suffocation")
	or (source == "script") then
		return
	end
	if cf.fall
	and (source == "fall") then
		return
	end
	if cf.magic
	and (
		(source == "magic")
	 or (source == "shield")
	) then
		return
	end

	local ref = e.reference
	if not ref then
		return
	end
	if cf.shield
	and tes3.isAffectedBy({reference = ref, effect = tes3_effect_shield}) then
		return
	end

	local mobile = e.mobile
	if not mobile then
		return
	end
	local ratio = mobile.health.normalized
	local data = ref.data
	local spa_bloodyinjury = {}
	if data then
		if not data.spa_bloodyinjury then
			data.spa_bloodyinjury = {}
		end
		spa_bloodyinjury = data.spa_bloodyinjury
	end
	local size = #spa_bloodyinjury
	if (ratio >= 0.8)
	or (
		(ratio >= 0.6)
		and (size >= 1)
	)
	or (
		(ratio >= 0.4)
		and (size >= 2)
	)
	or (
		(ratio >= 0.3)
		and (size >= 3)
	)
	or (
		(ratio >= 0.2)
		and (size >= 4)
	) then
		return
	end
	local obj = ref.baseObject
	local blood = obj.blood
	local attackerMob = e.attacker
	local attackerRef = e.attackerReference
	local firstPersBodyPartManager = firstPersRef.bodyPartManager

	local ok = attackerMob
		and attackerMob.weaponDrawn
		and attackerRef
		and attackerRef.bodyPartManager
	if ok then
		ok = false
		if not attackerMob.readiedWeapon then
			ok = true
		elseif (not blacklistWeapons[attackerMob.readiedWeapon.object.type]) then
			ok = true
		end
	end

	if obj.objectType == tes3_objectType_creature then
		--if (not cf.blocked[obj.id]) then
        addCreaDecal(blood, ref.sceneNode)
        if ok then
            for _, layer in pairs(tes3_activeBodyPartLayer) do
                local activpart = attackerRef.bodyPartManager:getActiveBodyPart(layer, tes3_activeBodyPart_weapon)
                if activpart and activpart.node then
                    addCreaDecal(blood, activpart.node)
                    if mobilePlayer == attackerMob then -- turns out attackerMob may become nil in-between, so put in on right side of comparison
                        local activpart2 = firstPersBodyPartManager:getActiveBodyPart(layer, tes3_activeBodyPart_weapon)
                        addCreaDecal(blood, activpart2.node)
                    end
                end
            end
        end
		--end
	end

	if not (obj.objectType == tes3_objectType_npc) then
		return
	end

	local skip = true
	for k, v in pairs(validArmor) do
		if not tes3.getEquippedItem({actor = ref, objectType = tes3_objectType_armor, slot = v}) then
			if not table.find(spa_bloodyinjury, bodyParts[v]) then
				unprotected[k] = v
				skip = false
			end
		end
	end

	if skip then
		return
	end

	if ok then
		for _,layer in pairs(tes3_activeBodyPartLayer) do
			local activpart = attackerRef.bodyPartManager:getActiveBodyPart(layer, tes3_activeBodyPart_weapon)
			if activpart and activpart.node then
				addRefDecal(attackerRef, tes3_activeBodyPart_weapon, activpart.node)
				if mobilePlayer == attackerMob then -- turns out attackerMob may become nil in-between, so put in on right side of comparison
					local activpart2 = firstPersBodyPartManager:getActiveBodyPart(layer, tes3_activeBodyPart_weapon)
					addRefDecal(firstPersRef, tes3_activeBodyPart_weapon, activpart2.node)
				end
			end
		end
	end

	local choice = table.choice(unprotected)
	local bprt = bodyParts[choice]
	if spa_bloodyinjury then
		if not table.find(spa_bloodyinjury, bprt) then
			ref.data.spa_bloodyinjury[choice] = bprt
		end
	end
	local bpm = ref.bodyPartManager
	if bpm then
		for _, part in ipairs(bprt) do
			for _, layer in pairs(tes3_activeBodyPartLayer) do
				local activpart = bpm:getActiveBodyPart(layer, part)
				if activpart and activpart.node then
					addRefDecal(ref, part, activpart.node)
				end
			end
		end
	end
end


---@param e bodyPartAssignedEventData
local function bodyPartAssigned(e)
	local ref = e.reference
	if not ref then
		return
	end
	local data = ref.data
	if not data then
		return
	end
	if not data.spa_bloodyinjury then
		return
	end
	local mobile = ref.mobile
	if mobile
	and (mobile.health.normalized > 0.75) then
		data.spa_bloodyinjury = {}
		data.spa_bloodydontrandom = {}
		return
	end
	local index = e.index
	local manager = e.manager
	for _, subtable in ipairs(data.spa_bloodyinjury) do
		if table.find(subtable, index) then
			for _, layer in pairs(tes3_activeBodyPartLayer) do
				local activpart = manager:getActiveBodyPart(layer, index)
				if activpart and activpart.node and not activpart.node:isAppCulled() then
					addRefDecal(ref, index, activpart.node)
				end
			end
		end
	end
end

event.register("modConfigReady", function ()
	--[[ hopefully not needed any more /abot
	local function getExclusionList()
		local list = {}
		local id
		for crit in tes3.iterateObjects(tes3_objectType_creature) do
			id = crit.id
			if not (table.find(list, id)) then
				table.insert(list, id)
			end
			if string.multifind(id:lower(), {'ash_','dagoth'}, 1, true) then
				cf.blocked[id] = true
			end
		end
		table.sort(list)
		return list
	end
	]]

	local template = mwse.mcm.createTemplate(mod.name)
	template:saveOnClose(mod.name, cf)
	template:register()

	local page = template:createSideBarPage({label="\""..mod.name.."\" Settings"})
	page.sidebar:createInfo{ text = "Welcome to \""..mod.name.."\" Configuration Menu. \n \n \n A mod by Abot & Spammer."}
    page.sidebar:createHyperlink { text = "Abot's Nexus Profile", url = "https://www.nexusmods.com/morrowind/users/38047?tab=user+files" }
	page.sidebar:createHyperlink{ text = "Spammer's Nexus Profile", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }

	local category0 = page:createCategory("Ignore fall damage?")
	category0:createYesNoButton{label = " ", variable = mwse.mcm.createTableVariable{id = "fall", table = cf}}

	local category1 = page:createCategory("Ignore magic damage?")
	category1:createYesNoButton{label = " ", variable = mwse.mcm.createTableVariable{id = "magic", table = cf}}

	local category2 = page:createCategory("\"Shield\" magic effect protects you from bleeding?")
	category2:createYesNoButton{label = " ", variable = mwse.mcm.createTableVariable{id = "shield", table = cf}}

	--[[ hopefully not needed any more /abot
	template:createExclusionsPage{label = "Creatures Blacklist",
	description = "Adding blood decals to some creatures seem to crash the game.\n"..
	"Since there are too many for me to find out exactly which ones do cause crashes, I added this blacklist.",
		variable = mwse.mcm.createTableVariable{id = "blocked", table = cf}, filters = {{label = " ", callback = getExclusionList}}}
	]]
end)

event.register("initialized", function()
    local splashController = tes3.worldController.splashController
    local bloodTextureCount = splashController.bloodTextureCount
    bloodTextures = splashController.bloodTextures
    --[[
	mwse.log('Spammer/Bloody: bloodTextureCount = %s', bloodTextureCount)
    for i = 1, bloodTextureCount do
        mwse.log('Spammer/Bloody: bloodTextures[%s] = %s', i, bloodTextures[i].fileName)
    end
	--]]
    event.register("loaded", loaded)
    event.register("menuEnter", menuEnter)
    event.register("menuExit", menuExit)
    event.register("bodyPartAssigned", bodyPartAssigned)
    event.register("spellResist", spellResist)
    event.register("damaged", damaged)
end)

