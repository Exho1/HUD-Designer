Designer = Designer or {}


--| 							|--
--| Designer.drawShape
--| 							
--| Contains the drawing code for each shape in the designer
--| Optional third argument to convert to screen dimensions
--| 							|-
function Designer.drawShape( data, layer, bRenderOffCanvas )

	data.color = data.color or color_white
	
	local drawColor = data.color
	
	-- Draw shapes from other layers at a transparency
	if layer != Designer.currentLayer then
		drawColor = Designer.colorAlpha( drawColor, 200 )
	end
	
	surface.SetDrawColor( drawColor )
	
	local x, y = data.x, data.y
	local w, h = data.w, data.h 
	
	if bRenderOffCanvas == true then
		Designer.designerToScreenDim( x, y, w, h )
	end
	
	if data.type == "rect" then
		if isnumber(data.special[1]) then
			draw.RoundedBox( data.special[1], x, y, w, h, data.color )
		elseif data.special[2] then
			surface.SetMaterial( data.special[2] )
			surface.DrawTexturedRect( x, y, w, h )
		else
			surface.DrawRect( x, y, w, h )
		end
	elseif data.type == "text" then
		--local tbl = {type="text", x=x, y=y, font=font, text=text, color=color, xalign=xAlign}
		
		local drawnText = Designer.formatString( data.text, true ) 
		
		if data.xalign then
			draw.DrawText( drawnText, data.font, x, y, data.color, data.xalign) 
		else
			
			surface.SetFont( data.font )
			surface.SetTextColor( Designer.unpackColor( data.color ) )
			surface.SetTextPos( x, y )
			surface.DrawText( drawnText )
		end
		
	end
	
end

--| 							|--
--| Designer.drawSelectionBox
--| 							
--| 
--| 							|--
local selectionColor = 255
local goal = 0
function Designer.drawSelectionBox( data )

	local d = FrameTime() * 15

	if selectionColor > 253 then
		goal = 0
	elseif selectionColor < 20 then
		goal = 255
	end
	
	-- Make the colors flash a little 
	selectionColor = Lerp( d, selectionColor, goal )
	surface.SetDrawColor( Color( selectionColor, selectionColor, selectionColor, 230 ) )	
	
	-- Draw the selection elements
	local hBoxes, dBoxes = Designer.getSelectionBoxPositions()
	
	for _, tbl in pairs( hBoxes ) do
		surface.DrawRect( tbl[1], tbl[2], tbl[3], tbl[4] )
	end
	
	if data.type != "text" then
		-- Inverted colors
		--local col = 255 - selectionColor
		--surface.SetDrawColor( Color( col, col, col, 230 ) )
		
		for _, tbl in pairs( dBoxes ) do
			surface.DrawRect( tbl[1], tbl[2], tbl[3], tbl[4] )
		end
	end
	
end

--| 							|--
--| Designer.designerToScreenDim
--| 							
--| Converts the given position and size to an acceptable screen size
--| 							|--
function Designer.designerToScreenDim( x, y, w, h )
	
	-- Scale the coords back to the screen size
	--local x = math.floor(x * Designer.canvasConst.wratio)
	--local y = math.floor(y * Designer.canvasConst.hratio)
	
	local consts = Designer.canvasConst
	
	local x = math.floor(x * Designer.canvasConst.wratio)
	local y = math.floor(y * Designer.canvasConst.hratio)
	
	-- Snap to grid 
	--x, y = Designer.snapToGrid( x, y )
	
	--local w, h
	
	if w and h then
		w = math.floor(w * Designer.canvasConst.wratio)
		h = math.floor(h * Designer.canvasConst.hratio)
		
		--w, h = Designer.snapToGrid( w, h )
	end
	
	return x, y, w, h

end

--| 							|--
--| Designer.screenToDesignerDim
--|				
--| 	Converts the given position and size to an approximate for the designer.
--| Some accuracy is lost due to the grid and rounding process
--| 							|--
function Designer.screenToDesignerDim( x, y, w, h )

	local x = math.floor(x / Designer.canvasConst.wratio)
	local y = math.floor(y / Designer.canvasConst.hratio)
	
	x, y = Designer.snapToGrid( x, y )
	
	if w and h then 
		local w = width / Designer.canvasConst.wratio
		local h = height / Designer.canvasConst.wratio
		
		w, h = Designer.snapToGrid( w, h )
	end
	
	return x, y, w, h
	
end

--| 							|--
--| Designer.registerStringSub
--| 							
--| Creates a substitution option where the user can select a formatted string and it will
--| run the associated code and replace the placeholder arg with the output
--| 							|--
function Designer.registerStringSub( printName, placeholder, code )
	
	Designer.stringFormats[ printName ] = string.lower(placeholder)
	Designer.stringSubs[string.lower(placeholder)] = code
	
end

--| 							|--
--| Designer.layerCount
--| 							
--| Returns the amount of layers 
--| 							|--
function Designer.layerCount()
	
	local i = 0
	for layerNum, layerContents in pairs( Designer.canvasElements ) do
		i = i + 1
	end
	
	return i
	
end

--| 							|--
--| Designer.projectModified
--| 							
--| Called when the project is modified, optional argument to consider it saved
--| 							|--
function Designer.onProjectModified( bUndo )
	
	Designer.projectSaved = bUndo or false

end

--| 							|--
--| Designer.concat
--| 							
--| Concatenates arguments into a string 
--| 							|--
function Designer.concat( ... )
	
	local args = {...}
	local str = ""
	
	for _, v in pairs( args ) do
		str = str .. string.format( "%s", tostring(v) )
	end
	
	return str
end

--| 							|--
--| Designer.getDefaultValues
--| 							
--| Returns a set of average values for an example rectangle
--| 							|--
function Designer.getDefaultValues()

	local x = Designer.canvas:GetWide() / 2
	local y = Designer.canvas:GetTall() / 2
	
	local w = Designer.gridSize * 4
	local h = Designer.gridSize * 4
	
	x = x - w/2
	y = y - h/2
	
	return x, y, w, h
end

--| 							|--
--| Designer.getCanvasCenter
--| 							
--| Returns the center coordinates (snapped to the grid) of the canvas
--| 							|--
function Designer.getCanvasCenter()
	
	local x = Designer.canvas:GetWide() / 2
	local y = Designer.canvas:GetTall() / 2
	
	return Designer.snapToGrid(x, y)

end


--| 							|--
--| Designer.getSelectedShape
--| 							
--|	Returns the currently selected shape
--| 							|--
function Designer.getSelectedShape()
	
	local data = Designer.selectedShapeData
	
	if data then 
		return Designer.canvasElements[ data.layer ][ data.index ] 
	end
	
end

--| 							|--
--| Designer.getSelectionBoxPositions
--| 							
--| 	Returns two tables. First table contains the dimensions for the selection box and the seconds
--| contains the dimensions for the handles
--| 							|--
function Designer.getSelectionBoxPositions()
	
	local data = Designer.getSelectedShape()
	
	local x, y = data.x, data.y - 3
	
	local highlightBars = {}
	local dragHandles = {}
	
	if data.alignOffset then
		x = x - data.alignOffset
	end
	
	-- Draw a light selection box
	highlightBars[ #highlightBars + 1 ] = {x - 3, y + 3, 3, data.h}
	highlightBars[ #highlightBars + 1 ] = {x, y, data.w, 3}
	highlightBars[ #highlightBars + 1 ] = {x + data.w, y + 3, 3, data.h}
	highlightBars[ #highlightBars + 1 ] = {x, y + data.h + 3, data.w, 3}
	
	local w, h = 10, 10
	local yO = 6

	-- Draw the 4 corner boxes
	-- lT, rT, bB, lB
	dragHandles[ #dragHandles + 1 ] = { x - w, y - yO, w, h }
	dragHandles[ #dragHandles + 1 ] = { x + data.w, y - yO, w, h }
	dragHandles[ #dragHandles + 1 ] = { x + data.w, y + data.h + (yO/2), w, h }
	dragHandles[ #dragHandles + 1 ] = { x - w, y + data.h + (yO/2), w, h }
	
	local xOffset = (data.w / 2) - (w / 2)
	local yOffset = (data.h / 2) - (h / 2)
	
	-- Draw the 4 middle boxes
	-- T, R, B, L
	dragHandles[ #dragHandles + 1 ] = { x + xOffset, y - yO, w, h }
	dragHandles[ #dragHandles + 1 ] = { x + data.w, y + yOffset, w, h }
	dragHandles[ #dragHandles + 1 ] = { x + xOffset, y + data.h + (yO/2), w, h }
	dragHandles[ #dragHandles + 1 ] = { x - w, y + yOffset, w, h }
	
	return highlightBars, dragHandles

end

--| 							|--
--| Designer.dimensionsIntToString
--| 							
--| Takes a x, y, w, h table of integer keys and returns it with string keys
--| 							|--
function Designer.dimensionsIntToString( tbl )
	
	return {x=tbl[1], y=tbl[2], w=tbl[3], h=tbl[4]}

end

--| 							|--
--| Designer.createID
--| 							
--| Creates a unique number id for each shape
--| 							|--
function Designer.createID()

	Designer.shapeID = Designer.shapeID + 1
	return Designer.shapeID
	
end

--| 							|--
--| Designer.getShapeBB
--| 							
--| 	Returns the shape's position and size for the given ID
--| The shape will be assumed to be on the current layer unless stated otherwise
--| As of May 3rd, 2017 I have not actually used this function... So TODO: find a use for getShapeBB
--| 							|--
function Designer.getShapeBB( id, layer )
	
	layer = layer or Designer.currentLayer
	
	if layer then
		for k, data in pairs( Designer.canvasElements[ layer ] ) do
			if data.id == id then
				return data.x, data.y, data.w, data.h
			end
		end
	end
	
end

--| 							|--
--|	Designer.rectContainsPoint
--| 							
--| 	Returns whether or not a given X and Y coordinate is contained
--| within the given dimensions and position
--| 							|--
function Designer.rectContainsPoint( tbl, px, py )

	local x, y = tbl.x, tbl.y
	local w, h = tbl.w, tbl.h
	
	if not x or not y then
		print("Attempt to check nonexistant rect")
		return false
	end
	
	if px > x and px < x + w then -- The point is within the domain of the rectangle
		if py > y and py < y + h then -- The point is within the range of recatangle
			return true
		end
	end
	
	return false
	
end

--| 							|--
--| math.SnapTo
--| 							
--| 	Slightly modified. The snap to grid function from Luabee's polygon editor
--| 							|--
function math.SnapTo(num, point)

	num = math.Round(num)
	local possible = {min=0, max=0}
	for i=1, point do
		if math.IsDivisible(num+i, point) then
			possible.max = num+i
		end
		if math.IsDivisible(num-i, point) then
			possible.min = num-i
		end
	end
	
	if possible.max - num <= num - possible.min then
		return possible.max
	else
		return possible.min
	end
	
end

--| 							|--
--| Designer.getMousePos
--| 							
--| 	Returns the coordinates for the mouse position relative to its parent.
--| Arithmetic on the Y value is so its aligned properly with the canvas
--| 							|--
function Designer.getMousePos( parent )

	parent = parent or Designer.canvas

	local _, pY = parent:GetPos()
	
	local x = parent:ScreenToLocal( gui.MouseX() )
	local y = parent:ScreenToLocal( gui.MouseY() + Designer.menuBar:GetTall() )

	-- Return the position values, adjusted for the canvas's location on the frame
	return x, y
	
end

--| 							|--
--| Designer.canvasHasFocus
--| 							
--| Returns if the canvas being focused on
--| 							|--
function Designer.canvasHasFocus()

	if IsValid(Designer.createMenu) then return false end
	
	return true
	
end

--| 							|--
--| Designer.isCanvasEmpty
--| 							
--| Returns if the canvas has any elements
--| 							|--
function Designer.isCanvasEmpty()
	
	local elements = 0
	
	for layerNum, layerContents in pairs( Designer.canvasElements ) do
		for k, data in pairs( layerContents ) do
			if data.type then
				elements = elements + 1
			end
		end
	end
		
	return elements < 1

end

--| 							|--
--| Designer.clearCanvas
--| 							
--| Removes all elements from the canvas (called from a save prompt)
--| 							|--
function Designer.clearCanvas()
		
	for layerNum, layerContents in pairs( Designer.canvasElements ) do
		for k, data in pairs( layerContents ) do
			data = nil
		end
		
		Designer.canvasElements[layerNum] = {{}}
	end
	
	Designer.projectSaved = true
	Designer.projectName = "UnnamedProject-" .. Designer.getWritableDate()
	
end

--| 							|--
--| Designer.snapToGrid
--| 							
--| Snaps the given X and Y values to the grid by rounding
--| 							|--
function Designer.snapToGrid( x, y )

	-- If we're not snapping to the grid, don't
	if not Designer.gridEnabled then
		return x, y 
	end
	
	x = math.SnapTo(x, Designer.gridSize)
	y = math.SnapTo(y, Designer.gridSize)
	
	-- Constraints
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	
	return x, y
	
end

--| 							|--
--| Designer.getWritableDate
--| 							
--| Returns a unique string to identify a save file
--| 							|--
function Designer.getWritableDate()
	
	-- Month-day-hourminutesecond
	-- Apr-23-141312
	return tostring( os.date("%b-%d-%H%M%S") )
	
end

--| 							|--
--| Designer.viewLayer
--| 							
--| Changes the current layer of the designer
--| 							|--
function Designer.viewLayer( num )
	
	if num == 0 then return end
	
	Designer.currentLayer = num

end

--| 							|--
--| Designer.colorAlpha
--| 							
--| Changes the alpha property of a given color
--| 							|--
function Designer.colorAlpha( col, alpha )

	return Color( col.r or 0, col.g or 0, col.b or 0, alpha or 255 )
	
end

--| 							|--
--| Designer.unpackColor
--| 							
--| Returns all the elements of a color structure as var args
--| 							|--
function Designer.unpackColor( col )
	
	return col.r, col.g, col.b, col.a

end

--| 							|--
--| Designer.mouseMoving
--| 							
--| 	Returns if the mouse is currently changing its location but it requires the function...
--| to be continuously called. 
--| TODO: Implement this better so there can be a Designer.isMouseMoving() function 
--| that could be used instead
--| 							|--
local lastMouseX, lastMouseY = 0, 0
local lastMouseCheck = 0
function Designer.mouseMoving()
	local x, y = gui.MouseX(), gui.MouseY()
	
	-- Get the deltas of the positions
	local deltaX = lastMouseX - x
	local deltaY = lastMouseY - y
	
	-- Update the values again (every .2 seconds)
	if SysTime() - lastMouseCheck >= 0.2 then
		lastMouseCheck = SysTime()
		
		lastMouseX = x
		lastMouseY = y
	end

	if deltaX + deltaY != 0 then
		return true
	end
	return false
end

--| 							|--
--| Designer.print
--| 							
--| Outputs text into the chatbox, has different types for colors indicating severity
--| 							|--
function Designer.print( msg, type )
	
	type = type or "nil"
	type = string.lower( type )
	
	if type == "warning" then
		chat.AddText( -- RED
			Color(230, 57, 43), "[!Designer!]", 
			Color(255,255,255), ": "..msg
		)
	elseif type == "alert" then
		chat.AddText( -- YELLOW
			Color(241, 196, 15), "[Designer]", 
			Color(255,255,255), ": "..msg
		)
	elseif type == "notify" then
		chat.AddText( -- GREEN
			Color(39, 174, 96), "[Designer]", 
			Color(255,255,255), ": "..msg
		)
	else
		chat.AddText( -- Normal blue
			Color(127, 140, 141), "[Designer]", 
			Color(255,255,255), ": "..msg
		)
	end

end

-- Returns a function that calls the given function with the given arguments
function lambda( func, ... )
	local args = {...} or {}
	
	return function() func(unpack(args)) end
end

--| 							|--
--| Designer.formatString
--| 							
--| 	Converts a keyword wrapped in % signs to either the code behind it or the output
--| of that code
--| 							|--
local percentSignPattern = "%%[^%%]+%%"
function Designer.formatString( str, bExecute )

	-- Make sure this string has the placeholder char in it
	if string.find( str, "%%" ) then

		-- Find all matches that resemble %whatever%
		local iter = string.gmatch( str, percentSignPattern )
		
		-- Iterate through each of them
		for placeholder in iter do
		
			-- Grab the location of the placeholder in the original string
			local startIndex, endIndex = string.find( str, placeholder, 1, true )
			
			-- Grab that section 
			local subString = string.sub( str, startIndex, endIndex )
			
			-- We work in lowercase for string matching
			subString = string.lower(subString)
			
			-- Check if there is a substitution for that string
			local code = Designer.stringSubs[ subString ]
			
			if code then

				-- This returns just the code for exporting to Lua
				if !bExecute then
					return code
				end
				
				-- This method is definitely not my preferred way of handling anything but gLua does not have
				-- loadstring and RunString doesn't return any values from the executed code so 
				-- this is my only decent option 
				Designer.runtimeVars = Designer.runtimeVars or {}
				
				-- Store the results of the substitution code in a table
				code = string.format("Designer.runtimeVars['%s'] = tostring(%s)", subString, code )
				
				-- Run the code
				local err = RunString( code, "Designer", false )
				
				-- It will return the result of the code OR the placeholder string if the result is nil
				local subValue = Designer.runtimeVars[subString] or placeholder
				
				-- Grab the preceding string and following string
				local front = string.sub( str, 1, startIndex - 1 )
				local back = string.sub( str, endIndex + 1 )
				
				-- Merge it together
				str = front .. subValue .. back
			end
		end
	end
	
	return str
end

