require "globals"
local UI2D = require "ui2d..ui2d"
local Game = require "game"
-- lovr.graphics.setBackgroundColor( 0.2, 0.2, 0.7 )

function lovr.load()
	UI2D.Init( "lovr" )
	Game.Init()
end

function lovr.keypressed( key, scancode, repeating )
	UI2D.KeyPressed( key, repeating )
	if key == "f1" then
		game_state = e_game_state.init
	end
end

function lovr.textinput( text, code )
	UI2D.TextInput( text )
end

function lovr.keyreleased( key, scancode )
	UI2D.KeyReleased()
end

function lovr.wheelmoved( deltaX, deltaY )
	UI2D.WheelMoved( deltaX, deltaY )
end

function lovr.mousepressed( x, y, button )

end

function lovr.mousereleased( x, y, button )

end

function lovr.update( dt )
	UI2D.InputInfo()
	Game.Update()
end

function lovr.draw( pass )
	pass:setProjection( 1, mat4():orthographic( pass:getDimensions() ) )

	UI2D.Begin( "main", 0, 450 )
	UI2D.Label( "game state:" .. game_state )
	UI2D.Label( tostring( window.tex_w ) )
	if UI2D.Button( "Shuffle..." ) then
		game_state = e_game_state.init
	end
	UI2D.End( pass )

	Game.Render()

	pass:setColor( 0.043, 0.411, 0.168 )
	pass:plane( window.w / 2, window.h / 2, 0, window.tex_w, window.tex_h )
	pass:setColor( 1, 1, 1 )
	pass:setMaterial( window.tex )
	pass:plane( window.w / 2, window.h / 2, 0, window.tex_w, -window.tex_h )

	local passes = UI2D.RenderFrame( pass )
	table.insert( passes, pass )
	table.insert( passes, window.pass )
	return lovr.graphics.submit( passes )
end
