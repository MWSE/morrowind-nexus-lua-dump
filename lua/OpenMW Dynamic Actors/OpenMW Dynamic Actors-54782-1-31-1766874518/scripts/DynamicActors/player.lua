-- local anim = require("openmw.animation")
local self = require("openmw.self")
local types = require("openmw.types")
local time = require("openmw_aux.time")
local input = require("openmw.input")
local async = require("openmw.async")
local core = require("openmw.core")
local util = require("openmw.util")
local camera = require("openmw.camera")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local nearby = require("openmw.nearby")
local l10n = core.l10n("DynamicActors")


-- local ST = types.Actor.STANCE
local Actor = {
	getStance = types.Actor.getStance,
	getEquipment = types.Actor.getEquipment,
	inventory = types.Actor.inventory,
	isActor = types.Actor.objectIsInstance,
	isSwimming = types.Actor.isSwimming,
	isDead = types.Actor.isDead,
	isWerewolf = types.NPC.isWerewolf,
	setEquipment = types.Actor.setEquipment,

	Helmet = types.Actor.EQUIPMENT_SLOT.Helmet,
	Shield = types.Actor.EQUIPMENT_SLOT.CarriedLeft,
	stanceNone = types.Actor.STANCE.Nothing
}
local stance = Actor.getStance(self)		local v3 = util.vector3

local MD = {
	FirstPerson = camera.MODE.FirstPerson,
	ThirdPerson = camera.MODE.ThirdPerson,
	Preview = camera.MODE.Preview,
	Static = camera.MODE.Static,
	getMode = camera.getMode,
	setMode = camera.setMode
}


local settings = { names = {
	{ "camera", "Settings_dynactors_camera", "playerSection" },
	{ "player", "Settings_dynactors_player", "playerSection" },
	{ "global", "Settings_dynamicactors", "globalSection" }
	},
	storage = {},
	update = {}
}

for _, v in ipairs(settings.names) do
	settings[v[1]] = storage[v[3]](v[2])
	settings.storage[v[1]] = v[2]
end


local dialogModes = {
	[I.UI.MODE.Barter] = true,
	[I.UI.MODE.Companion] = true,
	[I.UI.MODE.Dialogue] = true,
	[I.UI.MODE.Enchanting] = true,
	[I.UI.MODE.MerchantRepair] = true,
	[I.UI.MODE.Travel] = true,
	[I.UI.MODE.Training] = true,
	[I.UI.MODE.SpellBuying] = true,
	[I.UI.MODE.SpellCreation] = true,
--	[I.UI.MODE.Persuasion] = true,
}

local forceHudModes = {
	[I.UI.MODE.Alchemy] = true,
	[I.UI.MODE.Barter] = true,
	[I.UI.MODE.Container] = true,
	[I.UI.MODE.Companion] = true,
	[I.UI.MODE.Enchanting] = true,
	[I.UI.MODE.MerchantRepair] = true,
	[I.UI.MODE.Recharge] = true,
	[I.UI.MODE.Repair] = true,
	[I.UI.MODE.SpellBuying] = true,
	[I.UI.MODE.SpellCreation] = true,
	[I.UI.MODE.Training] = true,
}

local raceChangeModes = {
	[I.UI.MODE.ChargenRace] = true,
	[I.UI.MODE.ChargenClassReview] = true
}

local notIdle, posing = true, false
local V = { idle2sec = 2, idleCounter = 0, idlenum = 0 }

local actionKey = nil
local currentanim = 1
local poseOpt = {save=1, choose=false, count=0}
local dialogTarget = nil
local dialogCam = { controls=false, block=false, instant=false, firstAuto=false,
	height=100, interval=2, counter=0, adjust=true, pos=nil }
poseOpt.offset3rd = camera.getFocalPreferredOffset()
local zoom1st = {enabled=false, dist=70, speed=1, offset=0, force=false, level=0, vector=nil}
local camsave = {mode=camera.getMode(), offset=nil, offset1st=nil, offset3rd=poseOpt.offset3rd, extrayaw=0}
local doUpdates = false
local logging = false
local combatActors = {}


common = {
	poseOpt=poseOpt, zoom1st=zoom1st, dialogCam=dialogCam, camSave = camsave,
	MD=MD, Actor = Actor,
	omw = { self=self, input=input, core=core, util=util, camera=camera,
		ui=ui, interfaces=I }
}


local Anim = require("scripts.DynamicActors.playerAnimations")

common.anims = Anim		common.Anim = Anim
Anim.isBeast = types.NPC.races.records[types.NPC.records[self.recordId].race].isBeast

local dCam = require("scripts.DynamicActors.playerCamera")
local heights = require("scripts.DynamicActors.configCamera")
heights.byRecord = require("scripts.DynamicActors.userConfig.Dialog NPC Camera positions")

local L = {
	getActiveGroup = Anim.getActiveGroup,
	getStance = types.Actor.getStance,
	activeEffects = types.Actor.activeEffects(self),
	controls = self.controls
}

function settings.update.camera(_, key)
	dialogCam.firstAuto = settings.camera:get("dialog_1stperson")
	dialogCam.firstZoom = settings.camera:get("dialog_1st_zoom")
--	zoom1st.zoomIn = settings.camera:get("dialog_1st_zoom")
	zoom1st.dist = settings.camera:get("dialog_1st_zoomdist")
end

function settings.update.player(_, key)
	actionKey = settings.player:get("actionHotkey")
	if key and key:find("^baseIdleAnim_") then
--		print("Update idle animation")
		for _, v in ipairs(Anim.clear) do Anim.cancel(self, v)	end
		V.idleCounter = 6
	end
end

function settings.update.global()
	local pause = settings.global:get("unpause_dialog_opt") == "opt_alwayspause"
	for m in pairs(dialogModes) do
		I.UI.setPauseOnMode(m, pause)
	end
	I.UI.setPauseOnMode("Dialogue", true)
	logging = settings.global:get("debuglog")	common.logging = logging
	Anim.visibleShields = settings.global:get("visible_shields")
end

for k, v in pairs(settings.update) do
	v()
	settings[k]:subscribe(async:callback(v))
end


local helm = { idle = nil, combat = nil }
do
	local id = settings.player:get("autoHelmItemID")
	helm.combat = id and Actor.inventory(self):find(id)
	local id2 = settings.player:get("autoHelmItemID2")
	if id2 == id1 then id2 = nil		end
	helm.idle = id2 and Actor.inventory(self):find(id2)
end


local function getActorHeight(o)
	if types.Creature.objectIsInstance(o) then
		local box = o:getBoundingBox()
		return (box.center.z + box.halfSize.z - o.position.z) / o.scale
	end
	local rec = types.NPC.records[o.recordId]
	local gender = rec.isMale and "male" or "female"
	return types.NPC.races.records[rec.race].height[gender] * 128
end

local function getActorRatios(o)
	if types.Creature.objectIsInstance(o) then
		return util.transform.scale(1, 1, 1)
	end
	local rec = types.NPC.records[o.recordId]
	local gender = rec.isMale and "male" or "female"
	local height = types.NPC.races.records[rec.race].height[gender]
	local weight = types.NPC.races.records[rec.race].weight[gender]
	return util.transform.scale(weight, weight, height)
end

local function onDialogOpened(data)
	camsave.offset1st = camera.getFirstPersonOffset()
	camsave.dist3rd = camera.getThirdPersonDistance()
	camsave.hud = I.UI.isHudVisible()
	zoom1st.level, zoom1st.scale, zoom1st.force, zoom1st.zoomOut = 0, 1, false, false
	zoom1st.speed = settings.camera:get("dialog_1st_zoom_speed") / 100
	zoom1st.offset = math.rad(settings.camera:get("dialog_1st_zoom_offset"))
	zoom1st.dist = settings.camera:get("dialog_1st_zoomdist")
	camsave.yaw, camsave.pitch, camsave.extrayaw = camera.getYaw(), camera.getPitch(), camera.getExtraYaw()
	local npc = data.arg			dialogTarget = npc
	local distance = (npc.position - self.position):length()
	if data.pause or distance > 1000 or not data.near then
		return
	end

	local d = dialogCam
	d.interval, d.counter, d.adjust = 2, 0, true
--	d.playerHeight = getActorHeight(self) * self.scale
--	d.playerEyesVec = v3(0, 0, d.playerHeight * 0.974)
	d.playerEyesVec = v3(0, 0, getActorHeight(self) * self.scale * 0.974)
	d.target = npc
	d.radius, d.head, d.animKeys = 0
	d.npcSizeRatios = getActorRatios(npc)
--	d.height = types.Creature.objectIsInstance(npc) and getActorHeight(npc) * 0.85 or 128 * 0.85
--	d.vecFocalDefault = d.npcSizeRatios:apply(v3(0, 0, d.height * npc.scale))
	d.vecFocalDefault = v3(0, 0, getActorHeight(npc) * npc.scale * 0.85)

	d.barsRatio = settings.camera:get("dialog_1st_ratio") or 0
	dCam.enableShaders(true)
	d.aperture = d.shaders and settings.camera:get("dialog_1st_dof_str") / 100 or 0
--	d.ratio = d.shaders and settings.camera:get("dialog_1st_ratio") or 0

	local file = npc.type.records[npc.recordId].model:lower() or ""
	local height = heights.byAnim[file]
	if not height then
		local i, j = string.find(file, "/[^/]*$")
		file = i and string.sub(file, i+1, j) or file
		height = heights.byAnim[file]
	end

	local useBox, focusHeight, focusVec = true
	if height then
		useBox = false
		d.animKeys = height.keys
		local vec = height.focal or (height[1] and v3(0, 0, height[1]))
		d.headPosAnim = vec and d.npcSizeRatios:apply(vec) * npc.scale or d.vecFocalDefault
		if logging and next(height) then	print(file)		end
		zoom1st.dist = height.distance and math.max(height.distance, zoom1st.dist) or zoom1st.dist
	elseif types.Creature.objectIsInstance(npc) then
		for _, v in ipairs(heights.byModel) do
			if file:find(v.id) then
		--		print(v.id, v.height, v.scale)
				useBox = false
				focusHeight = v.height
				if v.scale then zoom1st.scale = v.scale		end
				if v.radius then d.radius = v.radius		end
				if v.focal then focusVec = v.focal		end
			end
		end
	end
	for _, v in ipairs(heights.byRecord) do
		if string.find(npc.recordId, "^"..v.id) then
			useBox = false
			if v.height then focusHeight = v.height		end
		--	if v.camAdjust then d.adjust = v.camAdjust		end
			if v.camAdjust ~= nil then d.adjust = v.camAdjust	end
		--	if v.scale then zoom1st.scale = v.scale			end
			if v.radius then d.radius = v.radius			end
			if v.focal then focusVec = v.focal			end
			zoom1st.dist = v.distance and math.max(v.distance, zoom1st.dist) or zoom1st.dist
			break
		end
	end
	if useBox then
		local box = npc:getBoundingBox()
		focusHeight = (box.center.z + box.halfSize.z - npc.position.z) * 0.85 / npc.scale
		if types.Creature.objectIsInstance(npc) then
			d.radius = math.max(box.halfSize.x, box.halfSize.y) / npc.scale
		end
	end

	if focusHeight and not focusVec then
		focusVec = v3(0, 0, focusHeight)
	end
	if focusVec then
		d.vecFocalDefault = d.npcSizeRatios:apply(focusVec) * npc.scale
	end
	focusVec = focusVec or d.vecFocalDefault

--	d.pos = npc.position	
	d.deltaPos = npc.position - self.position
	dCam.autoCamUpdate(0)
--	if d.head then
--		d.head = d.npcSizeRatios:apply(d.head) * npc.scale
--	else
--		d.head = d.vecFocalDefault
--	end
	d.radius = d.radius * npc.scale
	if logging then print(focusVec, d.radius)		end

	zoom1st.zoomIn = d.firstZoom
	local res = nearby.castRay(d.playerEyesVec + self.position, focusVec + npc.position,
		{ ignore={self, npc} })
	if res.hitObject and Actor.isActor(res.hitObject)
		and (self.position - npc.position):length() < 250 then
	elseif res.hit then
		zoom1st.zoomIn = false
	end
	d.controls, d.isActive, d.instant = false, true, false
	if settings.camera:get("dialog_disableHud") and I.UI.isHudVisible() then
		I.UI.setHudVisibility(false)
	end
	if not posing then
		camsave.mode, camsave.offset3rd = camera.getMode(), camera.getFocalPreferredOffset()
		if d.firstAuto and settings.global:get("unpause_dialog_opt") ~= "opt_alwayspause" then
			if camera.getMode() ~= MD.FirstPerson then
				camera.setMode(MD.FirstPerson)
				d.instant = true
			end
		end
	end
	doUpdates = true
end

local function onDialogClosed(data)
	dialogTarget  = nil
--	if camsave.hud ~= I.UI.isHudVisible() then I.UI.setHudVisibility(camsave.hud) end
	I.UI.setHudVisibility(true)
	if camera.getMode() == MD.FirstPerson and zoom1st.offset ~= 0 then
		camera.setExtraYaw(camsave.extrayaw)
	end

	dialogCam.isActive = false		zoom1st.zoomIn = false
	zoom1st.zoomOut = zoom1st.force
	if not posing then
		camera.setFocalPreferredOffset(camsave.offset3rd)
		if not zoom1st.zoomOut then	dCam.restoreCamera()		end
	end
end

--	Precaution if game was saved during dialogue
I.UI.setHudVisibility(true)

local function stopPosing()
	Anim.handler("cancel", Anim.poses[currentanim].id)
	camera.setFocalPreferredOffset(camsave.offset3rd)
	I.Controls.overrideMovementControls(false)
	posing = false
	V.idlenum = 0
	ui.showMessage(l10n("msg_moveon"))
	if camera.getMode() ~= MD.Preview then		return		end

	if camsave.mode == MD.FirstPerson then
		async:newUnsavableSimulationTimer(0.1, function() camera.setMode(MD.FirstPerson) end)
	else
		-- camera.lua expects ThirdPerson when in combat stance
		if Actor.getStance(self) ~= Actor.stanceNone then
			async:newUnsavableSimulationTimer(1, function()
				if camera.getMode() == MD.Preview then
					camera.setMode(MD.ThirdPerson)
				end
			end)
		end
		camera.setMode(camsave.mode)
	end
end


time.runRepeatedly(function()
	local dt = 1
	if dialogTarget and camera.getMode() == MD.FirstPerson then
		dCam.autoCamUpdate(dt)
	end
	if posing and not Anim.handler("isPlay", Anim.poses[currentanim].id) then stopPosing() end
--	if notIdle then notIdle = false		return		end
	V.idle2sec = V.idle2sec - 1		if V.idle2sec > 0 then		return		end
	V.idle2sec = 2			dt = 2

	if camera.getMode() == MD.FirstPerson
		or L.activeEffects:getEffect("levitate").magnitude > 0
		or Actor.isSwimming(self) or Actor.isWerewolf(self) then
		V.idleCounter = 0
		return
	end
	if posing or not types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.Controls) then
		V.idleCounter = 0		return
	end

	if V.idlenum == 0 then
		V.idlenum = 1
		V.idleCounter = 26
	end
	V.idleCounter = V.idleCounter + dt
	local legs = Anim.idle.base[Anim.settings[settings.player:get("baseIdleAnim_main")]]
	local top = Anim.idle.base[Anim.settings[settings.player:get("baseIdleAnim_upper")]]
	if V.idleCounter == 6 and top.id ~= legs.id and Anim.handler("isPlay", top.id) then
		Anim.handler("cancel", top.id)
	end
	if V.idleCounter < 32 then
		if V.idleCounter > 5 and V.idleCounter < 28 then
			if not Anim.handler("isPlay", legs.id) then
				Anim.handler("play", legs.id, {loops=50, priority=1, speed=legs.speed})
			end
			if not Anim.handler("isPlay", top.id) and top.id ~= legs.id then
				Anim.handler("play", top.id, {loops=50, priority=2, blendMask=(top.mask or 12), speed=top.speed})
			end
		end
		return
	end
	V.idleCounter = 0
	if not settings.player:get("rndIdleAnim") then		return		end

	for i=1, #Anim.clear do	Anim.cancel(self, Anim.clear[i])	end
	local rnd = Anim.idle.rnd[math.random(2)]
	for i=1, V.idlenum do
		local a, options = rnd[i].id, {}
		for k, v in pairs(rnd[i].opt) do	options[k] = v		end
		options.priority = i + 2
		Anim.handler("play", a, options)
	end
	if V.idlenum == 1 then V.idlenum = 2		end

end, 1 * time.second)


local function startPosing()
	ui.showMessage(l10n("msg_moveoff"))
	posing = true			doUpdates = true
	for _, v in ipairs(Anim.clear) do	Anim.cancel(self, v)		end
	local offset = Anim.poses[currentanim].offset
	local speed = Anim.poses[currentanim].speed or 1
	if offset then
		poseOpt.offset3rd = util.vector2(camsave.offset3rd.x, offset)
		camera.setFocalPreferredOffset(poseOpt.offset3rd)
	else
		poseOpt.offset3rd = camsave.offset3rd
	end
	local options = {loops=200, priority=5, speed=speed}
	if Anim.poses[currentanim].force then options.forceLoop = true		end
	Anim.handler("play", Anim.poses[currentanim].id, options)
end

local function onKeyPress(key)
	if (key.code ~= actionKey) then			return		end
	if core.isWorldPaused() or notIdle then		return		end
	if dialogTarget then
		if camera.getMode() == MD.ThirdPerson then camera.setMode(MD.Preview)		end
		if camera.getMode() == MD.Preview then
			dialogCam.controls = not dialogCam.controls
			if dialogCam.controls then
				doUpdates = true
				ui.showMessage(l10n("msg_ctrlon"))
			else
				ui.showMessage(l10n("msg_ctrloff"))
			end
		end
		return
	end
	if posing then		stopPosing()		return			end
	if L.activeEffects:getEffect("levitate").magnitude > 0
		or Actor.isSwimming(self) or Actor.isWerewolf(self) then
		return
	end
	if Actor.getStance(self) ~= Actor.stanceNone then	return		end
	camsave.mode, camsave.offset3rd = camera.getMode(), camera.getFocalPreferredOffset()
	I.Controls.overrideMovementControls(true)
	currentanim, poseOpt.choose = poseOpt.save, false
	for _, v in ipairs(Anim.clear) do Anim.cancel(self, v) end
	local offset = Anim.poses[currentanim].offset
	local speed = Anim.poses[currentanim].speed or 1
	if Anim.poses[currentanim].turn then
		async:newUnsavableSimulationTimer(0.2, function() core.sendGlobalEvent("objTurn", {object=self, angle=180}) end)
	end
	camera.setMode(MD.Preview)
	async:newUnsavableSimulationTimer(0.5, function() startPosing() end)
end

input.registerTriggerHandler("Jump", async:callback(function()
	if dialogTarget or not posing then return end
	poseOpt.choose = not poseOpt.choose
	if poseOpt.choose then ui.showMessage(l10n("msg_selecton"))
	else ui.showMessage(l10n("msg_selectoff")) end
end))


local function procStanceChange(inCombat)
	if Anim.isPlaying(self, "spellcast") then	return		end
	if Actor.isWerewolf(self) or not settings.player:get("autoHelm") then
		stance = Actor.getStance(self)
		return
	end
	local equip, head = Actor.getEquipment(self), Actor.Helmet
	local h = equip[head]
	if inCombat and helm.combat then
		equip[head] = helm.combat
		Actor.setEquipment(self, equip)
		return
	end
	local store1, store2 = settings.player:get("autoHelmItemID"), settings.player:get("autoHelmItemID2")
	local id = h and h.recordId
	if Actor.getStance(self) == Actor.stanceNone then
		helm.combat = h
		if id and store1 ~= id then
			settings.player:set("autoHelmItemID", id)
		end
		equip[head] = helm.idle
	elseif stance == Actor.stanceNone then
		if h ~= helm.combat then helm.idle = h			end
		if id and id ~= store2 and id ~= store1 then
			settings.player:set("autoHelmItemID2", id)
		end
		if helm.combat then equip[head] = helm.combat		end
	end
	Actor.setEquipment(self, equip)
	stance = Actor.getStance(self)
end

local function processCamera(dt)
	local active
	if posing then
		active = true
		if camera.getMode() ~= MD.Preview then
			stopPosing()
		elseif not dialogTarget then
			dCam.processControls(dt)
		end
	end
	if dialogTarget then
		if dialogCam.isActive and camera.getMode() == MD.FirstPerson then
			dCam.autoCam(dt)				active = true
		elseif dialogCam.controls and camera.getMode() == MD.Preview then
			dCam.processControls(dt, dialogTarget)		active = true
		end
	end
	if zoom1st.zoomOut then
		dCam.zoomOut1st(dt)			active = true
	end
	if not active then
		doUpdates = false
	--	print("processCamera OFF")
	end
end

local function onUpdate(dt)
	if dt <= 0 then				return		end
	local st = L.getStance(self)
	if st ~= stance then procStanceChange()			end
	if doUpdates then processCamera(dt)			end
	if notIdle then notIdle = false		return		end

	local g = L.getActiveGroup(self, 0)
	notIdle = st ~= Actor.stanceNone or L.controls.sneak or not Anim.idleGroups[g]
	if not notIdle then	return		end

	if not g:find("^turn") and V.idlenum > 0 then
		for _, v in ipairs(Anim.clear) do Anim.cancel(self, v)		end
		V.idlenum = 0
	end
	if posing then		stopPosing()	end
end


local function uiModeChanged(data)
	if raceChangeModes[data.oldMode] then
		Anim.isBeast = types.NPC.races.records[types.NPC.records[self.recordId].race].isBeast
	--	print("TRACK RACE MENU EVENT")
	end
	if dialogModes[data.newMode] and not dialogModes[data.oldMode]
		and data.arg and dialogTarget ~= data.arg then
		data.player = self		data.near = self.cell == data.arg.cell
		for _, v in ipairs(nearby.actors) do
			if combatActors[v.id] and not Actor.isDead(v) then
				data.pause = true
			end
		end
		if not data.pause then		combatActors = {}		end
		if data.arg ~= self and Actor.isActor(data.arg) then
			core.sendGlobalEvent("dynDialogOpened", data)
			onDialogOpened(data)
		end
	elseif dialogModes[data.newMode] and dialogTarget then
		core.sendGlobalEvent("dynDialogChange", data)
	elseif data.newMode == nil and dialogTarget then
		core.sendGlobalEvent("dynDialogClosed", data)
		onDialogClosed(data)
	end
	if not dialogTarget then	return		end
	if forceHudModes[data.newMode] then
		if not I.UI.isHudVisible() then I.UI.setHudVisibility(true)		end
	elseif settings.camera:get("dialog_disableHud") and I.UI.isHudVisible() then
		if data.newMode then I.UI.setHudVisibility(false)			end
	end
end


return {
	engineHandlers = {
		onUpdate = onUpdate, onKeyPress = onKeyPress,
		onQuestUpdate = function(id, stage)
			if dialogTarget then
				dialogTarget:sendEvent("dynamicActors",
					{event="onQuestUpdate", questId=id, questStage=stage})
			end
		end
	},
	eventHandlers = {
	UiModeChanged = uiModeChanged,
	tes3InfoGetText = function(e) if dialogTarget then dialogTarget:sendEvent("dynInfoEvent", e) end end,
	dynUiMessage = function(e) ui.showMessage(l10n(e)) end,
	OMWMusicCombatTargetsChanged = function(e)
		if next(e.targets) == nil or not e.actor then 		return		end
		local inCombat
		for _, target in ipairs(e.targets) do
			if target == self.object then
				inCombat = true
				break
			end
		end
		combatActors[e.actor.id] = inCombat
		if not inCombat then		return			end
		if dialogTarget then core.sendGlobalEvent("dynForcePause")		end
		local pos1, pos2 = e.actor.position, self.object.position
		if (pos1 - pos2):length() > 2000 then			return		end
		if math.abs(pos1.z - pos2.z) > 1000 then		return		end
		procStanceChange(true)
	end
	},

	interfaceName = "DynamicActors",
	interface = {
		version = 115,
		updates = function()	return doUpdates		end,
		bars = dCam.bars,
--[[
		dcam = function()	return dialogCam		end,
		combat = function()	return combatActors		end
--]]
	}

}
