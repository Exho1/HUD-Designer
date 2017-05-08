Designer = Designer or {}

--[[
	Food for thought...
	1. Shapes will scale but what about fonts? Even just in exporting..
	
	To do:
	- Save fonts?
		- Saved with the project or seperately
	- Ammo and health bars
	- Option to scale HUDs based on screensize created within the editor
	- Option to remove certain default HUD parts
	- Finish touching up the workflow parts 

]]

--| 							|--
--| Designer.initializeVars
--| 							
--| Sets all the variables to their defaults for the Designer, called every time it opens
--| 							|--
function Designer.initializeVars()
	
	-- Holds references to all of the HUD elements on the canvas
	Designer.canvasElements = {{}}
	--[[
		[layer] = {
			{
				type, x, y, w, h, color, {special}, layer, id
			}
		}
	]]
	
	-- Holds references to editor controls ex: sizing boxes
	Designer.editorElements = {}
	
	-- Contains the size of the grid
	Designer.canvasConst = {
		w = 0,
		h = 0,
		wratio = 0,
		hratio = 0,
	}
	
	Designer.actions = {
		NONE = 0,
		MOVE = 1,
		RESIZE = 2,
		
	}
	
	Designer.gamemodeSprites = {
		-- The blue G for garrysmod
		-- Red T for TTT
		-- etc
	
	}
	
	Designer.stringFormats = Designer.stringFormats or {
		["[GMD] Name"] = "%nick%",
		["[GMD] Team"] = "%team%",
		["[GMD] Health"] = "%health%",
		["[GMD] Weapon"] = "%weapon%",
		["[GMD] Ammo Max"] = "%ammo_m%",
		["[GMD] Ammo Current"] = "%ammo_c%",
		["[GMD] Ammo Reserve"] = "%ammo_r%",
		["[GMD] Armor"] = "%armor%",
		["[GMD] SteamID"] = "%steamid%",
		["[GMD] Velocity"] = "%velocity%",
		-- Add new ones using the function below
	}
	
	Designer.stringSubs = Designer.stringSubs or {
		["%nick%"] = "LocalPlayer():Nick()",
		["%team%"] = "team.GetName(LocalPlayer():Team())",
		["%health%"] = "LocalPlayer():Health()",
		["%weapon%"] = "LocalPlayer():GetActiveWeapon():GetPrintName()",
		["%ammo_m%"] = "LocalPlayer():GetActiveWeapon().Primary.ClipSize",
		["%ammo_c%"] = "LocalPlayer():GetActiveWeapon().Clip1()",
		["%ammo_r%"] = "LocalPlayer():GetActiveWeapon().Ammo1()",
		["%armor%"] = "LocalPlayer():Armor()",
		["%steamid%"] = "LocalPlayer():SteamID()",
		["%velocity%"] = "LocalPlayer():GetVelocity():Length()",
	
	}
	
	-- Custom string substitutions for the editor
	-- (If an error occurs with the code, it'll just display the placeholder) 
	Designer.registerStringSub( "[TTT] Round State", "%ttt_round%", "L[ roundstate_string[GAMEMODE.round_state] ]" )
	Designer.registerStringSub( "[TTT] Round Time", "%ttt_time%", 'util.SimpleTime(math.max(0, GetGlobalFloat("ttt_round_end", 0) - CurTime()), "%02i:%02i")')
	Designer.registerStringSub( "[TTT] Role", "%ttt_role%", "L[LocalPlayer():GetRoleStringRaw()]")

	Designer.registerStringSub( "[RP] Job", "%rp_job%", 'DarkRP.getPhrase("salary", DarkRP.formatMoney(lp:getDarkRPVar("salary")), "")')
	Designer.registerStringSub( "[RP] Cash", "%rp_cash%", 'DarkRP.getPhrase("job", lp:getDarkRPVar("job") or "")')
	Designer.registerStringSub( "[RP] Salary", "%rp_salary%", 'DarkRP.getPhrase("wallet", DarkRP.formatMoney(localplayer:getDarkRPVar("money")), "")')

	
	Designer.shapeID = 1;
	Designer.currentLayer = 1;
	Designer.selectedShape = nil
	Designer.selectedShapeData = nil
	Designer.currentAction = Designer.actions.NONE
	
	Designer.gridEnabled = true
	Designer.gridDrawn = true
	Designer.viewLayerOnMove = false
	Designer.opaqueBackground = false
	
	Designer.clipboard = {}
	Designer.fonts = {}
	Designer.runtimeVars = {}
	
	Designer.projectName = "UnnamedProject-" .. Designer.getWritableDate()
	Designer.projectSaved = true
	
	Designer.fileBannedCharacters = {"/", "\\", "?", "|", "<", ">", '"', ":" }
	
	Designer.exampleMat = Material( "scripted/breen_fakemonitor_1" ) 

end

--| 							|--
--| Designer.renderCanvas
--| 							
--| Draws all of the shapes on the canvas
--| 							|--
local selectionColor = 255
local goal = 0
function Designer.renderCanvas( )

	if not Designer.canvasElements then return end
	
	local shape = Designer.getSelectedShape()
	
	-- Begins the drawing process
	for layerNum, layerContents in pairs( Designer.canvasElements ) do
		-- Draw each shape within each layer
		for k, data in pairs( layerContents ) do
			data.color = data.color or color_white
			
			local drawColor = data.color
			
			-- Draw shapes from other layers at a transparency
			if layerNum != Designer.currentLayer then
				drawColor = Designer.colorAlpha( drawColor, 200 )
			end
			
			surface.SetDrawColor( drawColor )
			
			-- Draw rectangles
			if data.type == "rect" then
				if isnumber(data.special[1]) then
					draw.RoundedBox( data.special[1], data.x, data.y, data.w, data.h, data.color )
				elseif data.special[2] then
					surface.SetMaterial( data.special[2] )
					surface.DrawTexturedRect( data.x, data.y, data.w, data.h )
				else
					surface.DrawRect( data.x, data.y, data.w, data.h )
				end
			elseif data.type == "text" then
				--local tbl = {type="text", x=x, y=y, font=font, text=text, color=color, xalign=xAlign}
				
				local drawnText = Designer.formatString( data.text, true ) 
				
				if data.xalign then
					draw.DrawText( drawnText, data.font, data.x, data.y, data.color, data.xalign) 
				else
					
					surface.SetFont( data.font )
					surface.SetTextColor( Designer.unpackColor( data.color ) )
					surface.SetTextPos( data.x, data.y )
					surface.DrawText( drawnText )
				end
				
			end
			
			-- If we have selected a shape, draw helpers
			-- TODO: Put this in a function of its own and add a toggle
			if shape then
				if data.id == shape.id then
					
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
			end
		end
	end
end

--| 							|--
--| Designer.selectShapeAt
--| 							
--| Tries to find a shape at the given x, y coordinates and selects it
--| 							|--
function Designer.selectShapeAt( x, y )

	local shapes = Designer.getShapesAt( x, y )
	
	if not shapes then
		print("No shapes at position")
		return nil 
	end
	
	local len = #shapes
	local id, layer, index
	
	-- Select the shape that is drawing on top of the others in that area
	local data = shapes[ #shapes ]
	id, layer, index = data.id, data.layer, data.index
	
	if not id then 
		print("Didnt select a shape")
		return 
	end

	-- Holds a copy of the selected shape's data
	Designer.selectedShape = Designer.canvasElements[ layer ][ index ] 
	
	-- Get the distance between our mouse and the shape's origin
	-- This is to prevent the shape from unnecessarily moving around by..
	-- moving its origin to the mouse's position
	local shape = Designer.selectedShape
	local offsetX = x - shape.x
	local offsetY = y - shape.y
	
	-- Selection data
	Designer.selectedShapeData = {id=id, layer=layer, index=index,
	offsetX=offsetX, offsetY=offsetY}

	return shape
	
end

--| 							|--
--| Designer.getShapesAt
--| 							
--| Returns all the shapes at a given x, y position (layer strict)
--| 							|--
function Designer.getShapesAt( x, y )
	
	local lay = Designer.currentLayer
	if not Designer.canvasElements[ lay ] then
		--Designer.print( "Attempted to check shape at non-existant layer: " .. tostring(index), "warning" )
		return nil
	end
	
	local foundShapes = {}
	
	-- Iterate through each shape on our layer
	for k, data in pairs( Designer.canvasElements[ lay ] ) do
		-- Text shapes have alignment which mucks with the position
		local x2 = data.alignOffset or 0
			
		if Designer.rectContainsPoint( data, x + x2, y ) then
			table.insert( foundShapes, {id=data.id, layer=lay, index=k} )
		end
	end
	
	if #foundShapes == 0 then 
		print("No found shapes at point")
		return nil
	end
	
	return foundShapes
end

--| 							|--
--| Designer.shapeExistsAt
--| 							
--| 	DEPRECATED: Use Designer.getShapesAt instead
--| I just keep this around in case I need to pull the code for something
--| 							|--
function Designer.shapeExistsAt( px, py, layerStrict )
	
	layerStrict = layerStrict or false
	
	if layerStrict then 
		local index = Designer.currentLayer
		if not Designer.canvasElements[ index ] then
			--Designer.print( "Attempted to check shape at non-existant layer: " .. tostring(index), "warning" )
			return false
		end
		
		-- Iterate through each shape on our layer
		for k, data in pairs( Designer.canvasElements[ index ] ) do
			if Designer.rectContainsPoint( data, px, py ) then
				return data.id, index, k
			end
		end
	else
		-- Iterate through the layers of the canvas
		for layerNum, layerContents in pairs( Designer.canvasElements ) do
			-- Iterate through each shape on that layer
			for k, data in pairs( layerContents ) do
				if Designer.rectContainsPoint( data, px, py ) then
					return data.id, layerNum, k
				end
			end
		end
	end
	
	return false
	
end

--| 							|--
--| Designer.addRect
--| 							
--| Creates a rectangle on the canvas with the given specifics
--| 							|--
function Designer.addRect( x, y, w, h, color, layer, roundness, texture )

	--color = color or color_white
	layer = layer or Designer.currentLayer
	roundness = roundness or 0
	
	if roundness == 0 then roundness = nil end
	
	-- Snap its position 
	x, y = Designer.snapToGrid( x, y )
	
	-- Make sure the layer exists
	Designer.canvasElements[ layer ] = Designer.canvasElements[ layer ] or {}
	
	-- Add it to the drawing table
	local index = #Designer.canvasElements[ layer ] + 1
	Designer.canvasElements[ layer ][ index ] = {
		type="rect", x=x, y=y, w=w, h=h, color=color, special={roundness, texture}, layer=layer, id=Designer.createID()
	} 
	
	Designer.selectShapeAt( x + 2, y + 2 ) 
	Designer.onProjectModified()
	
	return Designer.canvasElements[ layer ][ index ]
end

--| 							|--
--| Designer.addText
--| 							
--| Creates a text box on the canvas with the given specifics
--| 							|--
function Designer.addText( x, y, font, text, color, layer, xAlign )
	
	layer = layer or Designer.currentLayer

	x, y = Designer.snapToGrid( x, y )
	
	Designer.canvasElements[ layer ] = Designer.canvasElements[ layer ] or {}
	
	local index = #Designer.canvasElements[ layer ] + 1
	local id = Designer.createID()
	
	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )
	
	local tbl = {type="text", x=x, y=y, w=w, h=h, font=font, text=text, color=color, xalign=xAlign, id=id}
	
	Designer.canvasElements[ layer ][ index ] = tbl
	
	Designer.selectShapeAt( x + 2, y + 2 ) 
	Designer.onProjectModified()
	
	return Designer.canvasElements[ layer ][ index ]
end

--| 							|--
--| Designer.deleteShape
--| 							
--| Deletes the currently selected shape from the canvas
--| 							|--
function Designer.deleteShape()
	
	local data = Designer.selectedShapeData
	
	if data then 
		Designer.canvasElements[ data.layer ][ data.index ] = nil
	end

	Designer.deselectShape()
	Designer.onProjectModified()
	
end

--| 							|--
--| Designer.deselectShape
--| 							
--| Deselects the currently selected shape
--| 							|--
function Designer.deselectShape()

	Designer.selectedShape = nil
	Designer.selectedShapeData = nil
	Designer.currentAction = Designer.actions.NONE
	
end

--| 							|--
--| Designer.moveShape
--| 							
--| Changes the position of the currently selected shape relative to the canvas
--| 							|--
function Designer.moveShape( x, y )
	
	local data = Designer.selectedShapeData
	
	local layer = data.layer
	local index = data.index
	local dx = data.offsetX
	local dy = data.offsetY
	
	--local shape = Designer.canvasElements[ layer ][ index ]
	local shape = Designer.getSelectedShape()
	
	local newX = x - dx
	local newY = y - dy

	-- Snap new values to the grid
	newX, newY = Designer.snapToGrid( newX, newY )
	
	shape.x = newX
	shape.y = newY
	
	Designer.onProjectModified()
	
end

--| 							|--
--| Designer.resizeShape
--| 							
--| Assumes a handle is selected and resizes the shape according to that handle's movement
--| 							|--
function Designer.resizeShape( x, y )
	
	-- Gets whichever shape handle we are holding onto
	-- They are arranged in this format from [1] to [8]
	-- leftTop, rightTop, rightBottom, leftBottom, midTop, midRight, midBottom, midLeft
	local handleID = Designer.selectedShapeData.handleID
	
	local shape = Designer.getSelectedShape()
	
	-- This code isn't that difficult, just repetitive
	if handleID == 1 then -- Top left handle : change origin
		
		-- Snap our mouse position to the grid
		local newX, newY = Designer.snapToGrid( x, y )
		
		-- Get the end points of the shape
		local xPlusW = shape.x + shape.w
		local yPlusH = shape.y + shape.h
		
		-- Get the new sizes
		local width = xPlusW - newX
		local height = yPlusH - newY
		
		-- Constraints
		if newX > xPlusW then
			width = Designer.gridSize
			newX = shape.x
		end
		
		if newY > yPlusH then
			height = Designer.gridSize
			newY = shape.y
		end
	
		-- Update
		shape.x = newX
		shape.y = newY
		shape.w = width
		shape.h = height
		
	elseif handleID == 2 then -- Top right handle : change origin Y and size

		local newX, newY = Designer.snapToGrid( x, y )
		
		local xPlusW = shape.x + shape.w
		local yPlusH = shape.y + shape.h
		
		local width = newX - shape.x
		local height = yPlusH - newY
		
		-- Constraints
		if width < 0 then
			width = Designer.gridSize	
		end
		
		if newY > yPlusH then
			height = Designer.gridSize
			newY = shape.y
		end
		
		-- Update
		shape.y = newY
		shape.w = width
		shape.h = height
			
	elseif handleID == 3 then -- Right bottom handle : change size
		
		local newX, newY = Designer.snapToGrid( x, y )
		
		local width = newX - shape.x
		local height = newY - shape.y
		
		-- Constraints
		if height < 0 then
			height = Designer.gridSize	
		end
		
		if width < 0 then
			width = Designer.gridSize	
		end
		
		-- Update
		shape.w = width
		shape.h = height
		
	elseif handleID == 4 then -- Bottom left handle : Change originX and size

		local newX, newY = Designer.snapToGrid( x, y )

		local xPlusW = shape.x + shape.w
		local yPlusH = shape.y + shape.h
		
		local width = xPlusW - newX
		local height = newY - shape.y

		-- Constraints
		if height < 0 then
			height = Designer.gridSize	
		end
		
		if newX > xPlusW then
			width = Designer.gridSize
			newX = shape.x
		end
		
		-- Update
		shape.x = newX
		shape.w = width
		shape.h = height
	end
	
	
	-- Middle handles
	if handleID == 5 then -- Top handle
		local _, newY = Designer.snapToGrid( x, y )
		
		local yPlusH = shape.y + shape.h
		
		local height = yPlusH - newY
		
		if newY > yPlusH then
			height = Designer.gridSize
			newY = shape.y
		end
		
		-- Update
		shape.y = newY
		shape.h = height
	elseif handleID == 6 then -- Right handle
		
		local newX, _ = Designer.snapToGrid( x, y )
		
		local width = newX - shape.x

		-- Constraints
		if width < 0 then
			width = Designer.gridSize	
		end
		
		-- Update
		shape.w = width
	elseif handleID == 7 then -- Bottom handle
	
		local _, newY = Designer.snapToGrid( x, y )
		
		local height = newY - shape.y
		
		-- Constraints
		if height < 0 then
			height = Designer.gridSize	
		end
		
		-- Update
		shape.h = height
	elseif handleID == 8 then -- Left handle
		
		local newX, _ = Designer.snapToGrid( x, y )

		local xPlusW = shape.x + shape.w
		
		local width = xPlusW - newX

		-- Constraints
		if newX > xPlusW then
			width = Designer.gridSize
			newX = shape.x
		end
		
		-- Update
		shape.x = newX
		shape.w = width

	end
	
	Designer.onProjectModified()

end

--| 							|--
--| Designer.changeText
--| 							
--| Changes the string inside a text shape
--| 							|--
function Designer.changeText( newString )

	local shape = Designer.getSelectedShape()

	surface.SetFont( shape.font )
	local w, h = surface.GetTextSize( newString )
	
	--shape.oldText = shape.text
	shape.text = newString
	shape.w, shape.h = w, h

	-- I don't think this is necessary
	--Designer.canvasElements[ data.layer ][ data.index ] = shape
	
	Designer.alignText( shape.xalign )
	
	Designer.onProjectModified()
end

--| 							|--
--| Designer.alignText
--| 							
--| Aligns the text within a text shape
--| 							|--
function Designer.alignText( enum )

	local shape = Designer.getSelectedShape()
	
	shape.xalign = enum
	
	-- Since text aligning doesn't change the X coordinate but does change how
	-- the text is rendered, this alignment offset is used to correct the selection box
	if enum == TEXT_ALIGN_CENTER then
		--shape.x = shape.x - shape.w/2
		shape.alignOffset = shape.w/2
	elseif enum == TEXT_ALIGN_RIGHT then
		shape.alignOffset = shape.w
	else
		shape.alignOffset = nil
	end
	
	Designer.onProjectModified()
end

--| 							|--
--| Designer.layerShape
--| 							
--| Moves the shape 'Z' layers on the canvas
--| 							|--
function Designer.layerShape( deltaZ )

	local data = Designer.selectedShapeData
	
	local layer = data.layer
	local index = data.index
	
	local newLayer = deltaZ + layer
	
	if newLayer <= 0 then
		-- No indices of 0
		-- Well you could but Lua isn't much about that and I'd rather not bring that into here
		-- I'll leave it in C where I know to expect it
		Designer.print("Cannot have a layer of 0", "alert")
		return
	end
	
	-- Get the selected shape's data
	local shape = Designer.selectedShape
	
	-- Adjust its layer property
	shape.layer = newLayer
	
	-- Create a new layer if we're moving up from the max
	Designer.canvasElements[ newLayer ] = Designer.canvasElements[ newLayer ] or {}
	
	-- Delete the shape from the old layer and move it
	Designer.canvasElements[ layer ][ index ] = nil
	Designer.canvasElements[ newLayer ][ index ] = shape
	
	if Designer.viewLayerOnMove then
		Designer.currentLayer = newLayer
	end
	
	Designer.onProjectModified()
end

--| 							|--
--| Designer.colorShape
--| 							
--| Changes the currently selected shape's color to the given color structure
--| 							|--
function Designer.colorShape( col )
	
	local data = Designer.selectedShapeData
	local shape = Designer.getSelectedShape()

	shape.oldColor = shape.color
	shape.color = col
	
	Designer.onProjectModified()
end

--| 							|--
--| Designer.materialShape
--| 							
--| Changes a shape's material to the one in the given path
--| 							|--
function Designer.materialShape( strPath )

	local data = Designer.selectedShapeData
	local shape = Designer.getSelectedShape()
	
	shape.special = shape.special or {}
	
	if not strPath then
		shape.special[2] = nil
	else
		shape.oldMaterial = shape.special[2]
		shape.special[2] = Material( strPath )
	end
	
	Designer.onProjectModified()
end

--| 							|--
--| Designer.undoMaterialShape
--| 							
--| Reverts the most recent shape material change
--| 							|--
function Designer.undoMaterialShape( )
	
	local data = Designer.selectedShapeData
	local shape = Designer.getSelectedShape()
	
	if shape.oldMaterial then
		local mat = shape.oldMaterial
		shape.oldMaterial = shape.special[2]
		shape.special[2] = mat
	else
		--Designer.print("No material change to undo on this shape", "notify")
		
		-- Default to color
		shape.special[2] = nil
	end
	
	Designer.onProjectModified()
end

--| 							|--
--| Designer.undoColorChange
--| 							
--| If the shape has had its color changed, this can undo it to the last color
--| 							|--
function Designer.undoColorChange( )
	
	local data = Designer.selectedShapeData
	local shape = Designer.getSelectedShape()
	
	if shape.oldColor then
		local color = shape.oldColor
		shape.oldColor = shape.color
		shape.color = color
	else
		Designer.print("No color change to undo on this shape", "notify")
	end
	
	Designer.onProjectModified()
end

--| 							|--
--| Designer.copyShape
--| 							
--| Copies the shape with the given ID and adds it to the clipboard
--| 							|--
function Designer.copyShape( id )
	
	local data = Designer.selectedShapeData

	if not id then 
		Designer.print("Cannot copy shape that does not exist", "warning")
		return false
	end
	
	for layerNum, layerContents in pairs( Designer.canvasElements ) do
		for k, data in pairs( layerContents ) do
			if data.id == id then
				Designer.print("Copied shape", "notify")
				Designer.clipboard = data
			end
		end
	end
	
	return true
end

--| 							|--
--| Designer.copySelectedShape
--| 							
--| Quick wrapper for buttons that are created on Designer initialize
--| 							|--
function Designer.copySelectedShape()
	local data = Designer.selectedShapeData
	
	if data then
		Designer.copyShape( data.id )
	end

end

--| 							|--
--| Designer.pasteShape
--| 							
--| Creates a new shape from the data on the clipboard at the given x, y coordinates
--| 							|--
function Designer.pasteShape( x, y ) 

	Designer.canvasElements[ Designer.currentLayer ] = Designer.canvasElements[ Designer.currentLayer ] or {}
	
	local data = Designer.clipboard
	local tbl = {}
	
	if not data or #data == 0 then
		Designer.print("Clipboard is empty", "notify")
		return
	end
	
	-- Copies the clipboard table that way we don't modify the original
	table.CopyFromTo( data, tbl )
	
	if not x or not y then
		x, y = Designer.getMousePos()
	end
	
	tbl.x, tbl.y = Designer.snapToGrid( x - tbl.w/2, y - tbl.h/2 )

	if tbl.special and #tbl.special < 0 then
		tbl.special = nil
	end
	
	sType = tbl.type:lower()
	
	-- Gotta keep this updated with each new type, unfortunately
	if sType == "rect" then
		Designer.addRect( tbl.x, tbl.y, tbl.w, tbl.h, tbl.color, tbl.layer, tbl.special )
	elseif sType == "text" then
		Designer.addText( tbl.x, tbl.y, tbl.font, tbl.text, tbl.color, tbl.layer, tbl.xalign )
	else
		Designer.print( "Cannot paste shape ("..tostring(sType)..")", "warning" )
	end
	
end

--| 							|--
--| Designer.openDesigner
--| 							
--| Creates the designer frame
--| 							|--
function Designer.openDesigner()
	
	Designer.initializeVars()
	
	if IsValid(Designer.frame) then
		
		Designer.frame:Close()
		return
	end

	--| 							|--
	--| Create the Derma elements that compromise the designer
	--| 							|--
	Designer.frame = vgui.Create( "DFrame" )
	local frame = Designer.frame
	frame:SetSize( ScrW() * 0.95, ScrH() * 0.95 )
	frame:Center()
	frame:MakePopup()
	-- TODO: Re-open this
	--[[frame.btnClose.DoClick = function( self )
		if not Designer.projectSaved then
			Designer.guiSaveBeforeFunc( function() self:GetParent():Close() end )
		else
			self:GetParent():Close()
		end
	end]]
	
	
	Designer.menuBar = vgui.Create( "DMenuBar", frame )
	Designer.menuBar:DockMargin( -3, -6, -3, 0 ) --corrects Designer.menuBar pos

	-- Create the default grid size
	if not Designer.gridSize then
		local gridRatio = 10 / frame:GetWide()
		Designer.gridSize = gridRatio * frame:GetWide()
		Designer.gridSize = math.Round(Designer.gridSize)
	end

	-- Code moved to cl_interfaces.lua
	Designer.buildMenuBar( Designer.menuBar )
	
	local menuBufferY = Designer.menuBar:GetTall() * 2
	
	-- Creates the canvas in which all shapes live
	Designer.canvas = vgui.Create( "DPanel", frame )
	local canvas = Designer.canvas
	canvas:SetSize( frame:GetWide(), frame:GetTall() - menuBufferY )
	canvas:SetPos( 0, menuBufferY )
	
	-- Determine the maximum length of the lines so that all grid squares have 4 sides
	local wCutOff = frame:GetWide() - (frame:GetWide() % Designer.gridSize)
	-- Shrinks the width so the width to height ratio is the same
	wCutOff = wCutOff - Designer.gridSize*10 
	local hCutOff = frame:GetTall() - menuBufferY - ((frame:GetTall() - menuBufferY) % Designer.gridSize)
	
	-- Resize and realign the canvas
	canvas:SetPos( 0, menuBufferY )
	canvas:SetSize( wCutOff + 1, canvas:GetTall() )
	
	local diff = frame:GetWide() - canvas:GetWide()
	
	-- Resizes the frame to accomidate the canvas and centers it
	frame:SetSize( frame:GetWide() - diff, frame:GetTall() - 5 )
	frame:Center()
	
	-- Gets the ratio of the screen size to the canvas size
	-- Multiply shape size by these to get their screen dimensions
	Designer.canvasConst.wratio = ScrW() / wCutOff
	Designer.canvasConst.hratio = ScrH() / hCutOff


	-- Determine the maximum length of the lines so that all grid squares have 4 sides
	Designer.canvasConst.w = wCutOff
	Designer.canvasConst.h = hCutOff
	
	local oldPaint = frame.Paint
	frame.Paint = function( self, w, h )
		local y = menuBufferY
		
		if Designer.opaqueBackground then
			y = h
		end	
		
		oldPaint(self, w, y)
	end

	frame.Think = function( self )
		
		-- Update the frame title to reflect the project
		local titleStr = "HUD Designer by Exho"
		
		if Designer.projectName then
			titleStr = titleStr .. " - " .. Designer.projectName
		end
		
		if not Designer.projectSaved then
			if not string.find( "*", titleStr ) then
				titleStr = titleStr .. "*"
			end
		end
		
		self:SetTitle( titleStr )
	end
	
	local x, y = canvas:GetPos()
	canvas.Paint = function( self, w, h )
		-- Grid drawing taken from Luabee's poly editor cause laziness
		-- Gotta give credit where credit is due 
		if Designer.gridDrawn then
			for i = 0, wCutOff, Designer.gridSize do
				surface.DrawLine(i, 0, i, hCutOff)
				surface.DrawLine(0, i, wCutOff, i)
			end
		end

		Designer.renderCanvas( )
	end
	
	--| 							|--
	--| Think function overrides for logic within the Derma
	--| 							|--
	canvas.Think = function( self )
		
		local mx, my = Designer.getMousePos( self )
		
		-- If the data doesn't exist, we have deselected our shape
		if !Designer.selectedShapeData then
			Designer.selectedShape = nil
		end
		
		-- If we are holding the left mouse button and focused on the canvas
		if input.IsMouseDown( MOUSE_LEFT ) and Designer.canvasHasFocus() then
			-- If we have a shape currently selected
			if Designer.selectedShapeData then 
				local shape = Designer.selectedShape
				
				-- If the mouse is moving on top of the above conditions
				if Designer.mouseMoving() then
				
					local act = Designer.currentAction
					
					if act == Designer.actions.RESIZE then
						-- Cannot resize a text shape, so don't do that
						if shape.type != "text" then
							Designer.resizeShape( mx, my )
						end
					elseif act == Designer.actions.MOVE then
						Designer.moveShape( mx, my )
					end
				end
			
			end
		else
			Designer.currentAction = Designer.actions.NONE
		end

	end

	
	canvas.OnMousePressed = function( self, code )
		local mx, my = Designer.getMousePos( self )
		
		if code == MOUSE_LEFT then
			
			if Designer.getSelectedShape() then 
				-- We have a shape selected, check to see if we are resizing
				local _, handles = Designer.getSelectionBoxPositions()
				
				-- Check all of the handles
				for k, tbl in ipairs( handles ) do
					-- These tables have integer keys, I usually work with string keys so they need to be converted
					local dimen = Designer.dimensionsIntToString( tbl )
					
					-- The mouse pointer isn't exactly where the sprite says it is, so give the user
					-- a little leeway with their selection just for ease
					local marginOfError = 3
					dimen.x = dimen.x - marginOfError
					dimen.y = dimen.y - marginOfError
					dimen.w = dimen.w + (marginOfError * 2)
					dimen.h = dimen.h + (marginOfError * 2)
					
					-- Check if the mouse is inside one of the boxes
					if Designer.rectContainsPoint( dimen, mx, my ) then
						Designer.currentAction = Designer.actions.RESIZE

						-- Note which box is being used
						Designer.selectedShapeData.handleID = k
						
						return
					end
				end
			end
			
			-- Selects a shape if it exists
			local shape = Designer.selectShapeAt( mx, my )
			
			-- Delay after clicking before changing the current action
			-- HACK: This fixes the shape moving slightly after being clicked on
			timer.Simple( 0.01, function()
				Designer.currentAction = Designer.actions.MOVE
			end)
			
			-- Deselect
			if not shape then
				Designer.deselectShape()
			end
		elseif code == MOUSE_RIGHT then
			-- Selects whatever shape is under the menu at the time
			Designer.selectShapeAt( mx, my )
			
			Designer.guiRightClick( self )
		end
	end
end

-- TODO: Remove this and make an actual concommand
concommand.Add("me", function(ply)
	Designer.openDesigner()
	
	-- TEST CODE: TODO: REMOVE LATER 
	--local myx, myy = Designer.snapToGrid( 45, 45 )
	--Designer.addRect( myx, myy, 300, 300, Color(255, 0, 0), 1, 0)
	--Designer.addText( myx, myy, "DesignerDefault", "Hello World!", color_white )
	--Designer.projectSaved = true
end)
	



