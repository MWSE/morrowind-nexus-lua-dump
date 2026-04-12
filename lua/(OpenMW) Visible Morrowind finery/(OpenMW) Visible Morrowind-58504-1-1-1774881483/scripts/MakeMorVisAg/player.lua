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
   { "dragonbone",         "heavy" },   -- artifact Dragonbone Mail (dragonbone_cuirass_unique)
   { "lords_mail",         "heavy" },   -- artifact Lord's Mail
   { "lord's mail",        "heavy" },
   { "lords mail",         "heavy" },
   { "herhand",            "heavy" },   -- Tribunal: Her Hands
   { "her_hand",           "heavy" },
   { "her hands",          "heavy" },
   { "nordic_mail",        "heavy" },   -- Bloodmoon: Nordic Mail (bm_nordicmail_cuirass)
   { "nordicmail",         "heavy" },
   { "nordic mail",        "heavy" },
   { "bm_nordic",          "heavy" },
   { "nordic_iron",        "heavy" },   -- Nordic Iron Cuirass (nordic_iron_cuirass)
   { "nordic iron",        "heavy" },
   { "trollbone",          "heavy" },   -- Nordic Trollbone Cuirass (trollbone_cuirass)
   { "daedric",            "heavy" },
   { "dwemer",             "heavy" },
   { "ebony_c",            "heavy" },   -- base Ebony cuirass; must stay BEFORE ebony_mail
   { "imperial_templar",   "heavy" },   -- Imperial Templar (imperial_templar_cuirass)
   { "imperial templar",   "heavy" },
   { "imperial_steel",     "heavy" },   -- Imperial Steel
   { "imperial steel",     "heavy" },
   { "imperial_dragon",    "heavy" },   -- safety catch for mod IDs with imperial_dragon prefix
   { "imperial dragon",    "heavy" },
   { "iron_cuirass",       "heavy" },
   { "iron cuirass",       "heavy" },
   { "steel_cuirass",      "heavy" },
   { "steel cuirass",      "heavy" },
   { "steel_",             "heavy" },
   { "templar",            "heavy" },
   { "silver_cuirass",     "heavy" },   -- Imperial Silver (silver_cuirass)
   { "silver cuirass",     "heavy" },
   { "duke_guard",         "heavy" },   -- Duke's Guard Silver (duke_guard_silver_cuirass)
   { "duke guard",         "heavy" },

   -- ── MEDIUM ──────────────────────────────────────────────
   { "ebony_mail",         "medium" },  -- artifact Ebony Mail; must stay BEFORE ebony_c
   { "indoril",            "medium" },
   { "mh_guard",           "medium" },  -- Tribunal: Almalexia's Guard
   { "almalexia",          "medium" },
   { "orcish",             "medium" },
   { "bonemold",           "medium" },
   { "armun",              "medium" },  -- Armun-An Bonemold
   { "gah_julan",          "medium" },  -- Gah-Julan Bonemold
   { "gah julan",          "medium" },
   { "imperial_chain",     "medium" },  -- Imperial Chain (imperial_chain_cuirass)
   { "imperial chain",     "medium" },
   { "dragonscale",        "medium" },  -- Imperial Dragonscale (dragonscale_cuirass)
   { "nordic_ringmail",    "medium" },  -- Nordic Ringmail (nordic_ringmail_cuirass)
   { "nordic ringmail",    "medium" },
   { "ringmail",           "medium" },
   { "royal_guard",        "medium" },  -- Tribunal: Royal Guard
   { "royalguard",         "medium" },
   { "helsethguard",       "medium" },
   { "helseth_guard",      "medium" },
   { "helseth guard",      "medium" },
   { "adamantium",         "medium" },  -- Tribunal: Adamantium
   { "dreugh",             "medium" },  -- Dreugh (dreugh_cuirass)
   { "gold_cuirass",       "medium" },  -- LeFemm: Gold Armor
   { "gold cuirass",       "medium" },
   { "bm_bear",            "medium" },  -- Bloodmoon: Snow Bear (bm_bear_cuirass)
   { "bm snow bear",       "medium" },
   { "bear cuirass",       "medium" },
   { "bm_wolf",            "medium" },  -- Bloodmoon: Snow Wolf (bm_wolf_cuirass)
   { "bm snow wolf",       "medium" },
   { "wolf cuirass",       "medium" },
   { "stalhrim",           "medium" },  -- Bloodmoon: Stalhrim
   { "bm_ice",             "medium" },  -- Bloodmoon: Ice Armor (bm_ice_cuirass)
   { "bm ice",             "medium" },
   { "ice cuirass",        "medium" },

   -- ── LIGHT ───────────────────────────────────────────────
   { "glass",              "light"  },  -- Glass (glass_cuirass)
   { "chitin",             "light"  },  -- Chitin (chitin_cuirass)
   { "boiled_netch",       "light"  },  -- Boiled Netch Leather (boiled_netch_leather_cuirass)
   { "boiled netch",       "light"  },
   { "netch_leather",      "light"  },  -- Netch Leather (netch_leather_cuirass)
   { "netch",              "light"  },
   { "fur_bearskin",       "light"  },  -- Nordic Bearskin (fur_bearskin_cuirass) — light, NOT Bloodmoon Snow Bear
   { "fur_cuirass",        "light"  },  -- Nordic Fur (fur_cuirass)
   { "fur cuirass",        "light"  },
   { "fur_",               "light"  },  -- catch remaining fur_ prefixed IDs
   { "newtscale",          "light"  },  -- Imperial Newtscale (newtscale_cuirass)
   { "imperial_studded",   "light"  },  -- Imperial Studded Leather (imperial_studded_cuirass)
   { "imperial studded",   "light"  },
   { "leather_cuirass",    "light"  },
   { "leather cuirass",    "light"  },
   { "db_cuirass",         "light"  },  -- Tribunal: Dark Brotherhood (db_cuirass)
   { "dark_brotherhood",   "light"  },
   { "dark brotherhood",   "light"  },
   { "savior",             "light"  },  -- artifact Cuirass of the Savior's Hide
   { "saviours",           "light"  },
   { "cultist",            "light"  },  -- Tribunal: Cultist
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

local settings = storage.playerSection("Settings_tt_visiblerings")
local frameSkip, onlyHands
local counter, refresh

local function updateSettings()
   frameSkip = settings:get("frameSkip") or 20
   onlyHands = settings:get("bareHandsOnly")
   local model = settings:get("defaultModel")
   if type(model) == "string" and vfs.fileExists(model) then
       L.defaultModel = model
   else
       L.defaultModel = nil
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
local showCuirass = false
local cuirassKeyWasDown = false

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
       if model == "" then model = L.defaultModel end
       if model then
           L.vfxItem.boneName = "Necklace " .. amuletSize[view]
           anim.addVfx(self, model, L.vfxItem)
       end
   end

   -- Belt
   if eq[b] then
       local model = items[eq[b].recordId] or L.getItem(eq[b])
       if model == "" then model = L.defaultModel end
       if model then
           L.vfxItem.boneName = "waist " .. beltSize[view]
           anim.addVfx(self, model, L.vfxItem)
       end
   end

   -- Cuirass (toggled by Z)
   if showCuirass and eq[c] then
       local model = items[eq[c].recordId] or L.getItem(eq[c])
       if model == "" then model = L.defaultModel end
       if model then
           L.vfxItem.boneName = "MEH"
           anim.addVfx(self, model, L.vfxItem)
       end
   end
end

local useHelper = false

local function onFrame(dt)
   local keyDown = input.isKeyPressed(input.KEY.Z)
   if keyDown and not cuirassKeyWasDown then
       showCuirass = not showCuirass
       counter = 1
       refresh = true
       if devMode then
           print("Cuirass VFX toggled: " .. tostring(showCuirass))
           ui.showMessage("Cuirass VFX: " .. (showCuirass and "ON" or "OFF"))
       end
   end
   cuirassKeyWasDown = keyDown

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
           useHelper = true
           I.luaHelper.eventRegister("equipped", function() newEquip = true end)
           I.luaHelper.eventRegister("unequipped", function() newEquip = true end)
       end,
       vfxRemoveAll = function() counter = 3    refresh = true end
   },
}