
local types = require('openmw.types')
local I = require('openmw.interfaces')







local songMap = {
   bk_ashland_hymns = 'Wondrous Love',
   bk_five_far_stars = 'Red Mountain',
   bk_words_of_the_wind = 'May I shrink to Dust',
}

local function makePath(song)
   return string.format('music/songsoftheashenwinds/%s.flac', song)
end

local function playSong(player, song)
   player:sendEvent('urm_SotAW_play', makePath(song))
end

I.ItemUsage.addHandlerForType(types.Book, function(object, actor)
   if actor.type == types.Player then
      local song = songMap[object.recordId]
      if song then
         print('SotAW playing', song)
         playSong(actor, song)
      end
   end
end)
