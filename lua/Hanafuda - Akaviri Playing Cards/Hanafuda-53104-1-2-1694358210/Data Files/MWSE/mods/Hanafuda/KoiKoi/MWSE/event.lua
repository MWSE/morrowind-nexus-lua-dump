---@class KoiKoi.EventHandler
---@field service KoiKoi.Service?
---@field enterFrameCallback fun(e : enterFrameEventData)?
---@field loadCallback fun(e : loadEventData)?
---@field debugDumpCallback fun(e : keyDownEventData)?
local this = {}

local logger = require("Hanafuda.logger")

---@param service KoiKoi.Service
---@return KoiKoi.EventHandler
function this.new(service)
    --@type KoiKoi.Event
    local instance = {
        service = service,
    }
    setmetatable(instance, { __index = this })
    return instance
end

---@param self KoiKoi.EventHandler
function this.Register(self)
    if not self.service then
        return
    end
    logger:debug("register service")
    local config = require("Hanafuda.config")

    assert(not self.enterFrameCallback)
    self.enterFrameCallback = function (e)
        self.service:OnEnterFrame(e.delta, e.timestamp)
    end
    event.register(tes3.event.enterFrame, self.enterFrameCallback)

    -- Stop services remaining when game is loaded during the game.
    assert(not self.loadCallback)
    self.loadCallback = function (e)
        self:Destory()
    end
    event.register(tes3.event.load, self.loadCallback)

    if config.development.debug then
        assert(not self.debugDumpCallback)
        self.debugDumpCallback = function (_)
            self.service:DumpData()
        end
        event.register(tes3.event.keyDown, self.debugDumpCallback, {filter = tes3.scanCode.d} )
    end
end

---@param self KoiKoi.EventHandler
function this.Unregister(self)
    logger:debug("unregister service")

    if self.enterFrameCallback then
        event.unregister(tes3.event.enterFrame, self.enterFrameCallback)
        self.enterFrameCallback = nil
    end
    if self.loadCallback then
        event.unregister(tes3.event.load, self.loadCallback)
        self.loadCallback = nil
    end
    if self.debugDumpCallback then
        event.unregister(tes3.event.keyDown, self.debugDumpCallback, {filter = tes3.scanCode.d} )
        self.debugDumpCallback = nil
    end
end

---@param self KoiKoi.EventHandler
function this.Initialize(self)
    if self.service then
        self.service:Initialize()
        self:Register()
    end
end

---@param self KoiKoi.EventHandler
function this.Destory(self)
    self:Unregister()
    if self.service then
        self.service:Destory()
        self.service = nil
    end
end

return this
