-- need to add the path to our drawing library
package.path = "/drawlib/?.lua;?.lua"
-- and add a way to *load* said library.
require("httploader")
local gl = require("openGL")
local Vector = require("vector")
local Camera = require("camera")
local Shader = require("shader")
local PointCloud = require'pointcloud'
local Polyline = require'polyline'

local Quaternion = require("quaternion")
local Matrix = require("matrix")
local Functions = require'functions'

local vec2, vec3, vec4 = Vector.vec2, Vector.vec3, Vector.vec4
print("loaded modules")

--setup camera
local camera = Camera( 0.001, 100, 45 )
camera.position = vec3(0,0,-20)
camera:lookat(vec3(0,0,0))

--load shaders
local shader = Shader('shaders/simple.vs', 'shaders/phong.fs')
local ptShader = Shader('shaders/points.vs', 'shaders/points.fs')
--keep track of fps and memory info
local countFrames = require("fpscounter")
--enable typical gl stuff
gl.glEnable(gl.GL_DEPTH_TEST)
gl.glClearColor(0,0,0,1)
gl.viewport(0,0,gl.canvas.width, gl.canvas.height)
--set one-time uniforms
shader.lightPosition = {3,3,3.2}
shader.lightColor = {1,1,1,10}
shader.materialProperties = {1,1,0.2,10}
shader.materialColor = {1,1,1}
shader.attenuation = {0.9, 0.8}

ptShader.view = camera.view
ptShader.perspective = camera.perspective

return function(gear1, gear2)
	print(gear1, gear2)
	local shape1 = Polyline(gear1.profile)
	local shape2 = Polyline(gear2.profile)
	local t = 0
	local function render()
		collectgarbage() --by gc'ing every frame, we get (higer) more consistent framerates (23 vs 30 fps)
		countFrames()
		gl.glClear(gl.GL_COLOR_BUFFER_BIT + gl.GL_DEPTH_BUFFER_BIT)
	
		t=t+0.1

		ptShader:use()


		ptShader.model = gear1:transform(t)
		ptShader.color = {1,1,1}
		shape1:draw(ptShader)

		ptShader.model = gear2:transform(t)
		ptShader.color = {0.15,0.6,1}
		shape2:draw(ptShader)

		js.global:requestAnimationFrame(render)
	end
	render()
end



