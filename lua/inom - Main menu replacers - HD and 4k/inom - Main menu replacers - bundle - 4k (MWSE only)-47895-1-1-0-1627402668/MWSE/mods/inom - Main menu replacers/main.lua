--[[

	inom - Main menu replacers - HD and 4k
	An MWSE-lua mod for Morrowind
	
	@version      v1.1.0
	@author       Isnan
	@last-update  July 27, 2021
	@changelog
		v1.1.0
        - First lua release, bundle of all videos in one download.
        - A script to randomize between the seven videos upon load.
]]


-- store
local dir            = lfs.currentdir()
local videoFolder    = dir .. "\\Data Files\\Video\\"
local missingFile    = nil
local workingFile    = "menu_background.bik"
local availableFiles = {}
local backgrounds    = { 
    "menu_background-1.bik", 
    "menu_background-2.bik", 
    "menu_background-3.bik", 
    "menu_background-4.bik", 
    "menu_background-5.bik", 
    "menu_background-6.bik", 
    "menu_background-7.bik",
}

-- init
local function onInitialized()

    -- loop all backgrounds
    for _, background in ipairs(backgrounds) do
        -- add existing background files to the availableFiles array,  this way the end 
        -- users may delete videos they don't want without destroying the mod.
        if lfs.fileexists( videoFolder .. background ) then
            table.insert( availableFiles, background )
        else
            -- make a note of the missing file
            missingFile = background
        end
    end

    -- if there are no availablefiles, there's no reason to do anything, reinstall mod.
    if ( #availableFiles == 0 ) then
        return false
    end

    -- if we have an existing workingfile, and a missing file slot, rename the worker
    -- so we always backfill the array. We don't add the worker back as an availableFile
    -- to prevent the same video showing twice. (human preferrable untrue-random)
    if ( lfs.fileexists( videoFolder .. workingFile ) and missingFile ) then
        os.rename( videoFolder .. workingFile, videoFolder .. missingFile )
    end

    -- if we still have a working file, it might be from some previous download - make a backup for safety.
    if lfs.fileexists( videoFolder .. workingFile ) then
        backupFile = 'menu_background_' .. os.time(os.date('!*t')) .. '.bik'
        os.rename( videoFolder .. workingFile, videoFolder .. backupFile )
    end

    -- now select a random file to use as intro video.
    local n = math.ceil( math.random() * #availableFiles )
    os.rename( videoFolder .. availableFiles[n], videoFolder .. workingFile )

end

event.register( "initialized", onInitialized, { doOnce = true } )
