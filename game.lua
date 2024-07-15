require "globals"

local Game = {}

local function GetSuit( str )
	if string.sub( str, 3, 3 ) == "c" then
		return "clubs"
	elseif string.sub( str, 3, 3 ) == "s" then
		return "spades"
	elseif string.sub( str, 3, 3 ) == "h" then
		return "hearts"
	else
		return "diamonds"
	end
end

local function UpdateMetrics()
	metrics.card_width = 0.089 * window.tex_w
	metrics.card_height = 0.1935 * window.tex_h
	metrics.slot_start_left = 0.018 * window.tex_w
	metrics.slot_start_top = 0.037 * window.tex_h
	metrics.slot_card_offset_left = 0.005 * window.tex_w
	metrics.slot_card_offset_top = 0.008 * window.tex_h
	metrics.slot_width = 0.099 * window.tex_w
	metrics.slot_height = 0.208 * window.tex_h
	metrics.slot_between_gap = 0.015 * window.tex_w
	metrics.freecell_homecell_gap = 0.084 * window.tex_w
	metrics.card_between_vertical_gap = 0.0464 * window.tex_h
	metrics.stack_first_offset_left = 0.078 * window.tex_w
	metrics.stack_first_offset_top = 0.2992 * window.tex_h
	metrics.stacks_between_gap = 0.019 * window.tex_w
	metrics.text_scale = 0.017
	metrics.text_left = 0.178
	metrics.text_top = 0.015
end

local function WindowWasResized()
	local w, h = lovr.system.getWindowDimensions()
	if w ~= window.w or h ~= window.h then
		window.w = w
		window.h = h
		window.tex_w = w
		window.tex_h = h

		-- Do aspect correction
		if (window.w / window.h) > window.aspect_multiplier then
			window.tex_h = window.h
			window.tex_w = window.h * window.aspect_multiplier
		elseif (window.w / window.h) < window.aspect_multiplier then
			window.tex_w = window.w
			window.tex_h = window.w / window.aspect_multiplier
		end

		UpdateMetrics()

		-- Re-generate game texture/pass
		window.tex = lovr.graphics.newTexture( window.tex_w, window.tex_h )
		window.pass = lovr.graphics.newPass( window.tex )

		return true
	end

	return false
end

local function DrawCard( card, x, y )
	window.pass:setColor( 1, 1, 1 )
	window.pass:setMaterial( card.tex )
	window.pass:plane( x + (metrics.card_width / 2), y + (metrics.card_height / 2), 0, metrics.card_width, -metrics.card_height )
	if card.is_highlighted then
		window.pass:setMaterial( highlight_tex )
		window.pass:plane( x + (metrics.card_width / 2), y + (metrics.card_height / 2), 0, metrics.card_width + 10, -metrics.card_height - 10 )
		window.pass:setColor( 0, 0, 0 )
		window.pass:setMaterial()
		window.pass:plane( x + (metrics.card_width / 2), y + (metrics.card_height / 2), 0, metrics.card_width, -metrics.card_height, 0, 0, 0, 0, "line" )
	end
end

local function DrawInfo()
	window.pass:setColor( 0.66, 0.66, 0.66 )
	window.pass:text( "Press F2 for new game, ENTER to autocomplete", window.tex_w * metrics.text_left,
		window.tex_h * metrics.text_top, 0, window.tex_w * metrics.text_scale )
end

local function DrawSlots()
	window.pass:setMaterial()
	window.pass:setColor( 1, 1, 1 )

	local offset_left = metrics.slot_start_left

	for i = 1, 8 do
		window.pass:plane( offset_left + (metrics.slot_width / 2), metrics.slot_start_top + (metrics.slot_height / 2), 0, metrics.slot_width,
			metrics.slot_height, 0, 0, 0, 0, "line" )

		if i == 4 then
			offset_left = offset_left + metrics.slot_width + metrics.freecell_homecell_gap
		else
			offset_left = offset_left + metrics.slot_width + metrics.slot_between_gap
		end
	end
end

local function DrawStack( num )
	local left = metrics.stack_first_offset_left + ((num - 1) * (metrics.card_width + metrics.stacks_between_gap))
	local top = metrics.stack_first_offset_top

	for i, v in ipairs( tableau[ num ] ) do
		DrawCard( v, left, top )
		top = top + metrics.card_between_vertical_gap
	end
end

local function DrawTableau()
	for i = 1, 8 do
		DrawStack( i )
	end
end

local function DrawMovingStack()
	if #moving_stack > 0 then
		for i, v in ipairs( moving_stack ) do
			local vert_offset = (i - 1) * metrics.card_between_vertical_gap
			DrawCard( v, mouse.x - moving_stack.offset_x, mouse.y - moving_stack.offset_y + vert_offset )
		end
	end
end

local function DrawFreeCells()
	local top = metrics.slot_start_top

	for i, v in ipairs( free_cells ) do
		local left = metrics.slot_start_left + ((i - 1) * (metrics.slot_width + metrics.slot_between_gap))
		if v then
			DrawCard( v, left + metrics.slot_card_offset_left, top + metrics.slot_card_offset_top )
		end
	end
end

local function DrawHomeCells()
	local top = metrics.slot_start_top
	local home_offset = (4 * metrics.slot_width) + (3 * metrics.slot_between_gap) + metrics.freecell_homecell_gap

	for i, v in ipairs( home_cells ) do
		local left = metrics.slot_start_left + home_offset + ((i - 1) * (metrics.slot_width + metrics.slot_between_gap))
		if v then
			DrawCard( v, left + metrics.slot_card_offset_left, top + metrics.slot_card_offset_top )
		end
	end
end

local function Shuffle( t ) -- https://gist.github.com/Uradamus/10323382?permalink_comment_id=3149506#gistcomment-3149506
	local tbl = {}
	for i = 1, #t do
		tbl[ i ] = t[ i ]
	end
	for i = #tbl, 2, -1 do
		local j = math.random( i )
		tbl[ i ], tbl[ j ] = tbl[ j ], tbl[ i ]
	end
	return tbl
end

local function PointInRect( px, py, rx, ry, rw, rh )
	if px >= rx and px <= rx + rw and py >= ry and py <= ry + rh then
		return true
	end

	return false
end

local function LoadTextures()
	highlight_tex = lovr.graphics.newTexture( "res/misc/highlight.png", { mipmaps = false } )

	local items = lovr.filesystem.getDirectoryItems( "res" )

	for i, v in ipairs( items ) do
		local cur = items[ i ]
		if lovr.filesystem.isFile( "res/" .. items[ i ] ) then
			local rank = 0
			if string.sub( cur, 1, 1 ) == "0" then -- single digit
				rank = tonumber( string.sub( cur, 2, 2 ) )
			else                          -- double digit
				rank = tonumber( string.sub( cur, 1, 2 ) )
			end

			local suit = GetSuit( cur )
			local tex = lovr.graphics.newTexture( "res/" .. items[ i ], { mipmaps = 2 } )
			local card = { rank = rank, suit = suit, tex = tex, id = rank .. suit }
			table.insert( deck_ordered, card )
		end
	end
end

local function TrackMouseState()
	-- Mouse coords: account for aspect ratio
	local mx, my = lovr.system.getMousePosition()
	mouse.x, mouse.y = mx, my
	if window.w > window.tex_w then
		mouse.x = mx - ((window.w - window.tex_w) / 2)
	end
	if window.h > window.tex_h then
		mouse.y = my - ((window.h - window.tex_h) / 2)
	end

	-- Left button state
	if lovr.system.isMouseDown( 1 ) then
		if mouse.button_prev == 0 then
			mouse.button_prev = 1
			mouse.button_curr = 1
			mouse.state = e_mouse_state.clicked
		else
			mouse.button_prev = 1
			mouse.button_curr = 0
			mouse.state = e_mouse_state.held
		end
	else
		mouse.button_prev = 0
		mouse.state = e_mouse_state.released
	end
end

local function ClearHighlight()
	for i, stack in ipairs( tableau ) do
		for j, card in ipairs( stack ) do
			tableau[ i ][ j ].is_highlighted = false
		end
	end
end

local function GetStackHoveredCard()
	local stack, index, x, y = nil
	local xx, yy
	ClearHighlight()

	for i, v in ipairs( tableau ) do
		x = metrics.stack_first_offset_left + ((i - 1) * (metrics.card_width + metrics.stacks_between_gap))

		for j, card in ipairs( v ) do
			y = metrics.stack_first_offset_top + ((j - 1) * metrics.card_between_vertical_gap)

			local height = j == #v and metrics.card_height or metrics.card_between_vertical_gap
			if PointInRect( mouse.x, mouse.y, x, y, metrics.card_width, height ) then
				stack, index = i, j
				xx, yy = x, y
				break
			end
			if stack then break end
		end
	end

	if stack then
		-- tableau[ stack ][ index ].is_highlighted = true
		return tableau[ stack ][ index ], stack, index, xx, yy
	end
	return nil
end

local function GetFreeCellsHovered()
	local top = metrics.slot_start_top + metrics.slot_card_offset_top

	for i = 1, 4 do
		local left = metrics.slot_start_left + metrics.slot_card_offset_left + ((i - 1) * (metrics.slot_width + metrics.slot_between_gap))
		if PointInRect( mouse.x, mouse.y, left, top, metrics.card_width, metrics.card_height ) then
			return free_cells[ i ], i
		end
	end
end

local function GetHomeCellsHovered()
	local top = metrics.slot_start_top + metrics.slot_card_offset_top
	local home_offset = (4 * metrics.slot_width) + (3 * metrics.slot_between_gap) + metrics.freecell_homecell_gap

	for i = 1, 4 do
		local left = metrics.slot_start_left + metrics.slot_card_offset_left + home_offset + ((i - 1) * (metrics.slot_width + metrics.slot_between_gap))
		if PointInRect( mouse.x, mouse.y, left, top, metrics.card_width, metrics.card_height ) then
			return home_cells[ i ], i
		end
	end
end

local function CancelMove()
	-- Cancel and move cards back to their original positions
	for i, v in ipairs( moving_stack ) do
		local stack = v.original_stack
		local index = v.original_index
		local slot = v.original_slot

		if slot and not stack then -- This card was moved from a free_cell slot
			free_cells[ slot ] = v
		else                 -- Otherwise it (or them if more than one) were coming from stacks
			table.insert( tableau[ stack ], index, v )
		end
	end
	moving_stack = nil
	moving_stack = { offset_x = 0, offset_y = 0 }
end

local function ClearState()
	deck_session = {}
	moving_stack = { offset_x = 0, offset_y = 0 }
	tableau = {}
	home_cells = { false, false, false, false }
	free_cells = { false, false, false, false }
	deck_session = Shuffle( deck_ordered )
end

local function GetSuitColor( suit )
	if suit == "hearts" or suit == "diamonds" then return "red" end
	return "black"
end

local function PopulateTableau()
	local index = 1

	for stack = 1, 8 do
		local stack_table = {}

		local x = metrics.stack_first_offset_left + ((stack - 1) * (metrics.card_width + metrics.stacks_between_gap))
		local y = metrics.stack_first_offset_top

		for card = 1, 7 do
			if card == 7 and stack > 4 then
				break -- skip 7th card for stacks 5-8 (they have one card less from stacks 1-4)
			end
			local entry = deck_session[ index ]
			entry.is_highlighted = false
			entry.x = x
			entry.y = y
			table.insert( stack_table, entry )
			index = index + 1
			y = y + metrics.card_between_vertical_gap
		end

		table.insert( tableau, stack_table )
	end
end

local function CanMoveFromStack( stack, start_index )
	local cur_rank = tableau[ stack ][ start_index ].rank
	local cur_color = GetSuitColor( tableau[ stack ][ start_index ].suit )

	for i = start_index + 1, #tableau[ stack ] do
		local card = tableau[ stack ][ i ]
		if card.rank ~= cur_rank - 1 or GetSuitColor( card.suit ) == cur_color then
			return false
		else
			cur_rank = card.rank
			cur_color = GetSuitColor( card.suit )
		end
	end

	return true
end

local function CanDropToStack( target_card )
	local first_card = moving_stack[ 1 ]
	if first_card.rank == target_card.rank - 1 and GetSuitColor( first_card.suit ) ~= GetSuitColor( target_card.suit ) then return true end
	return false
end

local function CanDropToHome( home_hovered_card, home_slot_index )
	if home_hovered_card then
		if moving_stack[ 1 ].rank == home_hovered_card.rank + 1 and moving_stack[ 1 ].suit == home_hovered_card.suit then
			return true
		end
	elseif home_slot_index then -- Only Ace can drop to empty home cell
		if moving_stack[ 1 ].rank == 1 then
			return true
		end
	end
	return false
end

local function IsHoveredStackEmpty()
	local top = metrics.stack_first_offset_top
	for i, v in ipairs( tableau ) do
		local left = metrics.stack_first_offset_left + ((i - 1) * (metrics.card_width + metrics.stacks_between_gap))
		if PointInRect( mouse.x, mouse.y, left, top, metrics.card_width, metrics.card_height ) then
			return true, i
		end
	end
	return false
end

local function SetMovingStack()
	if #moving_stack == 0 then
		---------- MOVE CARD FROM FREE CELLS ----------
		local free_hovered_card, slot_index = GetFreeCellsHovered()
		if free_hovered_card then
			free_hovered_card.original_stack = nil
			free_hovered_card.original_index = nil
			free_hovered_card.original_slot = slot_index
			table.insert( moving_stack, free_hovered_card )
			free_cells[ slot_index ] = false

			local left = metrics.slot_start_left + metrics.slot_card_offset_left + ((slot_index - 1) * (metrics.slot_width + metrics.slot_between_gap))
			local top = metrics.slot_start_top + metrics.slot_card_offset_top
			moving_stack.offset_x = mouse.x - left
			moving_stack.offset_y = mouse.y - top
		end

		---------- MOVE CARD(S) FROM STACKS ----------
		local stack_hovered_card, stack, first_index, x, y = GetStackHoveredCard()

		if stack_hovered_card then
			if CanMoveFromStack( stack, first_index ) then
				-- traverse the tableau table backwards but add to the moving_stack table in reverse order
				for i = #tableau[ stack ], first_index, -1 do
					local card = tableau[ stack ][ i ]
					card.original_stack = stack
					card.original_index = i
					table.insert( moving_stack, 1, card )
					table.remove( tableau[ stack ], i )
				end

				moving_stack.offset_x = mouse.x - x
				moving_stack.offset_y = mouse.y - y
			end
		end
	end
end

local function ReleaseMovingStack()
	if #moving_stack > 0 then
		---------- FREE CELLS / HOME CELLS ----------
		if #moving_stack == 1 then                   -- Can only release a single card in free cells/ home cells
			local free_hovered_card, free_slot_index = GetFreeCellsHovered()
			if not free_hovered_card and free_slot_index then -- Empty slot
				free_cells[ free_slot_index ] = moving_stack[ 1 ]
				table.remove( moving_stack, 1 )
			end

			local home_hovered_card, home_slot_index = GetHomeCellsHovered()
			if CanDropToHome( home_hovered_card, home_slot_index ) then
				-- TODO: Test for correct order
				home_cells[ home_slot_index ] = moving_stack[ 1 ]
				table.remove( moving_stack, 1 )
			end
		end

		---------- STACKS ----------
		local stack_hovered_card, stack, last_index = GetStackHoveredCard()
		if stack_hovered_card then
			if last_index == #tableau[ stack ] then -- See if it's the bottom card of the stack we're dropping on to
				if CanDropToStack( stack_hovered_card ) then
					-- traverse the moving_stack table backwards but ALWAYS add to the same position (the "last_index + 1" part)
					-- to effectively place them back in their original order
					for i = #moving_stack, 1, -1 do
						local card = moving_stack[ i ]
						table.insert( tableau[ stack ], last_index + 1, card )
						table.remove( moving_stack, i )
					end
				else
					CancelMove()
				end
			else
				CancelMove()
			end
		else
			local is_empty, stack = IsHoveredStackEmpty()
			if is_empty then
				for i = #moving_stack, 1, -1 do
					local card = moving_stack[ i ]
					table.insert( tableau[ stack ], 1, card )
					table.remove( moving_stack, i )
				end
			else
				CancelMove()
			end
		end
	end
end

local function AutoSolve()
	while true do
		local found = false
		local candidate_card = nil

		for i = #tableau, 1, -1 do
			local stack = tableau[ i ]
			local stack_last_card = stack[ #stack ]

			if stack_last_card and stack_last_card.rank == 1 then
				candidate_card = stack_last_card
				for j, slot in ipairs( home_cells ) do
					if slot == false then -- means empty
						home_cells[ j ] = candidate_card
						table.remove( tableau[ i ], #stack )
						break
					end
				end
			else
				for j, slot in ipairs( home_cells ) do
					if stack_last_card and slot and stack_last_card.rank == home_cells[ j ].rank + 1 and stack_last_card.suit == home_cells[ j ].suit then
						candidate_card = stack_last_card
						home_cells[ j ] = candidate_card
						table.remove( tableau[ i ], #stack )
						break
					end
				end
			end
			if candidate_card then
				found = true
				break
			else
				found = false
			end
		end



		if not found then return end
	end
end

function Game.Init()
	math.randomseed( os.time() )

	-- Init window
	WindowWasResized()
	window.w, window.h = lovr.system.getWindowDimensions()
	window.tex = lovr.graphics.newTexture( window.w, window.h )
	window.pass = lovr.graphics.newPass( window.tex )

	LoadTextures()
end

function Game.Update()
	WindowWasResized()
	TrackMouseState()

	if game_state == e_game_state.init then
		ClearState()
		PopulateTableau()
		game_state = e_game_state.session
	elseif game_state == e_game_state.session then
		if mouse.state == e_mouse_state.clicked then
			SetMovingStack()
		end

		if mouse.state == e_mouse_state.released then
			ReleaseMovingStack()
		end
	elseif game_state == e_game_state.autosolve then
		AutoSolve()
		game_state = e_game_state.session
	end
end

function Game.Render()
	window.pass:setSampler( 'linear' )
	window.pass:reset()
	window.pass:setProjection( 1, mat4():orthographic( window.pass:getDimensions() ) )

	DrawSlots()
	if game_state == e_game_state.session then
		DrawTableau()
		DrawFreeCells()
		DrawHomeCells()
		DrawMovingStack()
		DrawInfo()
	end
end

return Game
