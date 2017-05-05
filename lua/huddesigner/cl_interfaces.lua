Designer = Designer or {}

--[[
	Regarding popup panels for editing:
		- Frame close does NOT save changes, revert to original (if not locally saved)
		- Apply button (if visible) will just demo the changes
		- Save button will locally save changes and apply them
		- Undo button will undo the most last change
	

]]

surface.CreateFont( "DesignerDefault", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = true,
	size = 20,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "DesignerDefault18", {
	font = "Arial",
	extended = true,
	size = 18,
	weight = 500,
	antialias = true,
} )

surface.CreateFont( "DesignerDefault26", {
	font = "Arial",
	extended = true,
	size = 26,
	weight = 400,
	antialias = true,
} )

-- This font gets overwritten later but I need to declare it at least once
surface.CreateFont( "DesignerTestFont", {
	font = "Arial",
	extended = true,
	size = 18,
	weight = 500,
	antialias = true,
} )

--| 							|--
--| Designer.guiThinkOverride
--| 							
--| Replacement for a DFrame's think function which keep its on top of
--| other windows no matter what
--| 							|--
function Designer.guiThinkOverride( self )

	if not self:HasFocus() then
		self:MoveToFront()
	end

end

--| 							|--
--| Designer.buildMenuBar
--| 							
--| Creates the DFrame's menu bar for the designer
--| 							|--
function Designer.buildMenuBar( parent )

	local M1 = parent:AddMenu( "File" )
	M1:AddOption( "New", Designer.newProject ):SetImage( "icon16/page_white_go.png" )
	M1:AddOption( "Open", Designer.openProject ):SetImage( "icon16/folder_go.png" )
	M1:AddOption( "Save", Designer.saveProject ):SetImage( "icon16/disk.png" )
	M1:AddOption( "Save As", lambda( Designer.saveProject, false, true, false ) ):SetImage( "icon16/disk.png" )
	M1:AddOption( "Export", Designer.exportProject ):SetImage( "icon16/script.png" )

	local M2 = parent:AddMenu( "Edit" )

	local copyFunc = lambda( Designer.copySelectedShape )
	local pasteFunc = lambda( Designer.pasteShape )

	M2:AddOption( "Copy", copyFunc ):SetImage( "icon16/page_copy.png" )
	M2:AddOption( "Paste", pasteFunc ):SetImage( "icon16/page_paste.png" )
	M2:AddSpacer()
	M2:AddOption( "Color Mixer", Designer.guiColorPicker ):SetImage( "icon16/color_wheel.png" )
	M2:AddOption( "Font Creator", Designer.guiFontEditor ):SetImage( "icon16/font.png" )
	M2:AddSpacer()
	M2:AddOption( "Delete", Designer.deleteShape ):SetImage( "icon16/page_delete.png" )
	local M3 = parent:AddMenu( "View" )
	local pnl = M3:AddOption( "Current layer: " .. tostring(Designer.currentLayer))
	pnl:SetImage( "icon16/layers.png" )
	
	-- Update the text
	pnl.Think = function( self ) 
		self:SetText( "Current layer: " .. tostring(Designer.currentLayer) )
	end
	
	M3:AddSpacer()
	M3:AddOption("Move view up 1 layer", function() Designer.viewLayer( Designer.currentLayer + 1 ) end):SetImage( "icon16/arrow_up.png" )
	M3:AddOption("Move view down 1 layer", function() Designer.viewLayer( Designer.currentLayer - 1 ) end):SetImage( "icon16/arrow_down.png" )

	local M4 = parent:AddMenu( "Options" )
	M4:AddOption( "Open Canvas Settings", Designer.guiCanvasSettings )
	M4:AddSpacer()
	
end

--| 							|--
--| Designer.guiRightClick
--| 							
--| Opens the edit menu activated on a right mouse click on the canvas
--| 							|--
function Designer.guiRightClick( parent )

	-- Create the menu
	Designer.createMenu = vgui.Create( "DMenu", parent )
	local menu = Designer.createMenu
	
	-- TODO: Make these into actually decent looking functions
	-- I need better examples
	local function newRect()
		local x, y = Designer.getCanvasCenter()
		local d = Designer.gridSize
		
		local rand = math.random( d * 4, d * 10 )
		
		local w, h = Designer.snapToGrid( rand, rand )
		
		Designer.addRect( x, y, w, h, color_white, Designer.currentLayer, 0 )
	end
	
	local function newTRect()
	
		local x, y = Designer.getCanvasCenter()
		local d = Designer.gridSize
		
		local rand = math.random( d * 4, d * 10 )
		
		local w, h = Designer.snapToGrid( rand, rand )
		
		Designer.addRect( x, y, w, h, color_white, Designer.currentLayer, nil, Designer.exampleMat )
	end
	
	local function newText()
		local x, y = Designer.getCanvasCenter()
		
		Designer.addText( x, y, "DesignerDefault", "Hello World!", color_black )
	end

	local subMenu = menu:AddSubMenu( "Create" )
		subMenu:AddOption( "Rectangle", newRect ):SetIcon( "icon16/box.png" ) -- dumb
		--subMenu:AddOption( "Texture", newTRect ):SetIcon( "icon16/image.png" ) 
		subMenu:AddOption( "Text", newText ):SetImage( "icon16/textfield_add.png" )
		--subMenu:AddOption( "Sub Option #3" )
	
	menu:AddSpacer()
	
	if Designer.selectedShape then
		
		local subMenu = menu:AddSubMenu( "Layer" )
			subMenu:AddOption( "Current layer: " .. tostring(Designer.currentLayer) ):SetImage( "icon16/layers.png" )
			subMenu:AddSpacer()
			subMenu:AddOption( "Move shape up one (1)", lambda( Designer.layerShape, 1 ) ):SetImage( "icon16/bullet_arrow_up.png" )
			subMenu:AddOption( "Move shape down one (1)", lambda( Designer.layerShape, -1 ) ):SetImage( "icon16/bullet_arrow_down.png" )

		local subMenu = menu:AddSubMenu( "Color" )
			subMenu:AddOption( "Open Color Mixer", lambda( Designer.guiColorPicker ) ):SetImage( "icon16/color_wheel.png" )
			subMenu:AddSpacer()
			subMenu:AddOption( "Set to white", lambda( Designer.colorShape, color_white ) ):SetImage( "icon16/contrast_increase.png" )
			subMenu:AddOption( "Set to black", lambda( Designer.colorShape, color_black ) ):SetImage( "icon16/contrast_decrease.png" )
			subMenu:AddSpacer()
			subMenu:AddOption( "Undo color change", lambda( Designer.undoColorChange ) ):SetImage( "icon16/arrow_undo.png" )
		

		if Designer.selectedShape.type == "text" then
			local subMenu = menu:AddSubMenu( "Text" )
				subMenu:AddOption( "Open Text Editor", Designer.guiTextEditor ):SetImage( "icon16/text_allcaps.png" )
				subMenu:AddOption( "Open Font Creator", Designer.guiFontEditor ):SetImage( "icon16/font.png" )
		else
			local subMenu = menu:AddSubMenu( "Material" )
				subMenu:AddOption( "Open Material Selector", Designer.guiMatSelector ):SetImage( "icon16/picture_edit.png" )
				subMenu:AddSpacer()
				subMenu:AddOption( "Remove Material" , lambda( Designer.materialShape, nil ) ):SetImage( "icon16/picture_delete.png" )
				--subMenu:AddSpacer()
		end
	end
	
	local copyFunc = function() Designer.print( "No shape to copy", "alert" ) end
	local pasteFunc = lambda( Designer.pasteShape )
	if Designer.selectedShape then
		copyFunc = lambda( Designer.copyShape, Designer.selectedShapeData.id )
	end
	
	menu:AddSpacer()
	menu:AddOption( "Copy", copyFunc )
	menu:AddOption( "Paste", pasteFunc )
	
	if Designer.selectedShape then
		menu:AddSpacer()
		menu:AddOption( "Delete", Designer.deleteShape ) 
	end
	
	-- Position the menu
	local x, y = Designer.getMousePos( parent )
	menu:SetPos( x + 5, y )

end

--| 							|--
--| Designer.guiMatSelector
--| 							
--| Opens a menu which can change the material of a shape
--| 							|--
function Designer.guiMatSelector()

	local shape = Designer.getSelectedShape()
	local saved = false
	
	if not shape then
		Designer.print( "Please select a shape before opening the color picker", "warning")
		return
	end
	
	-- Gets the file name of the current material being used by the shape
	-- (if it exists)
	local oldMaterial = shape.special and shape.special[2] and shape.special[2]:GetName()
	
	Designer.materialSelector = vgui.Create( "DFrame" )
	local frame = Designer.materialSelector
	frame:SetSize( 450, 400 )
	frame:Center()
	frame:MakePopup()
	frame:SetTitle( "Open Project" )
	frame.Think = Designer.guiThinkOverride
	frame.OnClose = function( self )
		if !saved then
			Designer.materialShape( oldMaterial ) 
		end
	end

	local selectedPath
		
	local browser = vgui.Create( "DFileBrowser", frame )
	browser:SetSize( 440, 175 )
	browser:SetPos( 5, 30 )

	browser:SetPath( "GAME" ) -- The access path i.e. GAME, LUA, DATA etc.
	browser:SetBaseFolder( "materials/vgui" ) -- The root folder. Currently set to the vgui subfolder for efficiency
	browser:SetOpen( true ) -- Open the tree to show sub-folders
	browser.OnSelect = function( self, path, pnl )
		selectedPath = path
	end
	
	local _, y = browser:GetPos()
	
	local imagePreview = vgui.Create( "DImage", frame )
	imagePreview:SetSize( frame:GetTall()/2 - 15, frame:GetTall()/2 - 15 )
	imagePreview:SetPos( frame:GetWide() - imagePreview:GetWide() - 5, y + browser:GetTall() + 5 )
	-- Sets the preview image to the current material or a checkerboard if it doesn't exist
	imagePreview:SetImage( oldMaterial or "givemethatcheckerboardplease" )
	
	browser.OnSelect = function( self, path, pnl )
		-- Remove bad things which tend to create issues 
		path = string.gsub( path, ".vtf", "" )
		path = string.gsub( path, ".vmt", "" )
		path = string.gsub( path, "materials/", "" )
	
		imagePreview:SetImage( path )
	end
	
	local pnl = vgui.Create( "DPanel", frame )
	pnl:Dock( BOTTOM )
	pnl:SetSize( pnl:GetWide(), 30 )
	pnl.Paint = function( self, w, h ) end
	
	local btn1 = vgui.Create( "DButton", pnl )
	btn1:SetText( "Apply" )
	btn1:SetSize( 75, pnl:GetTall() )
	btn1.DoClick = function( self )
		
		-- This is just a demonstration
		--shape.special[2] = Material( imagePreview:GetImage() )
	
		Designer.materialShape( imagePreview:GetImage() )
		
	end
	
	local btn2 = vgui.Create( "DButton", pnl )
	btn2:SetText( "Save" )
	btn2:SetSize( 75, pnl:GetTall() )
	btn2:SetPos( 80, 0 )
	btn2.DoClick = function( self )
		
		--Designer.materialShape( imagePreview:GetImage() )
		Designer.saveProject( false, false, true )
		
		local parent = pnl:GetParent()
		
		if IsValid( parent ) then
			parent:Remove()
		end

	end
	
	local btn3 = vgui.Create( "DButton", pnl )
	btn3:SetText( "Undo" )
	btn3:SetSize( 75, pnl:GetTall() )
	btn3:SetPos( 150 + 10, 0 )
	btn3.DoClick = function( self )
	
		Designer.undoMaterialShape( )
		
	end

end

--| 							|--
--| Designer.guiColorPicker
--| 							
--| Opens a mixer frame to change the current shape's color
--| 							|--
function Designer.guiColorPicker()
	
	local shape = Designer.getSelectedShape()
	
	if not shape then
		Designer.print( "Please select a shape before opening the color picker", "warning")
		return
	end
	
	local saved = false
	
	local originalShapeColor = shape.color
	local mixer
	
	Designer.colorPicker = vgui.Create( "DFrame", Designer.canvas )
	local frame = Designer.colorPicker
	frame:SetSize( 275, 200 )
	frame:Center()
	frame:MakePopup()
	frame.Think = Designer.guiThinkOverride
	frame.btnClose.DoClick = function( button ) 
		if not saved then
			-- go to church()
			shape.color = originalShapeColor
		end
		
		button:GetParent():Close() 
	end
	
	frame:SetTitle( "Color Mixer" )
	
	mixer = vgui.Create( "DColorMixer", frame )
	mixer:Dock( TOP )
	mixer:SetSize( 275, 125 )
	mixer:SetPalette( false )
	mixer:SetAlphaBar( true )
	mixer:SetWangs( true )
	mixer:SetColor( originalShapeColor )
	mixer.Think = function( self )
		shape.color = self:GetColor()
	end
	
	-- Panel to hold these two buttons for docking ease
	local pnl = vgui.Create( "DPanel", frame )
	pnl:SetSize( frame:GetWide(), 25 )
	pnl:Dock( BOTTOM )
	pnl.Paint = function() end
	
	local btn1 = vgui.Create( "DButton", pnl )
	btn1:SetText( "Undo" )
	btn1:Dock( LEFT )
	btn1:DockMargin( 15, 0, 0, 0 )
	btn1.DoClick = function( self )
		if originalShapeColor != shape.color then
			-- Normal undo within the editor
			shape.color = originalShapeColor
			mixer:SetColor( originalShapeColor )
		else
			-- And then this crazy thing which undoes any color change
			shape.color = shape.oldColor or shape.color
			mixer:SetColor( shape.color ) 
		end
	end
	
	local btn2 = vgui.Create( "DButton", pnl )
	btn2:SetText( "Save" )
	btn2:Dock( RIGHT )
	btn2:DockMargin( 0, 0, 15, 0 )
	btn2.DoClick = function( self )
		
		Designer.colorShape( mixer:GetColor() )
		
		--shape.oldColor = originalShapeColor
		--shape.color = mixer:GetColor()
		
		saved = true
		--frame:Close()
	end

end

--| 							|--
--| Designer.guiTextEditor
--| 							
--|	Opens the text editing interface
--| 							|--
function Designer.guiTextEditor()
	
	local shape = Designer.getSelectedShape()
	local saved = false
	
	if not shape then
		Designer.print( "Please select a shape before opening the text editor", "warning")
		return
	end
	
	local oldText = shape.text
	local oldFont = shape.font

	Designer.textEditor = vgui.Create( "DFrame", Designer.canvas )
	local frame = Designer.textEditor
	frame:SetTitle( "Text Editor" )
	frame:SetSize( 500, 250 )
	frame:Center()
	frame:MakePopup()
	frame.Think = Designer.guiThinkOverride
	frame.btnClose.DoClick = function( button )
		if !saved then
			shape.font = oldFont
			Designer.changeText( oldText )
		end
		
		button:GetParent():Close() 
	end
	
	local leftPnl = vgui.Create( "DPanel", frame )
	leftPnl:Dock( FILL )
	leftPnl:DockPadding( 5, 10, 5, 10 )
	leftPnl:InvalidateParent()
	leftPnl.Paint = function( self, w, h ) end
	
	local rightPnl = vgui.Create( "DPanel", frame )
	rightPnl:Dock( RIGHT )
	rightPnl:DockPadding( 5, 10, 5, 10 )
	rightPnl:SetSize( (frame:GetWide() / 3), rightPnl:GetTall() )
	rightPnl:InvalidateParent()
	rightPnl.Paint = function( self, w, h ) end
	
	local label = vgui.Create( "DLabel", leftPnl )
	label:SetText( "Text to be displayed:" )
	label:Dock( TOP )
	
	local stringEntry = vgui.Create( "DTextEntry", leftPnl )
	stringEntry:SetPos( 5, 5 )
	stringEntry:Dock( TOP )
	stringEntry:SetSize( stringEntry:GetWide(), 25 )
	stringEntry:SetText( shape.text )
	stringEntry.OnChange = function( self )
		Designer.changeText( self:GetText() )
	end
	
	local label = vgui.Create( "DLabel", leftPnl )
	label:SetText( "Font: (MUST be a font created with surface.CreateFont in Lua)" )
	label:Dock( TOP )
	
	local fontEntry = vgui.Create( "DTextEntry", leftPnl )
	fontEntry:Dock( TOP )
	fontEntry:SetSize( stringEntry:GetWide(), 25 )
	fontEntry:SetText( shape.font )
	fontEntry.OnEnter = function( self )
		-- Check to make sure the font actually exists before we modify the canvas
		local succ, err = pcall( function() 
			surface.SetFont( data.font )
		end )
		
		if succ then -- nut?
			shape.font = self:GetText()
			
			-- Using the change text function cause it does most all of the work anyways
			Designer.changeText( shape.text )
		else
			Designer.print( tostring(self:GetText()) .. " is not a valid font!", "warning" )
		end
	end
	
	-- The format selector
	local label = vgui.Create( "DLabel", leftPnl )
	label:SetText( "Format: (Gamemode specific functions) " )
	label:Dock( TOP )
	
	local formatChoice = vgui.Create( "DComboBox", leftPnl )
	formatChoice:Dock( TOP )
	formatChoice:SetSize( formatChoice:GetWide(), 25 )
	formatChoice:SetValue( "Function" )
	
	-- Add each of the string formats
	for k, v in pairs( Designer.stringFormats ) do
		formatChoice:AddChoice( k, v )
	end
	
	formatChoice.OnSelect = function( self, index, val )
		local printName, strFormat = self:GetSelected()
		
		-- Append the formatting placeholder to the text
		local txt = tostring(stringEntry:GetText())
		stringEntry:SetText( txt .. strFormat )
		
		-- Call its OnChange function for continuity
		stringEntry:OnChange()
	end
	
	local label = vgui.Create( "DLabel", rightPnl )
	label:SetText( "X-Alignment" )
	label:Dock( TOP )
	
	local strToEnum = {
		["Left"] = TEXT_ALIGN_LEFT,
		["Center"] = TEXT_ALIGN_CENTER,
		["Right"] = TEXT_ALIGN_RIGHT,
	
	}
	
	-- Figure out what alignment this shape currently has
	local chosenEnum = "Left"
	for k, v in pairs( strToEnum ) do
		if v == shape.xalign then
			chosenEnum = k
		end
	end
	
	local alignChoice = vgui.Create( "DComboBox", rightPnl )
	alignChoice:Dock( TOP )
	alignChoice:SetSize( alignChoice:GetWide(), 25 )
	alignChoice:SetValue( chosenEnum )
	alignChoice:AddChoice( "Left" )
	alignChoice:AddChoice( "Center" )
	alignChoice:AddChoice( "Right" )
	alignChoice.OnSelect = function( self, index, val )
		Designer.alignText( strToEnum[val] )
	end
		
	local btnSave = vgui.Create( "DButton", rightPnl )
	btnSave:SetText( "Save" )
	btnSave:Dock( BOTTOM )
	btnSave:SetSize( 50, 25 )
	btnSave.DoClick = function( self )
		
		saved = true
		Designer.changeText( stringEntry:GetText() )
	
	end

end

--| 							|--
--| Designer.guiFontEditor
--| 							
--| Opens the font creator menu
--| 							|--
function Designer.guiFontEditor()

	Designer.fonts = Designer.fonts or {}

	Designer.fontEditor = vgui.Create( "DFrame", Designer.canvas )
	local frame = Designer.fontEditor
	frame:SetTitle( "Font Creator" )
	frame:SetSize( 500, 250 )
	frame:Center()
	frame:MakePopup()
	frame.Think = Designer.guiThinkOverride
	frame.btnClose.DoClick = function( button ) 
		button:GetParent():Close() 
	end

	local options = vgui.Create( "DScrollPanel", frame )
	options:Dock( FILL )
	options.Paint = function( self, w, h )
		--draw.RoundedBox( 0, 0, 0, w, h, color_black )
	end
	
	local yBuffer = 10;
	local xBuffer = 250;
	local yHalfBuffer = yBuffer / 2
	local yOffset = yBuffer;
	
	local alphabeticSort = function( a,b ) return a < b end
	
	-- Sort our list of fairly safe fonts alphabetically
	local fonts = { "Akbar", "Coolvetica", 
		"Georgia", "Comic Sans MS", "Trebuchet MS", "Impact",
		"Courier New", "Verdana", "Times New Roman", "Arial",
		"Roboto Lt", "Roboto Th", "Roboto"}
	
	-- Add user created fonts
	table.Merge( fonts, Designer.fonts )
	
	table.sort( fonts, alphabeticSort )
	
	-- Create a table of font variables that the user can change
	local checkboxTexts = {
		["Extended Character Range"] = 1,
		["Antialiasing"] = 1,
		["Underline"] = 0, 
		["Italic"] = 0, 
		["Strike Through"] = 0,
		["Symbolic"] = 0,
		["Shadow"] = 0,
		["Additive"] = 0,
		["Outline"] = 0,
	}
	
	-- Stores the checkbox derma elements
	local checkboxes = {}
	
	-- Create a table of font variables that require number input
	local textValues = {
		["Size"] = 22,
		["Weight"] = 500,
		["Blurring"] = 0,
		["Scanlines"] = 0,
	
	}
	
	-- Store those entries (not actually text entries anymore)
	local textEntries = {}

	local label = vgui.Create( "DLabel", options )
	label:SetText("In-Game Font Name: ")
	label:SetPos( xBuffer, yOffset )
	label:SizeToContents()
	
	yOffset = yOffset + label:GetTall() + yHalfBuffer
	
	-- Not to be confused with the the actual font's name
	local fontName = vgui.Create( "DTextEntry", options ) 
	fontName:SetPos( xBuffer, yOffset )
	fontName:SetSize( 150, 25 )
	fontName:SetText( "MyHUDFont" )
	fontName.OnEnter = function( self )
		
	end
	
	yOffset = yOffset + fontName:GetTall() + yHalfBuffer
	
	local fontSelector = nil
	
	-- Creates a new font with the given name from the given values
	local function createFontFromEditor( name )
		surface.CreateFont( name, {
			font = fontSelector:GetValue(), 
			extended = checkboxes["exte"]:GetValue(),
			size = textEntries["size"]:GetValue(),
			weight = textEntries["weig"]:GetValue(),
			blursize = textEntries["blur"]:GetValue(),
			scanlines = textEntries["scan"]:GetValue(),
			antialias = checkboxes["anti"]:GetValue(),
			underline = checkboxes["unde"]:GetValue(),
			italic = checkboxes["ital"]:GetValue(),
			strikeout = checkboxes["stri"]:GetValue(),
			symbol = checkboxes["symb"]:GetValue(),
			shadow = checkboxes["shad"]:GetValue(),
			additive = checkboxes["addi"]:GetValue(),
			outline = checkboxes["outl"]:GetValue(),
		} )
		
		if name != "DesignerTestFont" then
			print("Saved new font", name)
			if not table.HasValue( Designer.fonts, name ) then
				table.insert( Designer.fonts, name )
			end
		end
	end
	
	-- Helper function which just updates the current test font
	local function updateFont()
		print("Updating font")

		createFontFromEditor( "DesignerTestFont" )
	end
	
	
	-- Manually create the font name override combobox
	local label = vgui.Create( "DLabel", options )
	label:SetText("Font Name:")
	label:SetPos( xBuffer, yOffset )
	label:SizeToContents()
	
	yOffset = yOffset + label:GetTall() + yHalfBuffer
	
	fontSelector = vgui.Create( "DComboBox", options )
	fontSelector:SetPos( xBuffer, yOffset )
	fontSelector:SetSize( 125, 25 )
	fontSelector:SetValue( "Arial" )
	fontSelector.OnSelect = function( self, index, value )
		print("Update", value)
		updateFont()
	end
	
	-- Add all the fonts to the selector
	for k, v in pairs( fonts ) do
		fontSelector:AddChoice( v )
	end

	yOffset = yOffset + fontSelector:GetTall() + yHalfBuffer
	
	-- Create the text entry boxes
	for k, v in pairs( textValues ) do
		
		local label = vgui.Create( "DLabel", options )
		label:SetText("Font " .. tostring(k))
		label:SetPos( xBuffer, yOffset )
		label:SizeToContents()
		
		yOffset = yOffset + label:GetTall() + yHalfBuffer
		
		local textEntry = vgui.Create( "DNumberWang", options ) 
		textEntry:SetPos( xBuffer, yOffset )
		textEntry:SetSize( 150, 25 )
		textEntry:SetText( v )
		textEntry:SetMinMax( 0, 9999 )
		textEntry.OnValueChanged = function( self )
			print("Update", "WANG")
			updateFont()
		end
		
		-- Store references to these elements by the first 4 letters of their text
		textEntries[string.sub( k:lower(), 1, 4 )] = textEntry
		yOffset = yOffset + textEntry:GetTall() + yHalfBuffer
	end
	
	-- Create the check boxes
	for txt, val in pairs( checkboxTexts ) do
		
		local checkboxLabel = vgui.Create( "DCheckBoxLabel", options )
		checkboxLabel:SetPos( xBuffer, yOffset )
		checkboxLabel:SetText( txt )	
		checkboxLabel:SetValue( val )
		checkboxLabel:SizeToContents()	
		checkboxLabel.OnChange = function( self )
			updateFont()
		end
		
		-- Store references to these elements by the first 4 letters of their text
		checkboxes[string.sub( txt:lower(), 1, 4 )] = checkboxLabel
		yOffset = yOffset + checkboxLabel:GetTall() + yHalfBuffer
	end
	
	local str1 = "The fox does the things 123"
	local str2 = "Its ZEE not ZED, Jesus..."
	
	local examplePanel = vgui.Create( "DPanel", frame )
	examplePanel:SetPos( 5, 25 )
	examplePanel:SetSize( frame:GetWide()/2.2, frame:GetTall() - 75 )
	examplePanel.Paint = function( self, w, h )
		surface.SetFont( "DesignerTestFont" )
		surface.SetTextColor( 255, 255, 255, 255 )
		surface.SetTextPos( 5, 5 )
		surface.DrawText( str1 )
		
		local _, h = surface.GetTextSize( str1 )
		
		surface.SetTextPos( 5, 10 + h )
		surface.DrawText( str2 )
	end
	examplePanel.Think = function( self )
		-- Bad idea, occasionally causes crashes
		-- Generally just inefficient programming
		--updateFont()
	end
	
	local createFont = vgui.Create( "DButton", frame )
	createFont:SetSize( 75, 25 )
	createFont:SetPos( 10, frame:GetTall() - createFont:GetTall() - 10 )
	createFont:SetText( "Create" )
	createFont.DoClick = function( self )
	
		-- Gets the name of the user-created font
		local nombreDeFuente = fontName:GetText()
		
		Designer.print( "Created font under name: "..nombreDeFuente, "notify" )
		createFontFromEditor( nombreDeFuente )
	end
end

--| 							|--
--| Designer.guiProjectNameMenu
--| 							
--| Opens a menu which asks for a name for the given project
--| 							|--
function Designer.guiProjectNameMenu()
	
	Designer.guiNamePrompt = vgui.Create( "DFrame", Designer.canvas )
	local frame = Designer.guiNamePrompt
	frame:SetSize( 300, 125 )
	frame:Center()
	frame:MakePopup()
	frame:SetTitle( "Project Name" )
	frame.Think = Designer.guiThinkOverride
	
	local label = vgui.Create( "DLabel", frame )
	label:SetText( "Please enter a name for this project: " )
	label:Dock( TOP )
	
	local availablePic, availableLbl
	
	local function isFileNameValid( str )
		local fileNameInvalid = Designer.sanitizeFilename( str ) != str
		local fileAlreadyExists = file.Exists( "hud_designer/"..str..".txt", "DATA" )
		
		return !fileAlreadyExists and !fileNameInvalid
	end
	
	local stringEntry = vgui.Create( "DTextEntry", frame )
	stringEntry:SetPos( 5, 5 )
	stringEntry:Dock( TOP )
	stringEntry:SetSize( stringEntry:GetWide(), 25 )
	stringEntry:SetText( Designer.projectName )
	stringEntry.OnChange = function( self )
		--Designer.changeText( self:GetText() )
		
		local str = self:GetText()
		
		if isFileNameValid( str ) then
			availablePic:SetImage( "icon16/accept.png" )
			availableLbl:SetText( "File name available" )
		else
			availablePic:SetImage( "icon16/delete.png" )
			availableLbl:SetText( "Please choose a different file name" )
		end
		
		availableLbl:SizeToContents()
	end
	
	local x, _ = stringEntry:GetPos()
	
	availablePic = vgui.Create( "DImage", frame )
	availablePic:SetSize( 16, 16 )
	availablePic:SetPos( x, frame:GetTall() - availablePic:GetTall() * 2 - 10 )
	availablePic:SetImage( "icon16/accept.png" )
	
	local _, y = availablePic:GetPos()
	
	availableLbl = vgui.Create( "DLabel", frame )
	availableLbl:SetText( "" )
	availableLbl:SetPos( x + availablePic:GetWide(), y )
	
	local btn2 = vgui.Create( "DButton", frame )
	btn2:SetText( "Save" )
	btn2:SetSize( 60, 30 )
	btn2:SetPos( frame:GetWide() - btn2:GetWide() - 10, frame:GetTall() - btn2:GetTall() - 10 )
	btn2.DoClick = function( self )
		local str = stringEntry:GetText()
		
		if isFileNameValid( str ) then
			-- Save the project, change its name, and close the prompt
			Designer.projectName = str
			Designer.onProjectModified()
			btn2:GetParent():Close()
			Designer.saveProject( false, false, false )
		end
	end
	
	stringEntry.OnEnter = function( self )
		btn2:DoClick( btn2 )
	end
end

--| 							|--
--| Designer.guiSaveBeforeFunc
--| 							
--| Prompts the user to save their changes before continuing
--| 							|--
function Designer.guiSaveBeforeFunc( func )

	if Designer.projectSaved then
		print("Why are you asking to save the project when its already saved?")
	end

	if IsValid( Designer.guiSavePrompt ) then
		
		Designer.guiSavePrompt:Close()
		
	end	
	
	local function closeAndExecute()
		Designer.guiSavePrompt:Close()
		func()
	end

	Designer.guiSavePrompt = vgui.Create( "DFrame", Designer.canvas )
	local frame = Designer.guiSavePrompt
	frame:SetSize( 300, 125 )
	frame:Center()
	frame:MakePopup()
	frame:SetTitle( "HUD Designer" )
	frame.Think = Designer.guiThinkOverride
	
	local label = vgui.Create( "DLabel", frame )
	label:SetText( "Are you sure?" )
	label:SetTextColor( color_white )
	label:SetFont( "DesignerDefault26" )
	label:SizeToContents()
	label:SetPos( frame:GetWide()/2 - label:GetWide()/2, 35 )
	
	local label2 = vgui.Create( "DLabel", frame )
	label2:SetText( "Unsaved changes will be lost" )
	label2:SizeToContents()
	label2:SetPos( frame:GetWide()/2 - label2:GetWide()/2, 60 )

	local pnlButtons = vgui.Create( "DPanel", frame )
	pnlButtons:Dock( BOTTOM )
	pnlButtons:SetSize( pnlButtons:GetWide(), 30 )
	pnlButtons.Paint = function( self, w, h ) end
	
	local btn1 = vgui.Create( "DButton", pnlButtons )
	btn1:SetText( "Yes" )
	btn1:Dock( LEFT )
	btn1:DockMargin( 15, 0, 0, 0 )
	btn1.DoClick = function( self )
		closeAndExecute()
	end

	local btn2 = vgui.Create( "DButton", pnlButtons )
	btn2:SetText( "No" )
	btn2:Dock( RIGHT )
	btn2:DockMargin( 0, 0, 15, 0 )
	btn2.DoClick = function( self )
		Designer.guiSavePrompt:Close()
	end
	
	local btn3 = vgui.Create( "DButton", pnlButtons )
	btn3:SetText( "Save First" )
	btn3:Dock( FILL )
	btn3:DockMargin( 20, 0, 20, 0 )
	btn3.DoClick = function( self )
		Designer.saveProject( false, Designer.projectName == nil, false, closeAndExecute )
	end
end

--| 							|--
--| Designer.guiOpenProject
--| 							
--| Opens a saved project (with a save current project prompt)
--| 							|--
function Designer.guiOpenProject()
	
	Designer.projectViewer = vgui.Create( "DFrame" )
	local frame = Designer.projectViewer
	frame:SetSize( 450, 250 )
	frame:Center()
	frame:MakePopup()
	frame:SetTitle( "Open Project" )
	frame.Think = Designer.guiThinkOverride

	local selectedPath
		
	local browser = vgui.Create( "DFileBrowser", frame )
	browser:Dock( FILL )

	browser:SetPath( "DATA" ) -- The access path i.e. GAME, LUA, DATA etc.
	browser:SetBaseFolder( "hud_designer" ) -- The root folder
	browser:SetOpen( true ) -- Open the tree to show sub-folders
	browser:SetCurrentFolder( "saves" ) -- Show files from persist
	browser.OnSelect = function( self, path, pnl )
		selectedPath = path
	end
	
	local pnl = vgui.Create( "DPanel", frame )
	pnl:Dock( BOTTOM )
	pnl:SetSize( pnl:GetWide(), 30 )
	pnl:InvalidateParent( true )
	pnl.Paint = function( self, w, h ) end
	
	local btn1 = vgui.Create( "DButton", pnl )
	btn1:SetText( "Load" )
	btn1:SetSize( 50, pnl:GetTall() )
	btn1:Dock( FILL )
	btn1.DoClick = function( self )
		print(selectedPath)
		
		-- TODO: Check to make sure they don't open any exported files
		
		-- Creates a small function to load the given canvas from the browser path
		local f = lambda( Designer.loadCanvasFromFile, selectedPath )
		
		local dPanel = self:GetParent()
		local dFrame = dPanel:GetParent()
		dFrame:Close()
		
		-- TODO: Don't close the selection panel until they have chosen to load a save
		
		Designer.guiSaveBeforeFunc( f )
	end

end


--| 							|--
--| Designer.guiCanvasSettings
--| 							
--| Allows changing of Designer convars
--| 							|--
function Designer.guiCanvasSettings()
	
	--Designer.gridEnabled = !Designer.gridEnabled end )
	--Designer.gridDrawn = !Designer.gridDrawn end )
	--Designer.opaqueBackground = !Designer.opaqueBackground end )
	
	Designer.deselectShape()
	
	Designer.gridSettings = vgui.Create( "DFrame", Designer.canvas )
	local frame = Designer.gridSettings
	frame:SetSize( 300, 200 )
	frame:Center()
	frame:MakePopup()
	frame:SetTitle( "Canvas Settings" )
	frame.Think = Designer.guiThinkOverride
	
	local pnl = vgui.Create( "DScrollPanel", frame )
	pnl:Dock( FILL )
	pnl:DockPadding( 5, 10, 5, 10 )
	pnl:InvalidateParent()
	pnl.Paint = function( self, w, h ) end
	
	-- Various Designer values which will be modified inside this menu
	local booleans = {
		["Grid Enabled"] = "gridEnabled",
		["Grid Drawn"] = "gridDrawn",
		["Opaque Background"] = "opaqueBackground",
		["Change Layer on Layer Movement"] = "viewLayerOnMove",
	}
	
	for text, setting in pairs( booleans ) do

		local val = Designer[setting]
		
		local checkboxLabel = vgui.Create( "DCheckBoxLabel", pnl )
		checkboxLabel:Dock( TOP )
		checkboxLabel:SetText( text )	
		checkboxLabel:SetValue( val )
		checkboxLabel:SizeToContents()	
		checkboxLabel:DockMargin( 5, 5, 0, 0 )
		checkboxLabel.OnChange = function( self )
			Designer[setting] = self:GetChecked()
		end
	end
	
	--[[local checkboxLabel = vgui.Create( "DCheckBoxLabel", pnl )
	checkboxLabel:Dock( TOP )
	checkboxLabel:SetText( "Grid Enabled" )	
	checkboxLabel:SetValue( Designer.gridEnabled )
	checkboxLabel:SizeToContents()	
	checkboxLabel.OnChange = function( self )
		Designer.gridEnabled = self:GetChecked()
	end]]
	
end
