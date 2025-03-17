local core = require('openmw.core')



local followers = {}

local hud = require('scripts.AttendMe.hud')
local teleport = require('scripts.AttendMe.teleportFollowers')

return {
   eventHandlers = {
      AttendMeFollowerStatus = function(e)
         local index
         for i, follower in ipairs(followers) do
            if follower == e.actor then
               index = i
               break
            end
         end
         if e.status and not index then
            table.insert(followers, e.actor)
         end
         if not e.status and index then
            table.remove(followers, index)
         end
         hud.forceUpdate(followers)
      end,
      AttendMeFollowerAway = function(e)
         teleport.followerAway(e.actor)
      end,
   },
   engineHandlers = {
      onUpdate = function()
         hud.update(followers)
         teleport.update(followers)
      end,
   },
}
