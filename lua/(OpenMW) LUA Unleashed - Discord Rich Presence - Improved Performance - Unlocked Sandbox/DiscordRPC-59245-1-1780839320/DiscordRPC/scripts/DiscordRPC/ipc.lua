-- pure-ffi cross-platform ipc + network bridge for luajit.
-- transports: windows named pipe, unix domain socket, tcp (client + server).
--
-- acquires ffi itself: inside openmw via select('sandbox.bypass').ffi,
-- standalone luajit via require('ffi'). callers just require the module, no bypass dance.
--
-- public api:
--   ipc.connect_pipe(name [,timeout_ms]) -> conn | nil,err   client, local ipc
--   ipc.connect_tcp(host, port)          -> conn | nil,err   client, network
--   ipc.listen_pipe(name)                -> listener | nil,err
--   ipc.listen_tcp([host,] port [,backlog]) -> listener | nil,err   host nil = any iface
--   listener:accept()  -> conn | nil,err   (nil,"again" when non-blocking + idle)
--   listener:set_blocking(bool) -> true | nil,err   tcp/unix-socket listeners only
--   listener:close()
--   conn:write(data)   -> true | nil,err   writes all bytes
--   conn:read(n)       -> data | nil,err   exactly n bytes (nil,"closed" at eof)
--   conn:recv(n)       -> data | nil,err   up to n bytes, one syscall (nil,"closed" at eof)
--   conn:set_blocking(bool) -> true | nil,err   tcp/unix-socket conns only
--   conn:close()
--
-- a "pipe name" resolves per platform: windows -> \\.\pipe\<name>,
-- unix -> a unix-domain socket at $XDG_RUNTIME_DIR (or $TMPDIR, /tmp)/<name>.
-- pass a full path (containing a separator, or \\ on windows) to bypass resolution.
--
-- reads/writes block by default. call set_blocking(false) on a tcp/unix-socket conn or
-- listener to poll instead (recv/accept return nil,"again" when idle).
-- framing is the caller's job - this layer is a raw byte stream.

-- ffi from the openmw escape hatch when present (select is whitelisted in the sandbox),
-- else plain require for standalone luajit.
-- os_lib likewise - the sandbox withholds os.getenv, the bypass hands back the real os.
local ffi, os_lib
do
	local ok, bypass = pcall(select, "sandbox.bypass")
	if ok and type(bypass) == "table" and bypass.ffi then
		ffi = bypass.ffi
		os_lib = bypass.os or os
	else
		ffi = require("ffi")
		os_lib = os
	end
end

local os_name = ffi.os
local is_windows = (os_name == "Windows")
local is_osx = (os_name == "OSX")

local AF_UNIX = 1
local AF_INET = 2
local SOCK_STREAM = 1

local ipc = { os = os_name }

-- ------------------------------ cdefs ------------------------------
-- the ctstate is vm-wide and outlives a sandbox, but openmw re-runs this body on reload.
-- a 2nd ffi.cdef of the same struct throws "redefine", so a marker guards it.
local need_cdefs = not pcall(ffi.typeof, "struct __luaunleashed_ipc_marker")
if need_cdefs then ffi.cdef[[ struct __luaunleashed_ipc_marker { int unused; }; ]] end
if need_cdefs and is_windows then
	ffi.cdef[[
		typedef void* HANDLE;
		typedef int BOOL;
		typedef unsigned long DWORD;
		typedef uintptr_t SOCKET;

		HANDLE CreateFileA(const char* name, DWORD access, DWORD share, void* sec,
			DWORD disp, DWORD flags, HANDLE tmpl);
		BOOL WriteFile(HANDLE h, const void* buf, DWORD n, DWORD* written, void* ovl);
		BOOL ReadFile(HANDLE h, void* buf, DWORD n, DWORD* got, void* ovl);
		BOOL CloseHandle(HANDLE h);
		DWORD GetLastError(void);
		BOOL WaitNamedPipeA(const char* name, DWORD timeout);
		HANDLE CreateNamedPipeA(const char* name, DWORD openMode, DWORD pipeMode,
			DWORD maxInst, DWORD outBuf, DWORD inBuf, DWORD defTimeout, void* sec);
		BOOL ConnectNamedPipe(HANDLE h, void* ovl);
		BOOL DisconnectNamedPipe(HANDLE h);

		int WSAStartup(unsigned short ver, void* data);
		int WSAGetLastError(void);
		SOCKET socket(int af, int type, int proto);
		int connect(SOCKET s, const void* addr, int len);
		int bind(SOCKET s, const void* addr, int len);
		int listen(SOCKET s, int backlog);
		SOCKET accept(SOCKET s, void* addr, int* len);
		int send(SOCKET s, const void* buf, int len, int flags);
		int recv(SOCKET s, void* buf, int len, int flags);
		int closesocket(SOCKET s);
		int ioctlsocket(SOCKET s, long cmd, unsigned long* argp);
		unsigned short htons(unsigned short v);
		unsigned long inet_addr(const char* cp);
		struct hostent { char* h_name; char** h_aliases; short h_addrtype;
			short h_length; char** h_addr_list; };
		struct hostent* gethostbyname(const char* name);
		struct sockaddr_in { short sin_family; unsigned short sin_port;
			unsigned long sin_addr; char sin_zero[8]; };
	]]
elseif need_cdefs then
	-- bsd/mac put a 1-byte length before the 1-byte family. linux uses a 2-byte family.
	local fam_in = is_osx and "unsigned char sin_len; unsigned char sin_family;"
		or "unsigned short sin_family;"
	local fam_un = is_osx and "unsigned char sun_len; unsigned char sun_family;"
		or "unsigned short sun_family;"
	local un_cap = is_osx and 104 or 108
	ffi.cdef([[
		int socket(int domain, int type, int protocol);
		int connect(int fd, const void* addr, uint32_t len);
		int bind(int fd, const void* addr, uint32_t len);
		int listen(int fd, int backlog);
		int accept(int fd, void* addr, uint32_t* len);
		intptr_t send(int fd, const void* buf, size_t n, int flags);
		intptr_t recv(int fd, void* buf, size_t n, int flags);
		int close(int fd);
		int fcntl(int fd, int cmd, int arg);
		int setsockopt(int fd, int level, int opt, const void* val, uint32_t len);
		int unlink(const char* path);
		int inet_pton(int af, const char* src, void* dst);
		unsigned short htons(unsigned short v);
		struct hostent { char* h_name; char** h_aliases; int h_addrtype;
			int h_length; char** h_addr_list; };
		struct hostent* gethostbyname(const char* name);
		struct sockaddr_in { ]]..fam_in..[[ unsigned short sin_port;
			uint32_t sin_addr; char sin_zero[8]; };
		struct sockaddr_un { ]]..fam_un..[[ char sun_path[]]..un_cap..[[]; };
	]])
end

local kernel32 = is_windows and ffi.load("kernel32") or nil
local ws2 = is_windows and ffi.load("ws2_32") or nil
local C = (not is_windows) and ffi.C or nil
local net = is_windows and ws2 or C

-- ------------------------------ windows constants ------------------------------
local GENERIC_READ = 0x80000000
local GENERIC_WRITE = 0x40000000
local OPEN_EXISTING = 3
local PIPE_ACCESS_DUPLEX = 0x00000003
local PIPE_UNLIMITED_INSTANCES = 255
local ERROR_PIPE_BUSY = 231
local ERROR_BROKEN_PIPE = 109
local ERROR_PIPE_NOT_CONNECTED = 233
local ERROR_MORE_DATA = 234
local ERROR_PIPE_CONNECTED = 535
local INVALID_HANDLE_VALUE = is_windows and ffi.cast("void*", -1) or nil
local INVALID_SOCKET = is_windows and ffi.cast("SOCKET", -1) or nil

-- ------------------------------ posix constants ------------------------------
local SUN_PATH_MAX = is_osx and 104 or 108
local SOL_SOCKET = 0xffff      -- mac only
local SO_NOSIGPIPE = 0x1022    -- mac
local SEND_FLAGS = (os_name == "Linux") and 0x4000 or 0  -- MSG_NOSIGNAL on linux

-- ------------------------------ non-blocking ------------------------------
-- non-blocking lets a single-threaded host poll accept/recv per frame, not stall the vm
local FIONBIO = 0x8004667e          -- windows ioctlsocket cmd: set non-blocking
local WSAEWOULDBLOCK = 10035        -- windows: op would block
local F_SETFL = 4                   -- unix fcntl: set status flags
local O_NONBLOCK = is_osx and 0x0004 or 0x0800
local EAGAIN = is_osx and 35 or 11  -- unix: op would block (== EWOULDBLOCK)

-- flip blocking mode on a raw socket/fd (tcp + unix sockets, not win pipes)
local function socket_set_blocking(sock, blocking)
	if is_windows then
		local mode = ffi.new("unsigned long[1]", blocking and 0 or 1)
		if ws2.ioctlsocket(sock, FIONBIO, mode) ~= 0 then
			return nil, "ioctlsocket WSA "..ws2.WSAGetLastError()
		end
		return true
	end
	-- F_SETFL replaces all status flags - our sockets carry none we need to keep
	if C.fcntl(sock, F_SETFL, blocking and 0 or O_NONBLOCK) < 0 then
		return nil, "fcntl errno "..ffi.errno()
	end
	return true
end

-- ------------------------------ conn object ------------------------------
-- a conn wraps three closures over the live handle/fd:
--   _send(ptr,len) -> bytes_sent | nil,err
--   _recv(ptr,len) -> bytes_recv (0 = eof) | nil,err
--   _shut()        -> closes the underlying handle
local conn_mt = { __index = {} }
local conn = conn_mt.__index

function conn:write(data)
	if self._closed then return nil, "closed" end
	local len = #data
	local ptr = ffi.cast("const char*", data)
	local off = 0
	while off < len do
		local n, err = self._send(ptr + off, len - off)
		if not n then return nil, err end
		off = off + n
	end
	return true
end

function conn:recv(n)
	if self._closed then return nil, "closed" end
	local buf = ffi.new("char[?]", n)
	local got, err = self._recv(buf, n)
	if not got then return nil, err end
	if got == 0 then return nil, "closed" end
	return ffi.string(buf, got)
end

function conn:read(n)
	if self._closed then return nil, "closed" end
	local buf = ffi.new("char[?]", n)
	local off = 0
	while off < n do
		local got, err = self._recv(buf + off, n - off)
		if not got then return nil, err end
		if got == 0 then return nil, "closed" end
		off = off + got
	end
	return ffi.string(buf, n)
end

function conn:close()
	if self._closed then return true end
	self._closed = true
	self._shut()
	return true
end

-- non-blocking only on socket conns - recv then returns nil,"again" with no data
function conn:set_blocking(blocking)
	if not self._sock then return nil, "not a socket connection" end
	return socket_set_blocking(self._sock, blocking)
end

local function make_conn(send_fn, recv_fn, shut_fn, sock)
	return setmetatable({ _send = send_fn, _recv = recv_fn, _shut = shut_fn,
		_sock = sock, _closed = false }, conn_mt)
end

-- ------------------------------ listener object ------------------------------
local listener_mt = { __index = {} }
local listener = listener_mt.__index

function listener:accept()
	if self._closed then return nil, "closed" end
	return self._accept()
end

function listener:close()
	if self._closed then return true end
	self._closed = true
	self._shut()
	return true
end

-- non-blocking only on socket listeners - accept then returns nil,"again" when idle
function listener:set_blocking(blocking)
	if not self._sock then return nil, "not a socket listener" end
	return socket_set_blocking(self._sock, blocking)
end

local function make_listener(accept_fn, shut_fn, sock)
	return setmetatable({ _accept = accept_fn, _shut = shut_fn, _sock = sock,
		_closed = false }, listener_mt)
end

-- ------------------------------ windows named-pipe handle ------------------------------
local function winpipe_conn(h)
	local written = ffi.new("DWORD[1]")
	local got = ffi.new("DWORD[1]")
	local send_fn = function(ptr, len)
		if kernel32.WriteFile(h, ptr, len, written, nil) == 0 then
			return nil, "WriteFile failed: "..tonumber(kernel32.GetLastError())
		end
		return tonumber(written[0])
	end
	local recv_fn = function(ptr, len)
		if kernel32.ReadFile(h, ptr, len, got, nil) == 0 then
			local e = tonumber(kernel32.GetLastError())
			-- more-data still delivers got[0] bytes (message-mode pipe)
			if e == ERROR_MORE_DATA then return tonumber(got[0]) end
			if e == ERROR_BROKEN_PIPE or e == ERROR_PIPE_NOT_CONNECTED then return 0 end
			return nil, "ReadFile failed: "..e
		end
		return tonumber(got[0])
	end
	local shut_fn = function() kernel32.CloseHandle(h) end
	return make_conn(send_fn, recv_fn, shut_fn)
end

-- ------------------------------ posix socket fd ------------------------------
local function posix_conn(fd)
	local send_fn = function(ptr, len)
		local n = tonumber(C.send(fd, ptr, len, SEND_FLAGS))
		if n < 0 then return nil, "send errno "..ffi.errno() end
		return n
	end
	local recv_fn = function(ptr, len)
		local n = tonumber(C.recv(fd, ptr, len, 0))
		if n < 0 then
			if ffi.errno() == EAGAIN then return nil, "again" end
			return nil, "recv errno "..ffi.errno()
		end
		return n
	end
	local shut_fn = function() C.close(fd) end
	return make_conn(send_fn, recv_fn, shut_fn, fd)
end

-- ------------------------------ winsock socket ------------------------------
local function winsock_conn(s)
	local send_fn = function(ptr, len)
		local n = ws2.send(s, ptr, len, 0)
		if n < 0 then return nil, "send WSA "..ws2.WSAGetLastError() end
		return n
	end
	local recv_fn = function(ptr, len)
		local n = ws2.recv(s, ptr, len, 0)
		if n < 0 then
			if ws2.WSAGetLastError() == WSAEWOULDBLOCK then return nil, "again" end
			return nil, "recv WSA "..ws2.WSAGetLastError()
		end
		return n
	end
	local shut_fn = function() ws2.closesocket(s) end
	return make_conn(send_fn, recv_fn, shut_fn, s)
end

-- ------------------------------ winsock init ------------------------------
local wsa_started = false
local function ensure_wsa()
	if wsa_started then return true end
	local data = ffi.new("char[?]", 512)  -- WSADATA is ~400 bytes
	if ws2.WSAStartup(0x0202, data) ~= 0 then
		return nil, "WSAStartup failed"
	end
	wsa_started = true
	return true
end

-- ------------------------------ address helpers ------------------------------
local function resolve_pipe_name(name)
	if is_windows then
		if name:sub(1, 2) == "\\\\" then return name end
		return "\\\\.\\pipe\\"..name
	end
	if name:find("/", 1, true) then return name end
	local dir = os_lib.getenv("XDG_RUNTIME_DIR") or os_lib.getenv("TMPDIR") or "/tmp"
	if dir:sub(-1) == "/" then dir = dir:sub(1, -2) end
	return dir.."/"..name
end

local function new_sockaddr_un(path)
	if #path + 1 > SUN_PATH_MAX then return nil, "socket path too long" end
	local addr = ffi.new("struct sockaddr_un")
	addr.sun_family = AF_UNIX
	ffi.copy(addr.sun_path, path, #path)
	local len = ffi.offsetof("struct sockaddr_un", "sun_path") + #path + 1
	if is_osx then addr.sun_len = len end
	return addr, len
end

-- returns a 32-bit address in network byte order
local function resolve_ipv4(host)
	if is_windows then
		local a = tonumber(ffi.cast("uint32_t", ws2.inet_addr(host)))
		if a ~= 0xffffffff then return a end
		local he = ws2.gethostbyname(host)
		if he == nil then return nil, "cannot resolve "..host end
		return tonumber(ffi.cast("uint32_t*", he.h_addr_list[0])[0])
	end
	local out = ffi.new("uint32_t[1]")
	if C.inet_pton(AF_INET, host, out) == 1 then return tonumber(out[0]) end
	local he = C.gethostbyname(host)
	if he == nil then return nil, "cannot resolve "..host end
	return tonumber(ffi.cast("uint32_t*", he.h_addr_list[0])[0])
end

local function new_sockaddr_in(netaddr, port)
	local addr = ffi.new("struct sockaddr_in")
	addr.sin_family = AF_INET
	addr.sin_port = net.htons(port)
	addr.sin_addr = netaddr
	if is_osx then addr.sin_len = ffi.sizeof("struct sockaddr_in") end
	return addr, ffi.sizeof("struct sockaddr_in")
end

local function set_nosigpipe(fd)
	if is_osx then
		local one = ffi.new("int[1]", 1)
		C.setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, one, 4)
	end
end

-- ------------------------------ client: pipe ------------------------------
function ipc.connect_pipe(name, timeout_ms)
	local path = resolve_pipe_name(name)
	if is_windows then
		timeout_ms = timeout_ms or 3000
		while true do
			local h = kernel32.CreateFileA(path, GENERIC_READ + GENERIC_WRITE,
				0, nil, OPEN_EXISTING, 0, nil)
			if h ~= INVALID_HANDLE_VALUE then return winpipe_conn(h) end
			local e = tonumber(kernel32.GetLastError())
			if e ~= ERROR_PIPE_BUSY then
				return nil, "CreateFile failed: "..e
			end
			if kernel32.WaitNamedPipeA(path, timeout_ms) == 0 then
				return nil, "pipe busy, wait timed out"
			end
		end
	end
	-- unix domain socket client
	local fd = C.socket(AF_UNIX, SOCK_STREAM, 0)
	if fd < 0 then return nil, "socket errno "..ffi.errno() end
	set_nosigpipe(fd)
	local addr, addrlen = new_sockaddr_un(path)
	if not addr then C.close(fd); return nil, addrlen end
	if C.connect(fd, addr, addrlen) ~= 0 then
		local e = ffi.errno(); C.close(fd)
		return nil, "connect errno "..e
	end
	return posix_conn(fd)
end

-- ------------------------------ client: tcp ------------------------------
function ipc.connect_tcp(host, port)
	local netaddr, rerr = resolve_ipv4(host)
	if not netaddr then return nil, rerr end
	if is_windows then
		local ok, werr = ensure_wsa()
		if not ok then return nil, werr end
		local s = ws2.socket(AF_INET, SOCK_STREAM, 0)
		if s == INVALID_SOCKET then return nil, "socket WSA "..ws2.WSAGetLastError() end
		local addr, addrlen = new_sockaddr_in(netaddr, port)
		if ws2.connect(s, addr, addrlen) ~= 0 then
			local e = ws2.WSAGetLastError(); ws2.closesocket(s)
			return nil, "connect WSA "..e
		end
		return winsock_conn(s)
	end
	local fd = C.socket(AF_INET, SOCK_STREAM, 0)
	if fd < 0 then return nil, "socket errno "..ffi.errno() end
	set_nosigpipe(fd)
	local addr, addrlen = new_sockaddr_in(netaddr, port)
	if C.connect(fd, addr, addrlen) ~= 0 then
		local e = ffi.errno(); C.close(fd)
		return nil, "connect errno "..e
	end
	return posix_conn(fd)
end

-- ------------------------------ server: pipe ------------------------------
function ipc.listen_pipe(name)
	local path = resolve_pipe_name(name)
	if is_windows then
		local function new_instance()
			return kernel32.CreateNamedPipeA(path, PIPE_ACCESS_DUPLEX, 0,
				PIPE_UNLIMITED_INSTANCES, 65536, 65536, 0, nil)
		end
		local pending = new_instance()
		if pending == INVALID_HANDLE_VALUE then
			return nil, "CreateNamedPipe failed: "..tonumber(kernel32.GetLastError())
		end
		local accept_fn = function()
			-- block until a client opens the pending instance
			if kernel32.ConnectNamedPipe(pending, nil) == 0 then
				local e = tonumber(kernel32.GetLastError())
				if e ~= ERROR_PIPE_CONNECTED then
					return nil, "ConnectNamedPipe failed: "..e
				end
			end
			local c = winpipe_conn(pending)
			pending = new_instance()  -- ready the next instance
			return c
		end
		local shut_fn = function()
			if pending ~= INVALID_HANDLE_VALUE then kernel32.CloseHandle(pending) end
		end
		return make_listener(accept_fn, shut_fn)
	end
	-- unix domain socket server
	local fd = C.socket(AF_UNIX, SOCK_STREAM, 0)
	if fd < 0 then return nil, "socket errno "..ffi.errno() end
	C.unlink(path)  -- clear a stale socket file
	local addr, addrlen = new_sockaddr_un(path)
	if not addr then C.close(fd); return nil, addrlen end
	if C.bind(fd, addr, addrlen) ~= 0 then
		local e = ffi.errno(); C.close(fd); return nil, "bind errno "..e
	end
	if C.listen(fd, 16) ~= 0 then
		local e = ffi.errno(); C.close(fd); return nil, "listen errno "..e
	end
	local accept_fn = function()
		local cfd = tonumber(C.accept(fd, nil, nil))
		if cfd < 0 then
			if ffi.errno() == EAGAIN then return nil, "again" end
			return nil, "accept errno "..ffi.errno()
		end
		set_nosigpipe(cfd)
		return posix_conn(cfd)
	end
	local shut_fn = function() C.close(fd); C.unlink(path) end
	return make_listener(accept_fn, shut_fn)
end

-- ------------------------------ server: tcp ------------------------------
function ipc.listen_tcp(host, port, backlog)
	-- host is optional - ipc.listen_tcp(port) binds to all interfaces
	if port == nil or type(host) == "number" then
		host, port, backlog = nil, host, port
	end
	backlog = backlog or 16
	local netaddr = 0  -- INADDR_ANY
	if host and host ~= "0.0.0.0" and host ~= "*" then
		local a, rerr = resolve_ipv4(host)
		if not a then return nil, rerr end
		netaddr = a
	end
	if is_windows then
		local ok, werr = ensure_wsa()
		if not ok then return nil, werr end
		local s = ws2.socket(AF_INET, SOCK_STREAM, 0)
		if s == INVALID_SOCKET then return nil, "socket WSA "..ws2.WSAGetLastError() end
		local addr, addrlen = new_sockaddr_in(netaddr, port)
		if ws2.bind(s, addr, addrlen) ~= 0 then
			local e = ws2.WSAGetLastError(); ws2.closesocket(s)
			return nil, "bind WSA "..e
		end
		if ws2.listen(s, backlog) ~= 0 then
			local e = ws2.WSAGetLastError(); ws2.closesocket(s)
			return nil, "listen WSA "..e
		end
		local accept_fn = function()
			local cs = ws2.accept(s, nil, nil)
			if cs == INVALID_SOCKET then
				if ws2.WSAGetLastError() == WSAEWOULDBLOCK then return nil, "again" end
				return nil, "accept WSA "..ws2.WSAGetLastError()
			end
			return winsock_conn(cs)
		end
		local shut_fn = function() ws2.closesocket(s) end
		return make_listener(accept_fn, shut_fn, s)
	end
	local fd = C.socket(AF_INET, SOCK_STREAM, 0)
	if fd < 0 then return nil, "socket errno "..ffi.errno() end
	local addr, addrlen = new_sockaddr_in(netaddr, port)
	if C.bind(fd, addr, addrlen) ~= 0 then
		local e = ffi.errno(); C.close(fd); return nil, "bind errno "..e
	end
	if C.listen(fd, backlog) ~= 0 then
		local e = ffi.errno(); C.close(fd); return nil, "listen errno "..e
	end
	local accept_fn = function()
		local cfd = tonumber(C.accept(fd, nil, nil))
		if cfd < 0 then
			if ffi.errno() == EAGAIN then return nil, "again" end
			return nil, "accept errno "..ffi.errno()
		end
		set_nosigpipe(cfd)
		return posix_conn(cfd)
	end
	local shut_fn = function() C.close(fd) end
	return make_listener(accept_fn, shut_fn, fd)
end

return ipc
