local Class = require("herbert100.Class")


---@class herbert.AC.Animation_Info.new_params
---@field open_group number? animation group to use for open animation. Default: 1
---@field close_group number? animation group to use for close animation. Default: 2
---
---@field open_time number? amount of time it takes for open animation to play. Default: 0.5
---@field close_time number? amount of time it takes for flose animation to play. Default: `open_time`.
---
---@field sound_id string? You can pass this instead of `close_sound` and `open_sound` IF AND ONLY IF 
--- the `id` of the open and close sound follow the format `"AC_<sound_id>_open"` and `"AC_<sound_id>_close"`
---@field open_sound string|boolean? This should be the `id` of the sound to use. the actual sound will be grabbed when the game initializes.
---@field close_sound string|boolean? This should be the `id` of the sound to use. the actual sound will be grabbed when the game initializes.
---
---@field check_collisions boolean? should we check for collisions?

--[[ This class stores data about how animations behave. Such as:
* The open/close `group` of the animation. (Same meaning as in the `tes3.playAnimation` function.)
* The open/close `time` of the animation. i.e., the length in seconds of the open/close animation.
* The open/close `sound` of this animation. This can be either a `tes3sound` or the `id` of a `tes3sound`.
* Whether we should check for collisions when determining if the animation can be played.

**Note:** Instead of specifying an `open_sound` and `close_sound`, you can specify an `sound_id`. This will do the following:
* set `open_sound = "AC_<sound_id>_open"`
* set `open_sound = "AC_<sound_id>_close"`.

The default settings of each parameter are as follows:
1. `open_group = 1`
2. `close_group = 2`
3. `open_time = 0.5`
4. `close_time = <open_time>` (i.e., if `close_time` isn't specified, then `close_time == open_time`.)
5. `open_sound = nil`
6. `close_sound = nil`
7. `check_collisions = false`
]]
---@class herbert.AC.Animation_Info : herbert.Class, herbert.AC.Animation_Info.new_params
---@field open_sound string? path to the sound file to use when opening
---@field close_sound string? path to the sound file to use when closing
---@field check_collisions boolean? should we check for collisions before playing animations for this container?
---@field new fun(p:herbert.AC.Animation_Info.new_params): herbert.AC.Animation_Info make a new instance of this class
local Animation_Info = Class.new{name = "Animation_Info",
    fields = {
        {"sound_id"},
        {"open_group",          default=1,   eq=true}, -- `eq` means please use this field when checking if objects are equal
        {"close_group",         default=2,   eq=true},
        {"open_time",           default=0.5, eq=true,   converter=tonumber},
        {"close_time",          default=0.5, eq=true,   converter=tonumber},
        {"close_sound",                      eq=true,   },
        {"open_sound",                       eq=true,   },
        {"check_collisions",    default=false, eq=true  },
    },
	---@param self herbert.AC.Animation_Info
	post_init = function (self)
		if self.sound_id then
            self.open_sound = self.open_sound or string.format("AC_%s_open", self.sound_id)
            self.close_sound = self.close_sound or string.format("AC_%s_close", self.sound_id)
		end
        if self.open_sound and not string.find(self.open_sound, "%.wav$") then
            self.open_sound = string.format("AC\\%s.wav", self.open_sound)
        end
        if self.close_sound and not string.find(self.close_sound, "%.wav$") then
            self.close_sound = string.format("AC\\%s.wav", self.close_sound)
        end
        

        -- if no value for `close_time` is specified for this object, use the value of `open_time`
        -- if `open_time` isn't set, then it will be `nil` (and thus default to 0.5)
        if rawget(self, "close_time") == nil then
            self.close_time = rawget(self,"open_time")
        end
        
	end,
} ---@type herbert.AC.Animation_Info

return Animation_Info