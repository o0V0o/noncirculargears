local class = require("object")
local SimpleObject = require("SimpleObject")
local Mesh = require("mesh").Mesh
local gl = require('openGL')
local PointCloud = require('pointcloud')

local Polyline = class(PointCloud)
function Polyline:__init(points)
	PointCloud.__init(self, points)
end
function Polyline:draw(shader)
	if self.dirty then self:recalculate(shader) end
	self.eab:bind()
	for name,attribute in pairs(shader.attributes) do
		local mesh_attrib = self.attributeMap[name]
		if self.vbos[mesh_attrib] then
			self.vbos[mesh_attrib]:useForAttribute(attribute)
		end
	end
	gl.glDrawElements( gl.GL_LINES, #(self.inds), self.eab.datatype, 0)
	self.eab:unbind()
end
return Polyline
