local deepCopy = require("CES/deepCopy")

---@class Class
---@param class Class|Object takes a class or object as a base
---@param super table|Object|Class takes a class or object to inherit
local function class(class, super)
	if not class then
		class = {}
		local meta = {}
		meta.__call = function(self, ...)
			---@class Object
			local object = deepCopy(class)
			if object.init then object:init(...) end
			return object
		end
		setmetatable(class, meta)
	end

	if super then
		for k, v in pairs(super) do
			class[k] = v
		end
	end

	return class
end

return class
