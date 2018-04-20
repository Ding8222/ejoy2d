local handler = {}
local mt = { __index = handler }

function handler.new (request, response, cmd)
	return setmetatable ({
		init_func = {},
		release_func = {},
		request = request,
		response = response,
	}, mt)
end

function handler:init (f)
	table.insert (self.init_func, f)
end

function handler:release (f)
	table.insert (self.release_func, f)
end

local function merge (dest, t)
	if not dest or not t then return end
	for k, v in pairs (t) do
		dest[k] = v
	end
end

function handler:register (logic)
	for _, f in pairs (self.init_func) do
		f (logic)
	end

	merge (logic.REQUEST, self.request)
	merge (logic.RESPONSE, self.response)
end

local function clean (dest, t)
	if not dest or not t then return end
	for k, _ in pairs (t) do
		dest[k] = nil
	end
end

function handler:unregister (logic)
	for _, f in pairs (self.release_func) do
		f ()
	end

	clean (logic.REQUEST, self.request)
	clean (logic.RESPONSE, self.response)
end

return handler
