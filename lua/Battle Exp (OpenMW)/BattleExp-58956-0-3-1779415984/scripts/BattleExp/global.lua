---------------------------------------------------------------------------------
----------------------------- menu ----------------------------------------------
---------------------------------------------------------------------------------
local I = require('openmw.interfaces')

I.Settings.registerGroup({
    key              = 'SettingsBattleExp',
    page             = 'BattleExp',
    l10n             = 'BattleExp',
    name             = 'Customize your experience',
    permanentStorage = true,
    settings = {
        {
            key         = 'hideLevel',
            renderer    = 'checkbox',
            name        = 'Hide Character Level',
            description = 'Hides the level row in the character sheet.',
            default     = true,
        },
        {
            key         = 'disableLevel',
            renderer    = 'checkbox',
            name        = 'Disable Character Leveling',
            description = 'Disables vanilla character leveling.',
            default     = true,
        },
        {
            key         = 'userBattleExpScale',
            name        = 'Battle Experience progress scaling (%)',
            description = 'A higher percentage means faster leveling \n(1% - slowest, 100% - default, 1000% - fastest)',
            renderer    = 'number',
            integer     = true,
            default     = 100,
            min         = 1,
            max         = 1000,
        },
        {
            key         = 'showXpNotifications',
            renderer    = 'checkbox',
            name        = 'Show "defeated" notifications',
            description = 'Displays a "defeated" notification after each killed enemy.',
            default     = true,
        },
        {
            key         = 'showScaledXp',
            renderer    = 'checkbox',
            name        = 'Show scaled XP in "defeated" notifications',
            description = 'Scaled XP is affected by your Battle Experience level and custom scale, base XP depends only on enemy lvl.',
            default     = false,
        },
        {
            key         = 'rewardMelee',
            renderer    = 'checkbox',
            name        = 'Reward melee combat',
            description = 'Grants small XP bonus to Battle Experience for using melee weapons.',
            default     = true,
        },
        {
            key         = 'synergicTraining',
            renderer    = 'checkbox',
            name        = 'Synergic training',
            description = 'Using any melee weapon slightly improves proficiency with all others (until 50 skill lvl).',
            default     = false,
        },
        {
            key         = 'debug',
            renderer    = 'checkbox',
            name        = 'Debug mode',
            description = 'Logs all events into openmw.log \n(needs game restart or reloadlua in console).',
            default     = false,
        },
    },
})


---------------------------------------------------------------------------------
----------------------------- global --------------------------------------------
---------------------------------------------------------------------------------
local H = require('scripts/BattleExp/helpers')
local log = H.log

local storage = require('openmw.storage')
local summons = storage.globalSection('BattleExpSummons')

local settings = storage.globalSection('SettingsBattleExp')
local DEBUG = settings:get('debug')
H.setDebug(DEBUG)

local playerFollowers = storage.globalSection('PlayerFollowers')

return {
  eventHandlers = {
    RegisterPlayerSummon = function(actor)
      log('RegisterPlayerSummon event: %s', tostring(actor.id))
      summons:set(actor.id, true)
    end,
    UnregisterPlayerSummon = function(actor)
      log('UnregisterPlayerSummon event: %s', tostring(actor.id))
      summons:delete(actor.id)
    end,
    ClearAllPlayerSummons = function(actor)
      log('Clearing all player summons. Summon count: %s', H.countTruthyValues(summons:asTable()) or 0)
      summons:reset()
      log('Cleared all player summons. Summon count: %s', H.countTruthyValues(summons:asTable()) or 0)
    end,
    ClearAllPlayerFollowers = function(actor)
      log('Clearing all player followers. Follower count: %s', H.countTruthyValues(playerFollowers:asTable()) or 0)
      playerFollowers:reset()
      log('Cleared all player followers. Follower count: %s', H.countTruthyValues(playerFollowers:asTable()) or 0)
    end,
    FDU_UpdateFollowerListFromPlayer = function(data)
      log('FDU_UpdateFollowerListFromPlayer event fired')
      if data and data.followers then
        local followerIds = {}
        for id, follower in pairs(data.followers) do
          followerIds[id] = true
        end
        playerFollowers:set('all', followerIds)
        log('Cached %d follower IDs', H.countTruthyValues(followerIds) or 0)
      end
    end,
  }
}
