local anim = require("openmw.animation")
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
local l10n = core.l10n("DynamicActors")


local Actor, ST, MD = types.Actor, types.Actor.STANCE, camera.MODE
local stance = types.Actor.getStance(self)		local v3 = util.vector3


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

--[[
-- legacy settings check
do
	local dupe = {
		"dialog_disableHud",
		"dialog_1stperson",
		"dialog_1st_zoom",
		"dialog_1st_zoomdist",
		"dialog_1st_dof_str",
		"dialog_1st_ratio",
		"dialog_1st_zoom_speed",
		"dialog_1st_zoom_offset",
	}

	for _, v in ipairs(dupe) do
		local set = settings.player:get(v)
		if set ~= nil then
			print("Duping "..v.." original ", settings.camera:get(v))
			settings.camera:set(v, set)
			print("New ", settings.camera:get(v))
		end
	end
end
--]]

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

local moved, idlenum, counter = true, 0, 0
local posing = false

local anims = {}

anims.items = { "None", "Hand on Hip contrapose", "Ready Pose", "Idle2", "Arms Folded",
	"Arms Back Clasp", "anim_akimbo" }
anims.settings = {}
for i=1, #anims.items do anims.settings[anims.items[i]] = i end

anims.idle = {
	base = { {id="none", speed=1},
		{id="handhippose", speed=0.5},
		{id="readypose", speed=1},
		{id="idle2", speed=0.5},
		{id="armsfolded", speed=0.5},
		{id="armsatback", speed=0.5},
		{id="armsakimbo", speed=0.5},
	},
	rnd = {
{ {id="armsakimbo", opt={loops=2, speed=1}}, {id="idle4", opt={speed=2}} },
{ {id="armsfolded", opt={loops=2, speed=1}}, {id="idle8", opt={loops=1, speed=2}} }
		}
	}

anims.combo = { ["armsFoldPose"] = { "handhippose", {mask=3}, "armsfolded", {mask=12, spd=1} },
	["armsStrPose"] = { "handhippose", {mask=3} },
	["armsOneBackPose"] = { "handhippose", {mask=3}, "armsatback", {mask=8, spd=1} },
	["armsBackClaspPose"] = { "handhippose", {mask=3}, "armsatback", {mask=12, spd=1} }
	}

anims.clear = { "handhippose", "readypose", "idle2", "armsfolded", "armsakimbo", "armsatback",
	"posealma3" }

anims.poses = require("scripts.DynamicActors.playlist")

anims.isBeast = types.NPC.races.record(types.NPC.records[self.recordId].race).isBeast
anims.beastBlendMasks = {
	handhippose = 0, armsfolded = 12, armsakimbo = 12,
	armsatback = 12, armssunshield = 12, readypose = 0,
	armsfoldpose = 12, armsstrpose = 12, armsonebackpose = 12,
	armsbackclasppose = 12,
	armsalmapray = 12, posealma3 = 0, idle2_copy = 0, idle7_copy = 12, idle8_copy = 12
}

local heights = {

	byAnim = {

	["am_beggar.nif"] = { 35, keys={"idle2", "idle3", "idle4", "idle"} },		-- headnode 0 3 49
	["am_dreamera.nif"] = { 45, keys={"idle2", "idle"} },
	["am_dreamerb.nif"] = { 45, keys={"idle6", "idle"} },
	["am_drummer03.nif"] = { 45, keys={"idle2", "idle"} },
	["am_eater.nif"] = { keys={"idle2"}, focal=v3(0, 25, 40) },	--headnode 0 10 58	headpos 52
	["am_fishman.nif"] = { 45, keys={"idle2", "idle3", "idle"} },
	["am_luteplaying.nif"] = { 45, keys={"idle2", "idle"}, focal=v3(0, 0, 44) },	--headnode 0 7 58	headpos 62
	["am_reader2.nif"] = { 45, keys={"idle2", "idle3", "idle4"} },
	["am_sitting.nif"] = { 52, keys={"idle2", "idle3", "idle4"}, focal=v3(0, 30, 40) },	-- headpos 52
	["am_writer02.nif"] = { 45, keys={"idle2", "idle3", "idle4"} },

	["am_sitbar.nif"] = { 45, keys={"idle8", "idle9"} },
	["bandit.nif"] = { 45, keys={"idle8"} },
	["farmer.nif"] = { 45, keys={"idle8"} },
	["farmer2.nif"] = {45, keys={"idle9"} },
	["prayerdf.nif"] = {53, keys={"idle9"} },
	["prayerdm.nif"] = {53, keys={"idle9"} },	-- headnode 0 13.5 76		idle 0 5.5 124.5
	["slavesitting.nif"] = { 35, keys={"idle9"} },

	["va_sitting.nif"] = { 45, keys={"idle2", "idle3", "idle4", "idle5", "idle6", "idle7", "idle8", "idle9"} },
	["va_sittingdunmertest.nif"] = { 45, keys={"idle2"} },

	["barsitter.nif"] = { 52, keys={"idle2", "idle3", "idle4", "idle5"}, focal=v3(0, 30, 35) },	-- headpos 52
	["wallean.nif"] = { 120, keys={"idle9"}, focal=v3(0, -29, 102) },	-- headpos 120

	["anim_sitpleading.nif"] = { 45, keys={"idle9"} },
	["anim_sitthreatening.nif"] = { 45, keys={"idle9"} },

	-- Shadow of Aetherius
	["sit1.nif"] = { keys={"idle9"}, focal=v3(0, -11, 90) },	-- headpos 90
	["sit2.nif"] = { keys={"idle9"}, focal=v3(0, -30, 25)},	-- headpos -40, 25
	["sit3.nif"] = { keys={"idle9"}, focal=v3(0, 0, 40)},		-- headpos 52

--	["meshes/luce/am/am_luteplaying.nif"] = { }

	},

	byModel = {
		{id="guar.nif$", height=120, radius=165},
		{id="^guar_", height=120, radius=165},
--		{id="guar.nif$", height=120, radius=140, scale=0.3},
--		{id="^guar_", height=120, radius=140, scale=0.3},
--		{id="tr_gremlin", height=45},
--		{id="tr_vile_dae_c.nif", height=140},

	}

}

local actionKey = nil
local currentanim = 1
local poseOpt = {save=1, choose=false, count=0}
-- local savedanim = 1
local dialogTarget = nil
-- local turningToTarget = false
local dialogCam = {controls=false, block=false, instant=false, auto1st=false,
	height=100, interval=2, counter=0, adjust=true, pos=nil}
poseOpt.offset3rd = camera.getFocalPreferredOffset()
local zoom1st = {enabled=false, dist=70, speed=1, offset=0, force=false, level=0, vector=nil}
local camsave = {mode=camera.getMode(), offset=nil, offset1st=nil, offset3rd=poseOpt.offset3rd, extrayaw=0}
local doUpdates = false
local logging = false

common = {
	poseOpt=poseOpt, anims=anims, zoom1st=zoom1st, dialogCam=dialogCam, camSave = camsave,
	openmw = { self=self, input=input, core=core, util=util, camera=camera, ui=ui, interfaces=I }
}

local npcSettings = require("scripts.DynamicActors.configCamera")
local dCam = require("scripts.DynamicActors.cameraHandler")


function settings.update.camera(_, key)
	dialogCam.auto1st = settings.camera:get("dialog_1stperson")
	zoom1st.enabled = settings.camera:get("dialog_1st_zoom")
--	I.Settings.updateRendererArgument("Settings_dynactors_camera", "dialog_1st_zoomdist", {disabled = not zoom1st.enabled})
	zoom1st.dist = settings.camera:get("dialog_1st_zoomdist")
end

function settings.update.player(_, key)
	actionKey = settings.player:get("actionHotkey")
	if key and key:find("^baseIdleAnim_") then
--		print("Update idle animation")
		for _, v in ipairs(anims.clear) do anim.cancel(self, v)	end
		counter = 6
	end
end

function settings.update.global()
	local pause = settings.global:get("unpause_dialog_opt") == "opt_alwayspause"
	for m in pairs(dialogModes) do
		I.UI.setPauseOnMode(m, pause)
	end
	I.UI.setPauseOnMode("Dialogue", true)
	logging = settings.global:get("debuglog")
end

for k, v in pairs(settings.update) do
	v()		settings[k]:subscribe(async:callback(v))
end


local helm = { idle = nil, combat = nil }
do
	local id = settings.player:get("autoHelmItemID")
	helm.combat = id and types.Actor.inventory(self):find(id)
	local id2 = settings.player:get("autoHelmItemID2")
	if id2 == id1 then id2 = nil		end
	helm.idle = id2 and types.Actor.inventory(self):find(id2)
end


local function animHandler(a, g, o)
	local mask = 15
	if anims.isBeast then
		if g:find("_copy$") then g = g:gsub("_copy$", "")	end
		local v = anims.beastBlendMasks[g:lower()]
		if v and a == "play" then
			o = o or {}	mask = v or 12
			o.blendMask = o.blendMask or mask
			o.blendMask = util.bitAnd(v, mask)
		end
	end

	local combo = anims.combo[g]
	local play = true
	if g == "none" then return true end
	if a == "isplay" and not combo then
		return anim.isPlaying(self, g)
	end
	if not combo then
		if a == "play" then anim.playBlended(self, g, o)
		else anim.cancel(self, g) end
		return
	end
	if a == "isplay" then
		if g == "armsFoldPose" and not anim.isPlaying(self, "armsfolded") then play = false end
		if ( g == "armsBackClaspPose" or g == "armsOneBackPose" )
			and not anim.isPlaying(self, "armsatback") then play = false end
		if not anim.isPlaying(self, combo[1]) then play = false end
		return play
	end
	if a == "cancel" then
		anim.cancel(self, "armsfolded")
		anim.cancel(self, "armsatback")
		anim.cancel(self, combo[1])
		return
	end
	local options = {}
	for k, v in pairs(o) do options[k] = v end
--[[
	if g == "armsFoldPose" then
		o.blendMask = 12
	elseif g == "armsBackClaspPose" then
		o.blendMask = 12
	elseif g == "armsOneBackPose" then
		o.blendMask = 8
	end
--]]
	if combo[4] then o.blendMask = util.bitAnd(combo[4].mask, mask)		end
	options.blendMask = combo[2].mask or options.blendMask
	options.blendMask = util.bitAnd(options.blendMask, mask)
--	print(mask, options.blendMask)
	o.priority = o.priority + 1
	anim.playBlended(self, combo[1], options)
	if combo[3] then anim.playBlended(self, combo[3], o)		end
end

local function getActorHeight(o)
	if o.type == types.NPC or o.type == types.Player then
		local gender = "female"
		local npc = types.NPC.record(o)
		if npc.isMale then gender = "male" end
		return types.NPC.races.record(npc.race).height[gender] * 128
	else
		return (o:getBoundingBox().halfSize.z) * 2
--		return 128
	end
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
	camsave.yaw, camsave.pitch, camsave.extrayaw = camera.getYaw(), camera.getPitch(), camera.getExtraYaw()
	local npc = data.arg			dialogTarget = npc
	if not data.near then		return 		end
	if (npc.position - self.position):length() > 1000 then		return		end
	doUpdates = true
	dialogCam.interval, dialogCam.counter, dialogCam.adjust = 2, 0, true
	dialogCam.playerHeight = getActorHeight(self) * self.scale
	dialogCam.object = npc		dialogCam.pos = npc.position
	if npc.type == types.Creature then
		dialogCam.height = getActorHeight(npc) * 0.85
	else
		dialogCam.height = 128 * 0.85
	end
	dialogCam.radius, dialogCam.head, dialogCam.animKeys = 0
	dialogCam.headPosIdle = getActorRatios(npc):apply(v3(0, 0, dialogCam.height * npc.scale))
	dCam.enableShaders(true)
	dialogCam.aperture = dialogCam.shaders and settings.camera:get("dialog_1st_dof_str") / 100 or 0
	dialogCam.ratio = dialogCam.shaders and settings.camera:get("dialog_1st_ratio") or 0

	local file = npc.type.record(npc).model or ""

	--	OMW versions before Nov 19 2024
	file = string.gsub(file, "\\", "/")

	local i, j = string.find(file, "/[^/]*$")
	if i then
		file = string.sub(file, i+1, j)
	end
	file = file:lower()
	local height = heights.byAnim[file]
	if height then
		local vec = height.focal or (height[1] and v3(0, 0, height[1]))
		dialogCam.headPosAnim = getActorRatios(npc):apply(vec) * npc.scale
		if height.keys then
			dialogCam.animKeys = height.keys
			for _, v in ipairs(height.keys) do 
				if anim.isPlaying(npc, v) then
					dialogCam.head = vec
					if logging then print(file, v)		end
				end
			end
		else
			dialogCam.head = vec
		end
	end
	if types.Creature.objectIsInstance(npc) then
		for _, v in ipairs(heights.byModel) do
			if file:find(v.id) then
		--		print(v.id, v.height, v.scale)
				dialogCam.height = v.height
				if v.scale then zoom1st.scale = v.scale			end
				if v.radius then dialogCam.radius = v.radius		end
				if v.head then dialogCam.head = v.focal			end
			end
		end
	end
	for _, v in ipairs(npcSettings) do
		if string.find(npc.recordId, "^"..v.id) ~= nil then
			if v.height then dialogCam.height = v.height		end
			if v.camAdjust then dialogCam.adjust = v.camAdjust	end
--			if v.scale then zoom1st.scale = v.scale			end
			if v.radius then dialogCam.radius = v.radius		end
			if v.focal then dialogCam.head = v.focal			end
			break
		end
	end
	dialogCam.height = dialogCam.height * npc.scale
	if dialogCam.head then
		dialogCam.head = getActorRatios(npc):apply(dialogCam.head) * npc.scale
	else
		dialogCam.head = getActorRatios(npc):apply(v3(0, 0, dialogCam.height))
	end
	dialogCam.radius = (dialogCam.radius or 1) * npc.scale
	if logging then print(dialogCam.head, dialogCam.radius)		end

	dialogCam.controls, dialogCam.isActive, dialogCam.instant = false, true, false
	if settings.camera:get("dialog_disableHud") and I.UI.isHudVisible() then I.UI.setHudVisibility(false) end
	if not posing then
		camsave.mode, camsave.offset3rd = camera.getMode(), camera.getFocalPreferredOffset()
		if dialogCam.auto1st and settings.global:get("unpause_dialog_opt") ~= "opt_alwayspause" then
			if camera.getMode() ~= MD.FirstPerson then
				camera.setMode(MD.FirstPerson)
				dialogCam.instant = true
			end
		end
	end
end

local function onDialogClosed(data)
	dialogTarget  = nil
--	if camsave.hud ~= I.UI.isHudVisible() then I.UI.setHudVisibility(camsave.hud) end
	I.UI.setHudVisibility(true)
	if camera.getMode() == MD.FirstPerson and zoom1st.offset ~= 0 then
		camera.setExtraYaw(camsave.extrayaw)
	end

	if zoom1st.force then zoom1st.zoomOut = true		end
--[[
	if zoom1st.force then camera.setFirstPersonOffset(camsave.offset1st) end
	zoom1st.level, zoom1st.force = 0, false
	dCam.enableShaders(false)
	async:newUnsavableSimulationTimer(2, function() dCam.enableShaders(false) end)
--]]
	if not posing then
		camera.setFocalPreferredOffset(camsave.offset3rd)
		if not zoom1st.zoomOut then	dCam.restoreCamera()		end
		--[[
		if camera.getMode() ~= camsave.mode then
	-- directly switching 1stPerson-->Preview using setMode will glitch
			if camsave.mode == MD.Preview then camsave.mode = MD.ThirdPerson
			elseif camsave.mode == MD.ThirdPerson and camera.getMode() == MD.Preview then
				camera.setPreferredThirdPersonDistance(camsave.dist3rd)
				camera.setYaw(camsave.yaw)
				camera.setPitch(camsave.pitch)
				camera.instantTransition()
			end
			camera.setMode(camsave.mode)
		end
		--]]
	end
end

--	Precaution if game was saved during dialogue
I.UI.setHudVisibility(true)

local function stopPosing()
	animHandler("cancel", anims.poses[currentanim].id)
	camera.setFocalPreferredOffset(camsave.offset3rd)
	if camsave.mode == MD.FirstPerson then
		async:newUnsavableSimulationTimer(0.1, function() camera.setMode(MD.FirstPerson) end)
	else
		camera.setMode(camsave.mode)
	end
	I.Controls.overrideMovementControls(false)
	posing = false
	idlenum = 0
	ui.showMessage(l10n("msg_moveon"))
end


time.runRepeatedly(function()
	if dialogTarget then
		dialogCam.counter = dialogCam.counter + 2
		if dialogCam.counter >= dialogCam.interval then
			if dialogCam.adjust then dialogCam.pos = dialogTarget.position		end
			local keys = dialogCam.animKeys
			if keys then
				local isPlaying
				for _, v in ipairs(keys) do 
					if anim.isPlaying(dialogTarget, v) then
						isPlaying = true
						if logging then print(v)		end
					end
				end
				if isPlaying then
					dialogCam.head = dialogCam.headPosAnim
				else
					dialogCam.head = dialogCam.headPosIdle
				end
			end
			dialogCam.counter = 0
		end
	end
	if posing and not animHandler("isplay", anims.poses[currentanim].id) then stopPosing() end
	if moved then moved = false		return		end
	if camera.getMode() == MD.FirstPerson or Actor.activeEffects(self):getEffect("levitate").magnitude > 0
		or Actor.isSwimming(self) then
		counter = 0		return
	end
	if posing or not types.Player.getControlSwitch(self, types.Player.CONTROL_SWITCH.Controls) then
		counter = 0		return
	end
	if idlenum == 0 then
		idlenum = 1
		counter = 26
	end
	counter = counter + 2
	local legs = anims.idle.base[anims.settings[settings.player:get("baseIdleAnim_main")]]
	local top = anims.idle.base[anims.settings[settings.player:get("baseIdleAnim_upper")]]
	if counter == 6 and top.id ~= legs.id and animHandler("isplay", top.id) then
		animHandler("cancel", top.id)
	end
	if counter < 32 then
		if counter > 5 and counter < 28 then
			if not animHandler("isplay", legs.id) then
				animHandler("play", legs.id, {loops=50, priority=1, speed=legs.speed})
			end
			if not animHandler("isplay", top.id) and top.id ~= legs.id then
				animHandler("play", top.id, {loops=50, priority=2, blendMask=(top.mask or 12), speed=top.speed})
			end
		end
		return
	end
	counter = 0
	if not settings.player:get("rndIdleAnim") then return end
	for i=1, #anims.clear do anim.cancel(self, anims.clear[i]) end
	local rnd = anims.idle.rnd[math.random(2)]
	for i=1, idlenum do
		local a, options = rnd[i].id, {}
		for k, v in pairs(rnd[i].opt) do options[k] = v end
		options.priority = i + 2
		animHandler("play", a, options)
	end
	if idlenum == 1 then idlenum = 2 end
end, 2 * time.second)


local function startPosing()
	ui.showMessage(l10n("msg_moveoff"))
	posing = true			doUpdates = true
	for _, v in ipairs(anims.clear) do anim.cancel(self, v) end
	local offset = anims.poses[currentanim].offset
	local speed = anims.poses[currentanim].speed or 1
	if offset then
		poseOpt.offset3rd = util.vector2(camsave.offset3rd.x, offset)
		camera.setFocalPreferredOffset(poseOpt.offset3rd)
	else poseOpt.offset3rd = camsave.offset3rd end
	local options = {loops=200, priority=5, speed=speed}
	if anims.poses[currentanim].force then options.forceLoop = true end
	animHandler("play", anims.poses[currentanim].id, options)
end

local function onKeyPress(key)
	if (key.code ~= actionKey) then return end
	if core.isWorldPaused() or moved then return end
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
	if posing then stopPosing() return end
	if Actor.activeEffects(self):getEffect("levitate").magnitude > 0
		or Actor.isSwimming(self) then return end
	if Actor.getStance(self) ~= ST.Nothing then return end
	camsave.mode, camsave.offset3rd = camera.getMode(), camera.getFocalPreferredOffset()
	I.Controls.overrideMovementControls(true)
	currentanim, poseOpt.choose = poseOpt.save, false
	for _, v in ipairs(anims.clear) do anim.cancel(self, v) end
	local offset = anims.poses[currentanim].offset
	local speed = anims.poses[currentanim].speed or 1
	if anims.poses[currentanim].turn then
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
	if not settings.player:get("autoHelm") then return end
	local equip, head = Actor.getEquipment(self), Actor.EQUIPMENT_SLOT.Helmet
	local h = equip[head]
	if inCombat and helm.combat then
		equip[head] = helm.combat
		Actor.setEquipment(self, equip)
		return
	end
	local store1, store2 = settings.player:get("autoHelmItemID"), settings.player:get("autoHelmItemID2")
	local id = h and h.recordId
	if Actor.getStance(self) == ST.Nothing then
		helm.combat = h
		if id and store1 ~= id then
			settings.player:set("autoHelmItemID", id)
		end
		equip[head] = helm.idle
	elseif stance == ST.Nothing then
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
		if not dialogTarget then	dCam.processControls(dt)	end
	end
	if dialogCam.isActive and dialogTarget then
		if camera.getMode() == MD.FirstPerson then
			dCam.autoCam(dt)			active = true
		elseif camera.getMode() == MD.Preview and dialogCam.controls then
			dCam.processControls(dt, dialogTarget)			active = true
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
	if dt == 0 then return		end
	if stance ~= Actor.getStance(self) then procStanceChange() end
--	if dialogTarget or posing then processCamera(dt) end
	if doUpdates then processCamera(dt)		end
	if moved then moved = false	return		end
	local ctrls = self.controls
	if ctrls.movement ~= 0 or ctrls.sideMovement ~= 0 then moved=true end
	if ctrls.yawChange ~= 0 and posing then moved=true end
	if ctrls.jump or ctrls.sneak then moved=true end
	if Actor.getStance(self) ~= ST.Nothing then moved=true end
	if not moved then return end
	if idlenum > 0 then
		for _, v in ipairs(anims.clear) do anim.cancel(self, v) end
		idlenum = 0
	end
	if posing then stopPosing() end
end


local function uiModeChanged(data)
	if dialogModes[data.newMode] and not dialogModes[data.oldMode] and data.arg and dialogTarget ~= data.arg then
		data.player = self		data.near = self.cell == data.arg.cell
		if data.arg ~= self and types.Actor.objectIsInstance(data.arg) then
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


local function updateActorCombat(e)
		if next(e.targets) == nil or not dialogTarget then return	end
		for _, target in ipairs(e.targets) do
			if target == self then
				core.sendGlobalEvent("dynForcePause") break	end
		end
end


return {
	engineHandlers = { onUpdate = onUpdate, onKeyPress = onKeyPress },
	eventHandlers = {
	UiModeChanged = uiModeChanged,
	tes3InfoGetText = function(e) if dialogTarget then dialogTarget:sendEvent("dynInfoEvent", e) end end,
	dynUiMessage = function(e) ui.showMessage(l10n(e)) end,
	OMWMusicCombatTargetsChanged = function(e)
		if next(e.targets) == nil or not e.actor then return	end
		local inCombat
		for _, target in ipairs(e.targets) do
			if target == self.object then inCombat = true	break	end
		end
		if not inCombat then return	end
		if dialogTarget then core.sendGlobalEvent("dynForcePause")	end
		local pos1, pos2 = e.actor.position, self.object.position
		if (pos1 - pos2):length() > 2000 then return end
		if math.abs(pos1.z - pos2.z) > 1000 then return end
		procStanceChange(true)
	end
	},
--[[
	interfaceName = "dynamicActors",
	interface = {
		version = 115,
		dcam = function() return dialogCam	end
	}

--]]
}
