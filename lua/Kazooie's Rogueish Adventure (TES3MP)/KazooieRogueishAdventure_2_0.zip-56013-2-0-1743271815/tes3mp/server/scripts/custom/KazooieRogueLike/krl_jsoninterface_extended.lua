jsonInterface.isExistingDirectory = function(directoryPath)
    return jsonInterface.ioLibrary.fs.isdir(config.dataPath.."/"..directoryPath)
end

jsonInterface.createDirectory = function(directoryPath)
    jsonInterface.ioLibrary.fs.mkdir(config.dataPath.."/"..directoryPath)
end

jsonInterface.createDirectoryIfNotExists = function(directoryPath)
    if not jsonInterface.isExistingDirectory(directoryPath) then
        jsonInterface.createDirectory(directoryPath)
    end
end

jsonInterface.ioLibrary.fs = {
    mkdir = function(dir_path)
        os.execute("mkdir "..dir_path)
    end,
    isdir = function(dir_path)
        local ok, err, code = os.rename(dir_path, dir_path)

        if ok then
            return true
        else
            if code == 13 then -- Permission denied, but it exists
                return true
            end
        end

        return false
    end,
    rm = function(file_path)
        local file = io.open(file_path, "w+")

        if file then
            file:write("")
            file:close()
        end

        os.remove(file_path)
        os.execute("sudo rm -f '"..file_path.."' &")
    end
}