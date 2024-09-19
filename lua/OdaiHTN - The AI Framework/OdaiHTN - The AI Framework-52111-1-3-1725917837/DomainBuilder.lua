local mc = require("sb_htn.Utils.middleclass")
local BaseDomainBuilder = require("sb_htn.BaseDomainBuilder")
local DefaultFactory = require("sb_htn.Factory.DefaultFactory")

--- A simple domain builder for easy use when one just need the core functionality
--- of the BaseDomainBuilder. This class is sealed, so if you want to extend the
--- functionality of the domain builder, extend BaseDomainBuilder instead.
---@class DomainBuilder<IContext> : BaseDomainBuilder<DomainBuilder, IContext>
local DomainBuilder = mc.class("DomainBuilder", BaseDomainBuilder)

---@param domainName string
---@param factory IFactory
---@param T IContext
function DomainBuilder:initialize(T, domainName, factory)
    BaseDomainBuilder.initialize(self, T, domainName, factory or DefaultFactory:new(), DomainBuilder)
end

return DomainBuilder
