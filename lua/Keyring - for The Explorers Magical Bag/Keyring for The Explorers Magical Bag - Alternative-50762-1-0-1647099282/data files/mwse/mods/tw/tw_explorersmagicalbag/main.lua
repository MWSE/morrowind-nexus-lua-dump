--[[
Keyring
by
The Wanderer

use keys directly from PC or CSW key container to unlock anything automatically... if you already have the key of course
player->additem "skeleton_key" 1 - purly for testing.

Skeleton key only has 50 uses and option to not use it

--]]

mwse.log("[Bag of Holding Keyring] Loaded successfully.")

----------------------------------------------------------------------------------------------------
local function UseSkeletonKey(lock)
  
  tes3.messageBox ({
        message = "You have the skeleton key. Do you wish to use it?",
        buttons = {
              "Yes",
              "No" , 
            },
            callback = function(e)
                         timer.delayOneFrame(function()
                         if (e.button == 0 ) then
                            local keyObject = tes3.getObject("skeleton_key")
                            if ( keyObject.condition > 0 ) then
                                keyObject.condition = keyObject.condition - 1
                                lock.target.lockNode.locked = false 
                                lock.target.modified = true
                                
                                if ( keyObject.condition <= 0 ) then
                                   tes3.setEnabled({ reference = keyObject, enabled = false })  -- disable the key
                                   tes3.messageBox("Your Skeleton key has been used up.") 
                                else
                                  tes3.messageBox(
-- leave here on left to keep messagebox line formatting 
[[Skeleton key used for unlocking.
It has %s uses left]], keyObject.condition )    
                                end
                            else
                                tes3.messageBox("Your Skeleton key has been used up.")   
                                tes3.setEnabled({ reference = keyObject, enabled = false })  -- disable the key
                            end
                         end
                    end )    
            end          
        })
 
end

----------------------------------------------------------------------------------------------------
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
        timer.delayOneFrame( function() UseSkeletonKey(e) end )
     else
        if ( keyStore.object.inventory:contains(key) ) then
         -- do they have it stored.  
           e.target.lockNode.locked = false
           tes3.messageBox("%s used for unlocking.", key )
        elseif ( keyStore.object.inventory:contains("skeleton_key") ) then  
            timer.delayOneFrame( function() UseSkeletonKey(e) end )
        end
      end
  else   
    if ( tes3.player.object.inventory:contains("skeleton_key") ) then
      timer.delayOneFrame( function() UseSkeletonKey(e) end )
    elseif ( keyStore.object.inventory:contains("skeleton_key") ) then   
      timer.delayOneFrame( function() UseSkeletonKey(e) end )
    end
  end
end

----------------------------------------------------------------------------------------------------
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
