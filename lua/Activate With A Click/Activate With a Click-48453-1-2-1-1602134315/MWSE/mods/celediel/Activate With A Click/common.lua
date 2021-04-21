local this = {}

-- look, I made an enum in lua
this.click = {left = 0, right = 1, middle = 2, four = 3, five = 4, six = 5, seven = 6, eight = 7}

this.modName = "Activate with a Click"
this.author = "Celediel"
this.modInfo =
    [[Activate/interact with a click of the mouse, because simply mapping activate to a mouse button doesn't work when activating with objects that are made interactive by an MWSE Lua script.

Fixes interactivity with objects such as wells and kegs in Ashfall, and tameable guars in The Guar Whisperer.

I don't know why it happens but I wrote this script to "fix" it.

Requires Activate to be bound to a keyboard key for obvious reasons.
]]
this.version = "1.2.1"
this.configString = string.gsub(this.modName, "%s+", "")

return this
