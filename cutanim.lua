local gl = require("openGL")
local Vector = require("vector")
local Matrix = require("matrix")
local Camera = require("camera")
local Shader = require("shader")
local PointCloud = require'pointcloud'
local Polyline = require'polyline'
local Lines = require'lines'

local vec2, vec3, vec4 = Vector.vec2, Vector.vec3, Vector.vec4
print("loaded modules")

--setup camera
local camera = Camera( 0.001, 100, 45 )
camera.position = vec3(0,0,-40)
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


return function(gearset, stepanim)
	local gear, rack, extra
	local shape1 = Lines()
	local shape2 = Lines()
	local shape3 = Lines()
	local t = 0

	local stepped=false
	local step = function()
			stepped = true
			print("working...")
			local newgear, newrack, newextra = gearset:step()
			gear, rack, extra = newgear or gear, newrack or rack, newextra or extra
			shape1:setPoints(gear)
			shape2:setPoints(rack)
			shape3:setPoints(extra)
	end
	require'eventhandler'('next', 'click', step)

	local function render()
		collectgarbage() --by gc'ing every frame, we get (higer) more consistent framerates (23 vs 30 fps)
		--countFrames()
		gl.glClear(gl.GL_COLOR_BUFFER_BIT + gl.GL_DEPTH_BUFFER_BIT)

		if stepanim and stepped then
			step()
		end
	
		t=t+0.1


		ptShader:use()


		ptShader.model = Matrix.identity(4)
		ptShader.color = {1,1,1}
		shape1:draw(ptShader)

		ptShader.color = {0.15,0.6,1}
		shape2:draw(ptShader)

		ptShader.color = {0.15,1,0.6}
		shape3:draw(ptShader)

		js.global:requestAnimationFrame(render)
	end
	render()
end



