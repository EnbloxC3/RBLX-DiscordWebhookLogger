-- ModuleScript

local FieldBuilder = {}
FieldBuilder.__index = FieldBuilder

function FieldBuilder.new()
	return setmetatable({
		fields = {}
	}, FieldBuilder)
end

function FieldBuilder:add(field)
	self.fields[#self.fields + 1] = field
	return self
end

function FieldBuilder:addAll(list)
	for i = 1, #list do
		self.fields[#self.fields + 1] = list[i]
	end
	return self
end

function FieldBuilder:field(name, value, inline)
	return self:add({name = name, value = value, inline = inline == nil and true or inline})
end

function FieldBuilder:blank(inline)
	return self:field("", "", inline ~= false)
end

function FieldBuilder:build()
	return self.fields
end

return FieldBuilder