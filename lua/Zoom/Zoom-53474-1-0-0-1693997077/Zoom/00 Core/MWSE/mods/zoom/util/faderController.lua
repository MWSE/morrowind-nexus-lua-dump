local log = require("logging.logger").getLogger("zoom") --[[@as mwseLogger]]
local config = require("zoom.config").config

---@alias zoomFaderState
---|> "inactive"
---|  "activating"
---|  "active"
---|  "deactivating"

---@class zoomFaderController
---@field stateTimer mwseTimer|nil
---@field faderTexture string
---@field fadeTime number
---@field fader tes3fader
---@field state zoomFaderState
local faderController = {}

---@return zoomFaderController
function faderController:new()
	local o = {
		stateTimer = nil,
		faderTexture = "textures\\zoom\\spyglass.tga",
		fadeTime = 1.0,
		fader = nil,
		state = "inactive",
	}
	event.register(tes3.event.fadersCreated, function()
		o.fader = tes3fader.new()
		o.fader:setTexture(o.faderTexture)
		event.register(tes3.event.enterFrame, function()
			o.fader:update()
		end)
	end)


	setmetatable(o, self)
	self.__index = self
	return o
end

---@private
function faderController:canActivate()
	if self.state == "inactive" and config.faderOn then
		return true
	end

	return false
end

function faderController:activate()
	if not self:canActivate() then return end
	self.fader:activate()
	self.fader:fadeIn({ duration = self.fadeTime })
	self.state = "activating"
	self.stateTime = timer.start({
		type = timer.simulate,
		duration = self.fadeTime,
		iterations = 1,
		callback = function()
			self.state = "active"
		end
	})
end

---@private
function faderController:canDeactivate()
	if self.state == "active" then
		return true
	end
	return false
end

function faderController:deactivate()
	if not self:canDeactivate() then return end
	self.fader:fadeOut({ duration = self.fadeTime })
	self.state = "deactivating"
	self.stateTimer = timer.start({
		type = timer.simulate,
		duration = self.fadeTime,
		iterations = 1,
		callback = function()
			self.fader:deactivate()
			self.state = "inactive"
		end
	})
end

return faderController
