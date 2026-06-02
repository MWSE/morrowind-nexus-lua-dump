function ExtractFileName(path)
    return path:match("([^/\\]+)%.%w+$")
end
