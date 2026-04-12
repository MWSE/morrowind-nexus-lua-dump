local self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local anim = require("openmw.animation")
local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")
local camera = require("openmw.camera")
local vfs = require("openmw.vfs")
local storage = require("openmw.storage")
local input = require("openmw.input")

local Actor, ctrls, ST = types.Actor, self.controls, types.Actor.STANCE
local MD = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }

local cam = camera.getMode()
local devMode = false

local equipped = {}
local items = { default = "meshes/c/c_ring_common05_skins.nif" }
local items = { default = "meshes/c/C_belt_Common_5_skins.nif" }

local L = {
   bbody = { first="BB", third="BB" },
   rbody = { first="RB", third="RB" },
   vbody = { first="VB", third="VS" },
   vsbr  = { first="VS", third="VS" },
   slim  = { first="50", third="45" },
   glove = { first="50", third="50" },
   mid55 = { first="60", third="55" },
   mid60 = { first="60", third="60" },
   wide  = { first="70", third="60" },
   wide70= { first="70", third="70" },
}

local offset = {
   bareHands = { first="50", third="50" },
   ["bm bear left gauntlet"]  = L.mid55,
   ["bm bear right gauntlet"] = L.mid55,
   bm_ice_gauntletl           = L.slim,
   bm_ice_gauntletr           = L.slim,
   bm_nordicmail_gauntletl    = L.slim,
   bm_nordicmail_gauntletr    = L.slim,
   ["bm wolf left gauntlet"]  = L.mid60,
   ["bm wolf right gauntlet"] = L.mid60,
   ["chitin guantlet - left"] = L.glove,
   ["chitin guantlet - right"]= L.glove,
   ["bonedancer gauntlet"]        = L.glove,
   ["boneweave gauntlet"]         = L.glove,
   ["left gauntlet of the horny fist"]  = L.glove,
   ["right gauntlet of the horny fist"] = L.glove,
   ["darkBrotherhood gauntlet_l"] = L.mid55,
   ["darkBrotherhood gauntlet_r"] = L.mid55,
   fur_gauntlet_left  = L.wide70,
   fur_gauntlet_right = L.wide70,
   gauntlet_of_glory_left  = L.wide70,
   gauntlet_of_glory_right = L.wide70,
   Helsethguard_gauntlet_left  = L.mid55,
   Helsethguard_gauntlet_right = L.mid55,
   ["imperial left gauntlet"]  = L.glove,
   ["imperial right gauntlet"] = L.glove,
   iron_gauntlet_left  = L.mid55,
   iron_gauntlet_right = L.mid55,
   ["indoril left gauntlet"]   = L.mid55,
   ["indoril right gauntlet"]  = L.mid55,
   indoril_mh_guard_gauntlet_l = L.mid55,
   indoril_mh_guard_gauntlet_r = L.mid55,
   indoril_almalexia_gauntlet_l= L.mid55,
   indoril_almalexia_gauntlet_r= L.mid55,
   netch_leather_gauntlet_left  = L.glove,
   netch_leather_gauntlet_right = L.glove,
   gauntlet_horny_fist_l = L.glove,
   gauntlet_horny_fist_r = L.glove,
   steel_gauntlet_left  = L.wide,
   steel_gauntlet_right = L.wide,
}

for k, v in pairs(L) do offset[k] = v end

-- ============================================================
-- Amulet / Belt size offsets — five tiers
-- ============================================================
local amuletOffset = {
   naked   = { first="46", third="46" },
   clothes = { first="48", third="48" },
   light   = { first="50", third="50" },
   medium  = { first="55", third="53" },
   heavy   = { first="62", third="58" },
}

local beltOffset = {
   naked   = { first="46", third="46" },
   clothes = { first="48", third="48" },
   light   = { first="50", third="50" },
   medium  = { first="55", third="53" },
   heavy   = { first="62", third="58" },
}

local cuirassKeywords = {
   -- ── HEAVY ───────────────────────────────────────────────
   { "dragonbone",         "heavy" },
   { "lords_mail",         "heavy" },
   { "lord's mail",        "heavy" },
   { "lords mail",         "heavy" },
   { "herhand",            "heavy" },
   { "her_hand",           "heavy" },
   { "her hands",          "heavy" },
   { "nordic_mail",        "heavy" },
   { "nordicmail",         "heavy" },
   { "nordic mail",        "heavy" },
   { "bm_nordic",          "heavy" },
   { "nordic_iron",        "heavy" },
   { "nordic iron",        "heavy" },
   { "trollbone",          "heavy" },
   { "daedric",            "heavy" },
   { "dwemer",             "heavy" },
   { "ebony_c",            "heavy" },
   { "imperial_templar",   "heavy" },
   { "imperial templar",   "heavy" },
   { "imperial_steel",     "heavy" },
   { "imperial steel",     "heavy" },
   { "imperial_dragon",    "heavy" },
   { "imperial dragon",    "heavy" },
   { "iron_cuirass",       "heavy" },
   { "iron cuirass",       "heavy" },
   { "steel_cuirass",      "heavy" },
   { "steel cuirass",      "heavy" },
   { "steel_",             "heavy" },
   { "templar",            "heavy" },
   { "silver_cuirass",     "heavy" },
   { "silver cuirass",     "heavy" },
   { "duke_guard",         "heavy" },
   { "duke guard",         "heavy" },

   -- ── MEDIUM ──────────────────────────────────────────────
   { "ebony_mail",         "medium" },
   { "indoril",            "medium" },
   { "mh_guard",           "medium" },
   { "almalexia",          "medium" },
   { "orcish",             "medium" },
   { "bonemold",           "medium" },
   { "armun",              "medium" },
   { "gah_julan",          "medium" },
   { "gah julan",          "medium" },
   { "imperial_chain",     "medium" },
   { "imperial chain",     "medium" },
   { "dragonscale",        "medium" },
   { "nordic_ringmail",    "medium" },
   { "nordic ringmail",    "medium" },
   { "ringmail",           "medium" },
   { "royal_guard",        "medium" },
   { "royalguard",         "medium" },
   { "helsethguard",       "medium" },
   { "helseth_guard",      "medium" },
   { "helseth guard",      "medium" },
   { "adamantium",         "medium" },
   { "dreugh",             "medium" },
   { "gold_cuirass",       "medium" },
   { "gold cuirass",       "medium" },
   { "bm_bear",            "medium" },
   { "bm snow bear",       "medium" },
   { "bear cuirass",       "medium" },
   { "bm_wolf",            "medium" },
   { "bm snow wolf",       "medium" },
   { "wolf cuirass",       "medium" },
   { "stalhrim",           "medium" },
   { "bm_ice",             "medium" },
   { "bm ice",             "medium" },
   { "ice cuirass",        "medium" },

   -- ── LIGHT ───────────────────────────────────────────────
   { "glass",              "light"  },
   { "chitin",             "light"  },
   { "boiled_netch",       "light"  },
   { "boiled netch",       "light"  },
   { "netch_leather",      "light"  },
   { "netch",              "light"  },
   { "fur_bearskin",       "light"  },
   { "fur_cuirass",        "light"  },
   { "fur cuirass",        "light"  },
   { "fur_",               "light"  },
   { "newtscale",          "light"  },
   { "imperial_studded",   "light"  },
   { "imperial studded",   "light"  },
   { "leather_cuirass",    "light"  },
   { "leather cuirass",    "light"  },
   { "db_cuirass",         "light"  },
   { "dark_brotherhood",   "light"  },
   { "dark brotherhood",   "light"  },
   { "savior",             "light"  },
   { "saviours",           "light"  },
   { "cultist",            "light"  },
   { "telvanni",           "light"  },
   { "smuggler",           "light"  },
}

local clothesKeywords = {
   "shirt", "robe", "tunic", "dress", "vest", "common_",
   "expensive_", "extravagant_", "exquisite_", "colovian",
   "expensive robe", "common robe", "worn", "velvet",
}

local function getCuirassSize(cuirassObj, shirtObj)
   if cuirassObj then
       local id = cuirassObj.recordId:lower()
       for _, entry in ipairs(cuirassKeywords) do
           if id:find(entry[1], 1, true) then
               return amuletOffset[entry[2]], beltOffset[entry[2]]
           end
       end
       local ok, rec = pcall(function() return types.Armor.records[cuirassObj.recordId] end)
       if ok and rec then
           local t = rec.type
           if t == types.Armor.TYPE.HeavyCuirass  then return amuletOffset.heavy,  beltOffset.heavy  end
           if t == types.Armor.TYPE.MediumCuirass then return amuletOffset.medium, beltOffset.medium end
           if t == types.Armor.TYPE.LightCuirass  then return amuletOffset.light,  beltOffset.light  end
       end
       return amuletOffset.medium, beltOffset.medium
   end

   if shirtObj then
       local id = shirtObj.recordId:lower()
       for _, kw in ipairs(clothesKeywords) do
           if id:find(kw, 1, true) then
               return amuletOffset.clothes, beltOffset.clothes
           end
       end
       return amuletOffset.clothes, beltOffset.clothes
   end

   return amuletOffset.naked, beltOffset.naked
end

-- ─────────────────────────────────────────────────────────────────────────────

L = {
   fallback = {
       { "brace",      offset.bareHands },
       { "chitin",     offset.glove     },
       { "netch",      offset.glove     },
       { "daedric",    offset.glove     },
       { "guardtown1", offset.mid55     },
       { "iron",       offset.mid55     },
       { "steel",      offset.wide      },
       { "glove",      offset.glove     },
       { "helsethguard", offset.mid55   },
       { "bear",       offset.mid55     },
       { "wolf",       offset.mid60     },
       { "_ice_",      offset.slim      },
       { "nordicmail", offset.slim      },
       { "imperial",   offset.glove     },
       { "indoril",    offset.mid55     },
   },
   uiModes = { [I.UI.MODE.Rest] = true, [I.UI.MODE.Training] = true, [I.UI.MODE.Travel] = true },
   vfxItem = { loop=true, useAmbientLight=false, vfxId="visibleItems" },
}

L.getGlove = function(o)
   local sizes
   if o.type ~= types.Armor then
       if devMode then print("NOT ARMOR") end
       sizes = offset.glove
       offset[o.recordId] = sizes
       return sizes
   end
   for _, v in ipairs(L.fallback) do
       local i, j = table.unpack(v)
       if o.recordId:find(i) then sizes = j    break end
   end
   if not sizes then sizes = offset.glove end
   offset[o.recordId] = sizes
   return sizes
end

L.getItem = function(o)
   local id = o.recordId
   local model = o.type.records[id].model:lower()
   model = model:gsub("_gnd%.nif$", ".nif")
   model = model:gsub("%.nif$", "_skins.nif")
   if not vfs.fileExists(model) then
       if devMode then print("No visible model for "..model) end
       model = ""
   end
   items[id] = model
   return model
end

local function debug(m)
   if devMode then
       print(m)
       ui.showMessage(m)
   end
end

local settings = storage.playerSection("Settings_tt_visiblefinery")
local frameSkip, onlyHands
local counter, refresh

local function updateSettings()
   frameSkip = settings:get("frameSkip") or 20
   onlyHands = settings:get("bareHandsOnly")
   NoRings = settings:get("ShowRings")
   NoBelts = settings:get("ShowBelts")
   NoAmulets = settings:get("ShowAmulets")
   local model = settings:get("defaultModel")
   local Bmodel = settings:get("defaultBelt")
   local Amodel = settings:get("defaultAmulet")
   if type(model) == "string" and vfs.fileExists(model) then
       L.defaultModel = model
   else
       L.defaultModel = nil
   end
   if type(Bmodel) == "string" and vfs.fileExists(Bmodel) then
       L.defaultModelB = Bmodel
   else
       L.defaultModelB = nil
   end
   if type(Amodel) == "string" and vfs.fileExists(Amodel) then
       L.defaultModelA = Amodel
   else
       L.defaultModelA = nil
   end
   local b, rec = types.NPC.records[self.recordId].isMale and settings:get("bodyReplacer")
       or settings:get("bodyReplacer_f")
   if b == "opt_better" then
       rec = offset.bbody
   elseif b == "opt_robert" then
       rec = offset.rbody
   elseif b == "opt_vsbr" then
       rec = offset.vsbr
   else
       rec = offset.vbody
   end
   offset.bareHands.first = rec.first
   offset.bareHands.third = rec.third
   counter = math.random(3, 20)
   refresh = true
end

settings:subscribe(async:callback(updateSettings))
updateSettings()

local function addRingVfx(o, bone, hand)
   local model = items[o.recordId] or L.getItem(o)
   if model == "" then
       if devMode then print(model, "USE DEFAULT") end
       model = L.defaultModel
       if not model then return end
   end
   local id = hand and hand.recordId or "bareHands"
   local sizes = offset[id] or L.getGlove(hand)
   if NoRings then return end
   if onlyHands and sizes ~= offset.bareHands then return end
   local view = (cam == MD.first and "first") or "third"
   if devMode then print(sizes[view], id) end
   debug(model.." add ring vfx")
   L.vfxItem.boneName = bone .. " " .. sizes[view]
   anim.addVfx(self, model, L.vfxItem)
end

local scanSlots = {
   Actor.EQUIPMENT_SLOT.LeftRing,
   Actor.EQUIPMENT_SLOT.RightRing,
   Actor.EQUIPMENT_SLOT.LeftGauntlet,
   Actor.EQUIPMENT_SLOT.RightGauntlet,
   Actor.EQUIPMENT_SLOT.Amulet,
   Actor.EQUIPMENT_SLOT.Belt,
   Actor.EQUIPMENT_SLOT.Cuirass,
   Actor.EQUIPMENT_SLOT.Shirt,
}

local newEquip = false

local function scanInv(reset)
   newEquip = false
   refresh = false
   local e, f = Actor.getEquipment(self)
   local eq = equipped
   for _, v in ipairs(scanSlots) do
       if eq[v] ~= e[v] then f = true    eq[v] = e[v] end
   end
   if not f and not reset then return end
   debug("remove items vfx")
   anim.removeVfx(self, "visibleItems")
   local l, r, lG, rG, a, b, c, s = table.unpack(scanSlots)

   -- Rings
   if eq[l] then addRingVfx(eq[l], "Ring L Finger1", eq[lG]) end
   if eq[r] then addRingVfx(eq[r], "Ring R Finger1", eq[rG]) end

   if cam == MD.first then return end

   local view = "third"
   local amuletSize, beltSize = getCuirassSize(eq[c], eq[s])

   -- Amulet
   if eq[a] then
      local model = items[eq[a].recordId] or L.getItem(eq[a])
      if not NoAmulets then
         if model == "" then model = L.defaultModelA end
         if model then
            L.vfxItem.boneName = "Necklace " .. amuletSize[view]
            anim.addVfx(self, model, L.vfxItem)
         end
      end
   end

   -- Belt
   if eq[b] then
      local model = items[eq[b].recordId] or L.getItem(eq[b])
      if not NoBelts then
         if model == "" then model = L.defaultModelB end
         if model then
            L.vfxItem.boneName = "waist " .. beltSize[view]
            anim.addVfx(self, model, L.vfxItem)
         end
      end
   end
end

local useHelper = false

local function onFrame(dt)
   if newEquip then scanInv(refresh) end
   counter = counter - 1
   if counter > 0 then return end
   counter = frameSkip
   if refresh or not useHelper then scanInv(refresh) end
end

local function onUpdate(dt)
   if dt == 0 then return end
   if cam == camera.getMode() then return end
   local mode, fp = camera.getMode(), MD.first
   if mode == fp or cam == fp then
       cam = mode    counter = 3    refresh = true
   end
   cam = mode
end

return {
   engineHandlers = { onUpdate = onUpdate, onFrame = onFrame },
   eventHandlers = {
       UiModeChanged = function(e)
           if L.uiModes[e.oldMode] then
               counter = 3
               refresh = true
           end
       end,
       olhInitialized = function()
           if frameSkip ~= 20 then return end
           if not useHelper then
               useHelper = true
               I.luaHelper.eventRegister("equipped",   function() newEquip = true end)
               I.luaHelper.eventRegister("unequipped", function() newEquip = true end)
           end
       end,
       vfxRemoveAll = function() counter = math.random(3, 8)    refresh = true end
   },
}