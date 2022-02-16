--[[
Keyring
by
The Wanderer

use keys directly from PC or CSW key container to unlock anything automatically... if you already have the key of course
player->additem "skeleton_key" 1

--]]

mwse.log("[Bag of Holding Keyring] Loaded successfully.")

--Pass in lock.
local function checkUnlockKey(e)
  -- only here if they have the BoH
  local key = e.target.lockNode.key
  local keyStore = tes3.getReference("tw_Keys_store")
        
  if ( key ~= nil ) then
     if ( tes3.player.object.inventory:contains(key) ) then
         e.target.lockNode.locked = false
         tes3.messageBox("%s used for unlocking.", key.id )
      elseif ( tes3.player.object.inventory:contains("skeleton_key") ) then
         e.target.lockNode.locked = false
         tes3.messageBox("Skeleton key used for unlocking.") 
       -- what to do about traps !!!
     else
        if ( keyStore.object.inventory:contains(key) ) then
         -- do they have it stored.  
           e.target.lockNode.locked = false
           tes3.messageBox("%s used for unlocking.", key )
        elseif ( keyStore.object.inventory:contains("skeleton_key") ) then   
            e.target.lockNode.locked = false
            tes3.messageBox("Skeleton key used for unlocking.")
        end
      end
  else
    if ( tes3.player.object.inventory:contains("skeleton_key") ) then
       e.target.lockNode.locked = false
       tes3.messageBox("Skeleton key used for unlocking.")
    elseif ( keyStore.object.inventory:contains("skeleton_key") ) then   
       e.target.lockNode.locked = false
       tes3.messageBox("Skeleton key used for unlocking.")
    end
  end
end

local function checkLock(e)   
  local player   = tes3.player
  if ( tes3.getItemCount({ reference = tes3.player, item = "tw_bagofholding_misc" }) > 0 ) then   
    if ( tes3.getLocked({ reference = e.target })   ) then
    -- only need to check if it is actually locked   
      checkUnlockKey(e) --, key, node)
    else
    end
  end
end
event.register("activate", checkLock)
