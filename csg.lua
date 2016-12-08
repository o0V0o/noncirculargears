local CSG = js.global.CSG
local csg = {}

local function new(...)
	return js.new(...)
end
local function array(...)
	return js.global:jsArray(...)
end

function csg.Vector3D(x,y,z)
	if type(x)=='table' then
		return new( CSG.Vector3D,x.x, x.y, x.z)
	else
		return new( CSG.Vector3D,x,y,z)
	end
end
function csg.Vector2D(x,y)
	if type(x)=='table' then
		return new( CSG.Vector2D,x.x, x.y)
	else
		return new( CSG.Vector2D,x,y)
	end
end
function csg.Vertex(pos, norm)
	print("vertex")
	return new( CSG.Vertex, array({pos.x, pos.y, pos.z}), array({norm.x, norm.y, norm.z}))
end
function csg.Polygon(vertices)
	print("polygon")
	local verts = array(vertices)
	js.global.console:log( verts )
	local poly = new( CSG.Polygon, verts )
	print("Phew")
	return new( CSG.Polygon, array(vertices))
end
function csg.Solid(polygons)
	if polygons then
		print("solid")
		return CSG:fromPolygons( array(polygons))
	else
		print("gah.")
		return new(CSG)
	end
end

return csg
