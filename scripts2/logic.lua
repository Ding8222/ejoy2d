local socket = require"mylib.lualib.socket"
local msgparser = require"scripts2.msgparser"
local login_handler = require"scripts2.login_handler"
require"mylib.lualib.luaext"

local logic = {
	send_request = nil,
	REQUEST = {},
	RESPONSE = {},
	tcp = nil
}

local testip = "172.16.4.103"
--local testip = "47.52.138.32"
local loginserverip = testip

local gameserverip = testip

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

tcp = assert(socket.tcp())

assert(tcp:connect(loginserverip, 5001))
assert(tcp:settimeout(0))

local function send_request(msg,mainid,subid)
	local data = assert(msgparser.encode(mainid,subid,msg))
	local size = #data + 2 + 4
	
	local str = string.pack("<I4",size)..string.pack("I1I1", mainid, subid)..data
	
	tcp:send(str)
end

logic.tcp = tcp
logic.send_request = send_request
login_handler:register(logic)

logic.REQUEST.HandShake()


local function unpack_package(text)
	local size = #text
	if size < 4 then
		return nil, text
	end
	local s = text:byte(1) + text:byte(2) * 256 + text:byte(3) * 65536 + text:byte(4) * 16777216
	if size < s then
		return nil, text
	end
	return text:sub(5,s), text:sub(s+1)
end

local last = ""

local function unpack_f(f)
	local function try_recv(last)
		local result
		result, last = f(last)
		if result then
			return result, last
		end
		local r,e = tcp:receive(4)
		if not r then
			return nil, last
		else
			local size = r:byte(1) + r:byte(2) * 256 + r:byte(3) * 65536 + r:byte(4) * 16777216
			local rec = tcp:receive(size-4)
			r = r..rec
		end
		if r == "" then
			error "Server closed"
		end
		return f(last .. r)
	end

	--每秒尝试接受来自服务器的消息
	return function()
		local result
		result, last = try_recv(last)
		if result then
			return result
		end
	end
end

local readpackage = unpack_f(unpack_package)

local function recv_response(v)
	local size = #v - 2
	local mainid,subid,content, ok = string.unpack("I1I1".."c"..tostring(size), v)
	return ok ~=0, mainid, subid, content
end

function logic.dispatch_message()
	while true do
		local str = readpackage()
		if str ~= nil then
			local ok , mainid, subid, content = recv_response(str)
			if ok then
				local data = msgparser.decode(mainid, subid, content)
				logic.RESPONSE[msgparser["msgname_"..mainid.."_"..subid]()](data)
			end
		else
			break
		end
	end
end

return logic
