love.graphics.setDefaultFilter("nearest", "nearest")

tiles = require "tileset"

local propKey = {
	_0_1_0_1 = { image = love.graphics.newImage("assets/tree.png"), offsetX = -8, offsetY = -32 },
	_0_0_0_1 = { image = love.graphics.newImage("assets/truck.png") },
	_0_0_1_1 = { image = love.graphics.newImage("assets/truck_overlay.png"), offsetY = -48 },
}

local propmap = love.image.newImageData("assets/props.png")
local propmapTex = love.graphics.newImage(propmap)

local function _draw(self)
	love.graphics.draw(self.prop.image, (self.prop.offsetX or 0) + self.x, (self.prop.offsetY or 0) + self.y)
end

local props = {}

local function instantiateProp(prop, x, y)
	local ret = {prop = prop, x = x, y = y, draw = _draw}
	table.insert(props, ret)
	return ret
end

for i = 0, propmap:getHeight() - 1 do
	for j = 0, propmap:getWidth() - 1 do
		local prop = propKey[("_%d_%d_%d_%d"):format(propmap:getPixel(j, i))]
		if prop then
			instantiateProp(prop, j * 16, i * 16)
		end
	end
end
function love.draw()
	local w, h = love.graphics.getDimensions()
	local s = math.min(w/20/16, h/15/16)
	love.graphics.clear(0, 0.1, 0.2)
	love.graphics.translate(w/2, 0)
	love.graphics.scale(s, s)
	love.graphics.translate(-20*8, 0)
	love.graphics.stencil(function () love.graphics.rectangle("fill", 0, 0, 20*16, 15*16) end)
	love.graphics.setStencilTest("equal", 1)
	table.sort(props, function(a, b) return a.y < b.y end)
	love.graphics.draw(tiles, 0, 0)
	for k, v in ipairs(props) do
		v:draw()
	end
end
