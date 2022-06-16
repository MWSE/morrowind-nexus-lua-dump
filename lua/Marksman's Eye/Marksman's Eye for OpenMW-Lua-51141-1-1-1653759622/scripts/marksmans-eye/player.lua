--[[
!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!! NOTE !!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!

This Lua was generated from Fennel.

Fennel resources:
https://fennel-lang.org/setup
https://fennel-lang.org/tutorial
https://fennel-lang.org/lua-primer
https://fennel-lang.org/reference

Original Fennel source:

(local camera (require :openmw.camera))
(local core (require :openmw.core))
(local self (require :openmw.self))
(local storage (require :openmw.storage))
(local types (require :openmw.types))
(local ui (require :openmw.ui))
(local util (require :openmw.util))

(local I (require :openmw.interfaces))

(local MOD_NAME :MarksmansEye)
(local item-refId :marksmans_eye_item)
(local playerSettings (storage.playerSection (.. :SettingsPlayer MOD_NAME)))

(local L (core.l10n MOD_NAME))

(local Player types.Player)
(local Weapon types.Weapon)

(local counter-min -3)
(local counter-max 2)
(local combat-offset (util.vector2 -30 -10))
(local aiming-offset (util.vector2 -15 0))

(var active false)
(var do-effect false)
(var counter counter-min)
(var use-aiming-offset false)

(local interface-version 1)
(local script-version 1)

(I.Settings.registerPage {:key MOD_NAME
                          :l10n MOD_NAME
                          :name "Marksman's Eye"
                          :description "Adds a zoom effect while aiming a bow or crossbow"})

(I.Settings.registerGroup {:key (.. :SettingsPlayer MOD_NAME)
                           :l10n MOD_NAME
                           :name "Zoom Settings"
                           :page MOD_NAME
                           :description "Set the max intensity of the zoom effect (limit 1.9)"
                           :permanentStorage false
                           :settings [{:key :maxZoom
                                       :name "Max Zoom"
                                       :default 0.9
                                       :max 1.9
                                       :min 0
                                       :renderer :number}]})

(fn apply-fov [magnitude]
  (camera.setFieldOfView (* (camera.getBaseFieldOfView) (- 1 (* 0.5 magnitude)))))

(fn player-stat-base [kind name]
  (. ((. (. Player.stats kind) name) self) :base))

(fn player-marksman-base []
  (player-stat-base :skills :marksman))

(fn player-speed-base []
  (player-stat-base :attributes :speed))

(fn effect-magnitude [c]
  ;; This magic number was selected after some play testing.
  ;; Maybe there's a "better" way to get here..
  (local magic-num 0.02685)
  (local marksman (player-marksman-base))
  (local max-mag (playerSettings:get :maxZoom))
  (local speed (player-speed-base))
  (local modify-mrk (* marksman magic-num))
  (local modify-spd (* speed (/ magic-num 2)))
  (local modify (/ (* modify-mrk modify-spd) 2))
  (math.min (* (/ (- (math.max 0.1 (math.exp (- (math.min 1 c) 1))) 0.1)
                  max-mag) modify) max-mag))

;; Eventually we can use some kind of event to know when the player picks up the item.
(fn have-item []
  (let [inv (Player.inventory self)]
    (let [has (> (inv:countOf item-refId) 0)]
      (if (and has (not active))
          (ui.showMessage (L :abilityActive))
          (when (and (not has) active)
            (ui.showMessage (L :abilityDeactive))))
      (set active has)))
  active)

(fn is-bow-prepared []
  (when (= (Player.stance self) Player.STANCE.Weapon)
    (when (or (= (camera.getMode) camera.MODE.FirstPerson)
              (= (camera.getMode) camera.MODE.ThirdPerson))
      (let [item (Player.equipment self Player.EQUIPMENT_SLOT.CarriedRight)]
        (let [weaponRecord (and (not= item nil)
                                (and (= item.type Weapon) (Weapon.record item)))]
          (when weaponRecord
            (or (= weaponRecord.type Weapon.TYPE.MarksmanBow)
                (= weaponRecord.type Weapon.TYPE.MarksmanCrossbow))))))))

(fn on-load [data]
  (set active data.active))

(fn on-save []
  {: active :version script-version})

(fn on-update [dt]
  (have-item)
  (when (and active (not= do-effect (is-bow-prepared)))
    (set do-effect (not do-effect))
    (if do-effect
        (do
          (I.Camera.disableThirdPersonOffsetControl)
          (camera.setFocalTransitionSpeed 5)
          (camera.setFocalPreferredOffset combat-offset))
        (I.Camera.enableThirdPersonOffsetControl)))
  (if (or (= self.controls.use 0) (not do-effect))
      (set counter (math.max counter-min (- counter (* dt 2.5))))
      (set counter (math.min counter-max (+ counter (* dt 2.5)))))
  (var effect (effect-magnitude counter))
  (apply-fov effect)
  (when (not= (camera.getMode) camera.MODE.ThirdPerson)
    (set effect 0))
  (when (and (not= use-aiming-offset (> effect 0.4)) do-effect)
    (set use-aiming-offset (> effect 0.4))
    (if use-aiming-offset
        (camera.setFocalPreferredOffset aiming-offset)
        (camera.setFocalPreferredOffset combat-offset))))

(fn Level []
  (local fully-drawn 2)
  (if active
      (let [mag (effect-magnitude fully-drawn)
            max-mag (playerSettings:get :maxZoom)]
        (let [lvl (/ mag max-mag)]
          (if (= lvl max-mag) :Maximum
              (if (>= lvl 0.75) :High (if (>= lvl 0.5) :Medium :Low)))))
      "Not active"))

{:engineHandlers {:onLoad on-load :onSave on-save :onUpdate on-update}
 :interfaceName MOD_NAME
 :interface {:version interface-version : Level}}
]]--
local camera = require("openmw.camera")
local core = require("openmw.core")
local self = require("openmw.self")
local storage = require("openmw.storage")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")
local I = require("openmw.interfaces")
local MOD_NAME = "MarksmansEye"
local item_refId = "marksmans_eye_item"
local playerSettings = storage.playerSection(("SettingsPlayer" .. MOD_NAME))
local L = core.l10n(MOD_NAME)
local Player = types.Player
local Weapon = types.Weapon
local counter_min = -3
local counter_max = 2
local combat_offset = util.vector2(-30, -10)
local aiming_offset = util.vector2(-15, 0)
local active = false
local do_effect = false
local counter = counter_min
local use_aiming_offset = false
local interface_version = 1
local script_version = 1
I.Settings.registerPage({key = MOD_NAME, l10n = MOD_NAME, name = "Marksman's Eye", description = "Adds a zoom effect while aiming a bow or crossbow"})
I.Settings.registerGroup({key = ("SettingsPlayer" .. MOD_NAME), l10n = MOD_NAME, name = "Zoom Settings", page = MOD_NAME, description = "Set the max intensity of the zoom effect (limit 1.9)", permanentStorage = false, settings = {{key = "maxZoom", name = "Max Zoom", default = 0.9, max = 1.9, min = 0, renderer = "number"}}})
local function apply_fov(magnitude)
  return camera.setFieldOfView((camera.getBaseFieldOfView() * (1 - (0.5 * magnitude))))
end
local function player_stat_base(kind, name)
  return Player.stats[kind][name](self).base
end
local function player_marksman_base()
  return player_stat_base("skills", "marksman")
end
local function player_speed_base()
  return player_stat_base("attributes", "speed")
end
local function effect_magnitude(c)
  local magic_num = 0.02685
  local marksman = player_marksman_base()
  local max_mag = playerSettings:get("maxZoom")
  local speed = player_speed_base()
  local modify_mrk = (marksman * magic_num)
  local modify_spd = (speed * (magic_num / 2))
  local modify = ((modify_mrk * modify_spd) / 2)
  return math.min((((math.max(0.1, math.exp((math.min(1, c) - 1))) - 0.1) / max_mag) * modify), max_mag)
end
local function have_item()
  do
    local inv = Player.inventory(self)
    local has = (inv:countOf(item_refId) > 0)
    if (has and not active) then
      ui.showMessage(L("abilityActive"))
    else
      if (not has and active) then
        ui.showMessage(L("abilityDeactive"))
      else
      end
    end
    active = has
  end
  return active
end
local function is_bow_prepared()
  if (Player.stance(self) == Player.STANCE.Weapon) then
    if ((camera.getMode() == camera.MODE.FirstPerson) or (camera.getMode() == camera.MODE.ThirdPerson)) then
      local item = Player.equipment(self, Player.EQUIPMENT_SLOT.CarriedRight)
      local weaponRecord = ((item ~= nil) and ((item.type == Weapon) and Weapon.record(item)))
      if weaponRecord then
        return ((weaponRecord.type == Weapon.TYPE.MarksmanBow) or (weaponRecord.type == Weapon.TYPE.MarksmanCrossbow))
      else
        return nil
      end
    else
      return nil
    end
  else
    return nil
  end
end
local function on_load(data)
  active = data.active
  return nil
end
local function on_save()
  return {active = active, version = script_version}
end
local function on_update(dt)
  have_item()
  if (active and (do_effect ~= is_bow_prepared())) then
    do_effect = not do_effect
    if do_effect then
      I.Camera.disableThirdPersonOffsetControl()
      camera.setFocalTransitionSpeed(5)
      camera.setFocalPreferredOffset(combat_offset)
    else
      I.Camera.enableThirdPersonOffsetControl()
    end
  else
  end
  if ((self.controls.use == 0) or not do_effect) then
    counter = math.max(counter_min, (counter - (dt * 2.5)))
  else
    counter = math.min(counter_max, (counter + (dt * 2.5)))
  end
  local effect = effect_magnitude(counter)
  apply_fov(effect)
  if (camera.getMode() ~= camera.MODE.ThirdPerson) then
    effect = 0
  else
  end
  if ((use_aiming_offset ~= (effect > 0.4)) and do_effect) then
    use_aiming_offset = (effect > 0.4)
    if use_aiming_offset then
      return camera.setFocalPreferredOffset(aiming_offset)
    else
      return camera.setFocalPreferredOffset(combat_offset)
    end
  else
    return nil
  end
end
local function Level()
  local fully_drawn = 2
  if active then
    local mag = effect_magnitude(fully_drawn)
    local max_mag = playerSettings:get("maxZoom")
    local lvl = (mag / max_mag)
    if (lvl == max_mag) then
      return "Maximum"
    else
      if (lvl >= 0.75) then
        return "High"
      else
        if (lvl >= 0.5) then
          return "Medium"
        else
          return "Low"
        end
      end
    end
  else
    return "Not active"
  end
end
return {engineHandlers = {onLoad = on_load, onSave = on_save, onUpdate = on_update}, interfaceName = MOD_NAME, interface = {version = interface_version, Level = Level}}
