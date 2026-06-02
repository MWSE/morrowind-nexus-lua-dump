---@meta

-- This file was mechanically drafted from files/lua_api/openmw/vfs.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: global|menu|local|player|load

---Provides read-only access to data directories via VFS.
---Interface is very similar to "io" library.
---@class openmw.vfs
local vfs = {}

---@class openmw.vfs.FileHandle
---@field fileName string VFS path to related file
local FileHandle = {}

---Close a file handle
---@return boolean true if a call succeeds without errors.
---@return nil|string nil plus the error message in case of any error.
function FileHandle:close() end

---Get an iterator function to fetch the next line from a given file.
---Throws an exception if the file is closed.
---Hint: since garbage collection works once per frame,
---you will get the whole file in RAM if you read it in one frame.
---So if you need to read a really large file, it is better to split reading
---between different frames (e.g. by keeping a current position in file
---and using a "seek" to read from saved position).
---for line in f:lines() do
---end
---@return fun(...): any Iterator function to get next line
function FileHandle:lines() end

---Set new position in a file.
---Throws an exception if the file is closed or seek base is incorrect.
---f = vfs.open("Test\\test.txt");
---f:seek("set");
---f = vfs.open("Test\\test.txt");
---print(f:seek());
---f = vfs.open("Test\\test.txt");
---print(f:seek("end"));
---@param whence? string Seek base (optional, "cur" by default). Can be: * "set" - seek from beginning of file; * "cur" - seek from current position; * "end" - seek from end of file (offset needs to be <= 0);
---@param offset? number Offset from given base (optional, 0 by default)
---@return number new position in file if a call succeeds without errors.
---@return nil|string nil plus the error message in case of any error.
function FileHandle:seek(whence, offset) end

---Read data from a file to strings.
---Throws an exception if the file is closed, if there are too many arguments or if an invalid format is encountered.
---Hint: since garbage collection works once per frame,
---you will get the whole file in RAM if you read it in one frame.
---So if you need to read a really large file, it is better to split reading
---between different frames (e.g. by keeping a current position in file
---and using a "seek" to read from saved position).
---f = vfs.open("Test\\test.txt");
---local n1, n2, n3 = f:read("*number", "*number", "*number");
---f = vfs.open("Test\\test.txt");
---local n4 = f:read(10);
---f = vfs.open("Test\\test.txt");
---local n5 = f:read("*all");
---f = vfs.open("Test\\test.txt");
---local n6 = f:read();
---f = vfs.open("one.txt");
---print(f:read("*number", "*number", "*number"));
----- prints(1, nil)
---@param ... any Read formats (up to 20 arguments, default value is one "*l"). Can be: * "\*a" (or "*all") - reads the whole file, starting at the current position as #string. On end of file, it returns the empty string. * "\*l" (or "*line") - reads the next line (skipping the end of line), returning nil on end of file (nil and error message if error occured); * "\*n" (or "*number") - read a floating point value as #number (nil and error message if error occured); * number - reads a #string with up to this number of characters, returning nil on end of file (nil and error message if error occured). If number is 0 and end of file is not reached, it reads nothing and returns an empty string;
---@return string|nil One #string for every format if a call succeeds without errors. One #string for every successfully handled format for first failed format.
function FileHandle:read(...) end

---Check if a file exists in VFS
---@param fileName string Path to file in VFS
---@return boolean exists True if the file exists, false otherwise.
function vfs.fileExists(fileName) end

---Open a file
----- print file name or error message
---if (f == nil)
---else
---end
---@param fileName string Path to file in VFS
---@return openmw.vfs.FileHandle Opened file handle if a call succeeds without errors.
---@return nil|string nil plus the error message in case of any error.
function vfs.open(fileName) end

---Get an iterator function to fetch the next line from a file with the given path.
---Throws an exception if the file is closed or the file with the given path does not exist.
---Closes the file automatically when it fails to read any more bytes.
---Hint: since garbage collection works once per frame,
---you will get the whole file in RAM if you read it in one frame.
---So if you need to read a really large file, it is better to split reading
---between different frames (e.g. by keeping a current position in file
---and using a "seek" to read from saved position).
---end
---@param fileName string Path to file in VFS
---@return fun(...): any Iterator function to get next line
function vfs.lines(fileName) end

---Get an iterator function to fetch file names with given path prefix from the VFS
---for fileName in vfs.pathsWithPrefix("Music\\Explore") do
---end
---local getNextFile = vfs.pathsWithPrefix("Music\\Explore");
---local firstFile = getNextFile();
---local secondFile = getNextFile();
---@param path string Path prefix
---@return fun(...): any Function to get next file name
function vfs.pathsWithPrefix(path) end

---Detect a file handle type
---print(vfs.type(f));
---@param handle any Object to check
---@return string File handle type. Can be: * "file" - an argument is a valid opened openmw.vfs.FileHandle; * "closed file" - an argument is a valid closed openmw.vfs.FileHandle; * nil - an argument is not a openmw.vfs.FileHandle;
function vfs.type(handle) end

return vfs
