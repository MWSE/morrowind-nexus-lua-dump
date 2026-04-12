-- visibleitems_npc.lua
-- NPC local script: shows equipped rings, amulets, and belts as visible 3D items.
--
-- KEY DIFFERENCES FROM PLAYER VERSION:
--   - onFrame is player-only; NPC scripts use onUpdate for per-frame logic.
--   - openmw.interfaces (I.luaHelper, I.UI) are player-only; removed entirely.
--   - openmw.camera / openmw.input / openmw.ui are player-only; removed entirely.
--   - Actor.getEquipment() returns ONE value (the table); the second return
--     value the player script used does not exist for NPC scripts.
--   - Always uses the "third" person offset since NPCs have no camera mode.
--   - onActive is used to re-attach VFX after cell transitions.
--
-- OMWSCRIPTS ENTRY:
--   NPC: scripts/yourmod/visibleitems_npc.lua

local self  = require("openmw.self")
local types = require("openmw.types")
local anim  = require("openmw.animation")
local vfs   = require("openmw.vfs")

local Actor = types.Actor

local VIEW = "third"   -- NPCs are always third-person

-- ---------------------------------------------------------------------------
-- Offset / bone-position tables
-- ---------------------------------------------------------------------------

local L = {
   slim   = { third="45" },
   glove  = { third="50" },
   mid55  = { third="55" },
   mid60  = { third="60" },
   wide   = { third="60" },
   wide70 = { third="70" },
}

local offset = {
   bareHands = { third="VS" },

   ["bm bear left gauntlet"]      = L.mid55,
   ["bm bear right gauntlet"]     = L.mid55,
   bm_ice_gauntletl               = L.slim,
   bm_ice_gauntletr               = L.slim,
   bm_nordicmail_gauntletl        = L.slim,
   bm_nordicmail_gauntletr        = L.slim,
   ["bm wolf left gauntlet"]      = L.mid60,
   ["bm wolf right gauntlet"]     = L.mid60,

   ["chitin guantlet - left"]     = L.glove,
   ["chitin guantlet - right"]    = L.glove,
   ["bonedancer gauntlet"]        = L.glove,
   ["boneweave gauntlet"]         = L.glove,
   ["left gauntlet of the horny fist"]  = L.glove,
   ["right gauntlet of the horny fist"] = L.glove,

   ["darkBrotherhood gauntlet_l"] = L.mid55,
   ["darkBrotherhood gauntlet_r"] = L.mid55,

   fur_gauntlet_left              = L.wide70,
   fur_gauntlet_right             = L.wide70,
   gauntlet_of_glory_left         = L.wide70,
   gauntlet_of_glory_right        = L.wide70,

   Helsethguard_gauntlet_left     = L.mid55,
   Helsethguard_gauntlet_right    = L.mid55,
   ["imperial left gauntlet"]     = L.glove,
   ["imperial right gauntlet"]    = L.glove,
   iron_gauntlet_left             = L.mid55,
   iron_gauntlet_right            = L.mid55,
   ["indoril left gauntlet"]      = L.mid55,
   ["indoril right gauntlet"]     = L.mid55,
   indoril_mh_guard_gauntlet_l    = L.mid55,
   indoril_mh_guard_gauntlet_r    = L.mid55,
   indoril_almalexia_gauntlet_l   = L.mid55,
   indoril_almalexia_gauntlet_r   = L.mid55,

   netch_leather_gauntlet_left    = L.glove,
   netch_leather_gauntlet_right   = L.glove,
   gauntlet_horny_fist_l          = L.glove,
   gauntlet_horny_fist_r          = L.glove,

   steel_gauntlet_left            = L.wide,
   steel_gauntlet_right           = L.wide,
}

for k, v in pairs(L) do offset[k] = v end

local fallback = {
   { "brace",      offset.bareHands },
   { "chitin",     offset.glove     },
   { "netch",      offset.glove     },
   { "daedric",    offset.glove     },
   { "guardtown1", offset.mid55     },
   { "iron",       offset.mid55     },
   { "steel",      offset.wide      },
   { "glove",      offset.glove     },
}

local vfxItem   = { loop=true, useAmbientLight=false, vfxId="visibleItems" }
local itemModels = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function getGloveOffset(o)
   if not o then return offset.bareHands end
   local cached = offset[o.recordId]
   if cached then return cached end
   if o.type == types.Armor then
   	for _, v in ipairs(fallback) do
   		local pattern, sizes = table.unpack(v)
   		if o.recordId:find(pattern) then
   			offset[o.recordId] = sizes
   			return sizes
   		end
   	end
   end
   offset[o.recordId] = offset.glove
   return offset.glove
end

local function getModel(o)
   local id = o.recordId
   if itemModels[id] ~= nil then return itemModels[id] end
   local model = o.type.records[id].model:lower()
   model = model:gsub("_gnd%.nif$", ".nif")
   model = model:gsub("%.nif$",     "_skins.nif")
   if not vfs.fileExists(model) then model = "" end
   itemModels[id] = model
   return model
end

-- ---------------------------------------------------------------------------
-- VFX attachment
-- ---------------------------------------------------------------------------

local function addRingVfx(itemObj, bone, gauntletObj)
   local model = getModel(itemObj)
   if model == "" then return end
   local sizes = getGloveOffset(gauntletObj)
   vfxItem.boneName = bone .. " " .. sizes[VIEW]
   anim.addVfx(self, model, vfxItem)
end

-- ---------------------------------------------------------------------------
-- Equipment scanning
-- ---------------------------------------------------------------------------

local SLOT      = Actor.EQUIPMENT_SLOT
local scanSlots = {
   SLOT.LeftRing, SLOT.RightRing,
   SLOT.LeftGauntlet, SLOT.RightGauntlet,
   SLOT.Amulet, SLOT.Belt,
}

local equipped = {}
local needScan = true

local function scanInv(force)
   needScan  = false
   local eq  = Actor.getEquipment(self)   -- ONE return value on NPC scripts
   local changed = force
   for _, slot in ipairs(scanSlots) do
   	if equipped[slot] ~= eq[slot] then
   		changed        = true
   		equipped[slot] = eq[slot]
   	end
   end
   if not changed then return end

   anim.removeVfx(self, "visibleItems")

   local lRing  = eq[SLOT.LeftRing]
   local rRing  = eq[SLOT.RightRing]
   local lGaunt = eq[SLOT.LeftGauntlet]
   local rGaunt = eq[SLOT.RightGauntlet]
   local amulet = eq[SLOT.Amulet]
   local belt   = eq[SLOT.Belt]

   if lRing then addRingVfx(lRing, "Ring L Finger1", lGaunt) end
   if rRing then addRingVfx(rRing, "Ring R Finger1", rGaunt) end

   if amulet then
   	local m = getModel(amulet)
   	if m ~= "" then vfxItem.boneName = "Necklace"; anim.addVfx(self, m, vfxItem) end
   end
   if belt then
   	local m = getModel(belt)
   	if m ~= "" then vfxItem.boneName = "waist"; anim.addVfx(self, m, vfxItem) end
   end
end

-- ---------------------------------------------------------------------------
-- Engine handlers  (onFrame is player-only — use onUpdate for NPCs)
-- ---------------------------------------------------------------------------

local FRAME_SKIP = 20
local counter    = math.random(3, FRAME_SKIP)

local function onActive()
   -- Called when the NPC's cell is loaded / actor becomes active again.
   -- Forces a full VFX re-attachment after cell transitions.
   needScan = true
   counter  = 1  -- scan on the very next onUpdate tick
end

local function onUpdate(dt)
   if dt == 0 then return end
   if needScan then scanInv(true); counter = FRAME_SKIP; return end
   counter = counter - 1
   if counter <= 0 then counter = FRAME_SKIP; scanInv(false) end
end

return {
   engineHandlers = {
   	onUpdate = onUpdate,
   	onActive = onActive,
   },
   eventHandlers  = {
   	vfxRemoveAll = function() counter = 1; needScan = true end,
   	equipped     = function() needScan = true end,
   	unequipped   = function() needScan = true end,
   },
}