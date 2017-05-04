----// HUD Designer //----
-- Author: Exho
-- Version: 12/10/14

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("cl_util.lua")
	AddCSLuaFile("cl_assorted.lua")
	util.AddNetworkString( "HD_OpenDesigner" )
	resource.AddFile("resource/fonts/roboto_light.tff")
	for k, v in pairs(file.Find( "materials/vgui/hud_designer/*", "GAME" )) do
		resource.AddFile(v)
	end
	
	hook.Add("PlayerSay", "HUDDesignerOpener", function(ply, text)
		text = string.lower(text)
	
		if string.sub(text, 1) == "!hud" then
			net.Start("HD_OpenDesigner")
			net.Send(ply)
		end
	end)
end

--[[ To Do:
* More shapes
* Recreate TTT's HUD in the editor
* Variable based width/height for rectangles
* Font creator
* Copy tool

In Progress:
* Textured rects - Make a texture selector in the Shape Options right click menu
* On-start pop up menu to choose a save
* In-game testing
]]

if CLIENT then
	HD = HD or {}
	local client = LocalPlayer()
	include("cl_util.lua")
	include("cl_assorted.lua")
	
	local showtut = CreateClientConVar("hd_tutorial", "1", true, true)	
	
	local i_grabber = Material( "vgui/hud_designer/grabber.png" )
	
	surface.CreateFont( "HD_Title", {
	font = "Roboto Lt",
	size = 20,
	weight = 500,
	antialias = true,
} )

	surface.CreateFont( "HD_Smaller", {
	font = "Roboto Lt",
	size = 14,
	weight = 500,
	antialias = true,
} )

	surface.CreateFont( "HD_Button", {
	font = "Roboto Lt",
	size = 16,
	weight = 500,
	antialias = true,
} )

	surface.CreateFont( "Arial24", {
	font = "Arial",
	size = 24,
	weight = 500,
	antialias = true,
} )
	
	function HD.OpenDesigner(firstime)
		if HD.DesignerOpen then 
			if IsValid(HD.Frame) then
				HD.Frame:Close()
				if HD.SplashFrame then
					HD.SplashFrame:Close()
				end
				return 
			end
		end
		
		hook.Remove("HUDPaint", "HUD_Designer_Demo")
		
		if showtut:GetBool() then
			HD.OpenTutorial()
			HD.DesignerOpen = false
			HD.Frame = nil
			return
		end
		
		-- // Config //
		HD.UseAutosave = true -- Use autosave?
		HD.AutosaveMinShapes = 5
		HD.AutosaveIncrement = 120
		
		HD.DefaultCorner = 4 -- Rounded corner size
		
		HD.GridEnabled = true -- Use the grid?
		HD.GridSize = (0.010416666666667 * ScrW())
		HD.DefaultCol = Color(41, 128, 185, 255) -- Default shape color
		
		HD.ScalePos = true
		HD.ScaleSize = false
		-- // End config //
		
		HD.Types = {
			"draw.RoundedBox",
			"draw.DrawText",
			"surface.DrawTexturedRect",
			--"surface.CreateFont"
		}
		
		HD.FormatTypes = {
			-- [Display Name] = {Placeholder text, code to use when exporting}
			
			["Health"] = {text="%health%", code="lp:Health()"},
			["Ammo Max"] = {text="%ammomax%", code="wep.Primary.ClipSize or 0"},
			["Ammo Current"] = {text="%ammocur%", code="wep:Clip1() or 0"},
			["Ammo Reserve"] = {text="%ammores%", code="wep:Ammo1() or 0"},
			["Armor"] = {text="%armor%", code="lp:Armor()"},
			["Team"] = {text="%team%", code="lp:Team()"},
			["Name"] = {text="%name%", code="lp:Nick()"},
			
			["TTT - Round State"] = {text="%tttround%", code="L[ roundstate_string[GAMEMODE.round_state] ]"},
			["TTT - Round Time"] = {text="%ttttime%", code='util.SimpleTime(math.max(0, GetGlobalFloat("ttt_round_end", 0) - CurTime()), "%02i:%02i")'},
			["TTT - Role"] = {text="%tttrole%", code="L[lp:GetRoleStringRaw()]"},
			
			["RP - Salary"] = {text="%rpsalary%", code='DarkRP.getPhrase("salary", DarkRP.formatMoney(lp:getDarkRPVar("salary")), "")'},
			["RP - Job"] = {text="%rpjob%", code='DarkRP.getPhrase("job", lp:getDarkRPVar("job") or "")'},
			["RP - Money"] = {text="%rpmoney%", code='DarkRP.getPhrase("wallet", DarkRP.formatMoney(localplayer:getDarkRPVar("money")), "")'},
			
			["None"] = {text="N/A", code="N/A"}, -- Disables the format
		}
		
		HD.Tools = {
			["Info"] = 1,
			["Create"] = 2,
			["Layers"] = 3,
			["Color"] = 4,
			["Select"] = 5,
			["Grid"] = 6,
			["Delete"] = 7,
			["Save"] = 8,
			["Load"] = 9,
			["Export"] = 10,
			["Demo"] = 11,
		}
		
		HD.Boundaries = {} -- Used for clicking
		HD.DrawnObjects = {} -- Used for drawing/exporting
		HD.ShapesOnLayer = {} -- Shape counts per layer
		for k, v in pairs(HD.Types) do
			-- Create the categories
			HD.DrawnObjects[1] = {}
			HD.DrawnObjects[1][v] = {}
		end
		
		HD.SelectedButton = nil
		HD.CurTool = HD.Tools.Box
		HD.CurType = HD.Types[1]
		HD.ShapeID = 1
		HD.ShapeCount = 1
		HD.CurLayer = 1
		HD.Layers = 1
		HD.Cursor = "arrow"
		HD.ProjectName = "Project Name"
		HD.FAKE_TEXTURE = "vgui/nonexistant.png"
		HD.Y_BUFFER = 35
		
		HD.ScaleSize, HD.ScalePos = false
		
		HD.ChosenCol, HD.ColMixer, HD.GridEditor, HD.LoadSel, HD.CreateOpen, HD.CurSizeID = nil
		HD.LayerView, HD.LayerOpen, HD.GridOpen, HD.LoadOpen, HD.ColMixerOpen, HD.CreatePanel = false
		
		HD.Sizing, HD.Moving, HD.ClickColor = false
		HD.CurMovingData = {}
		HD.ShapeOptions = {}
		
		--// Frame
			HD.Frame = vgui.Create("DFrame")
		HD.Frame:SetSize(ScrW(),ScrH())
		HD.Frame:SetPos(0,0)
		HD.Frame:SetTitle("")
		HD.Frame:MakePopup()
		HD.Frame:SetDraggable(false)
		HD.Frame.btnMaxim:SetVisible( false )
		HD.Frame.btnMinim:SetVisible( false )
		HD.Frame.btnClose:SetVisible( false )
		HD.Frame.Paint = function()
			draw.RoundedBox(0, 0, 0, ScrW(), 35, Color(39, 174, 96))
		end
		
		-- My own title and exit button because default derma is gross
			local Title = vgui.Create("DLabel", HD.Frame) 
		Title:SetPos(10, 8) 
		Title:SetSize(30, 0)
		Title:SetColor(Color(255,255,255)) 
		Title:SetFont("HD_Title")
		Title:SetText("HUD Designer") 
		Title:SizeToContents() 
		HD.DesignerOpen = true
		
			local Exit = vgui.Create( "DButton", HD.Frame )
		Exit:SetText( "X" )
		Exit:SetTextColor( Color(255,255,255,255) )
		Exit:SetPos( HD.Frame:GetWide() - 55, 5 ) 
		Exit:SetFont("HD_Button")
		Exit:SetSize( 50, 20 ) 
		Exit.Paint = function()
			draw.RoundedBox( 0, 0, 0, Exit:GetWide(), Exit:GetTall(), Color(200, 79, 79,255) )
		end
		Exit.DoClick = function()
			surface.PlaySound("buttons/button9.wav")
			-- Close the main frame
			HD.Frame:Close()
			
			if HD.SplashFrame then
				HD.SplashFrame:Close()
			end
			
			-- Nuke all the variables
			HD.DesignerOpen = false
			HD.Frame = nil
			HD.CloseOpenInfoPanels()
			HD.Sizing, HD.Moving = false
			HD.CurMovingData = {}
			
			gui.EnableScreenClicker( false )
		end
		
		--// Toolbar
			HD.IconLayout = vgui.Create( "DIconLayout", HD.Frame )
		HD.IconLayout:SetSize( 700, 25 )
		HD.IconLayout:SetPos( ScrW()/2-HD.IconLayout:GetWide()/2, 5 )
		HD.IconLayout:SetSpaceY( 5 )
		HD.IconLayout:SetSpaceX( 5 ) 
		
		HD.ToolbarButtons = {}
		local i = 1
		for i = 1, table.Count(HD.Tools) do 
			local k, v 
			for key, val in pairs(HD.Tools) do
				if val == i then
					k = key
					v = val
				end
			end
				HD.ToolbarButtons[k] = HD.IconLayout:Add( "DButton" ) 
			HD.ToolbarButtons[k]:SetSize( 54, 29 )
			HD.ToolbarButtons[k]:SetText(k)
			HD.ToolbarButtons[k]:SetTextColor(Color(0,0,0))
			HD.ToolbarButtons[k]:SetFont("HD_Button")
			HD.ToolbarButtons[k].DoClick = function()
				surface.PlaySound("buttons/button9.wav")
				HD.SetTool(v,k)
				HD.ToolFunctions(v)
			end
			HD.ToolbarButtons[k].Paint = function()
				if HD.SelectedButton == k then
					draw.RoundedBox(0, 0, 0, HD.ToolbarButtons[k]:GetWide(), HD.ToolbarButtons[k]:GetTall(), Color(200, 200, 200))
				end
				draw.RoundedBox(0, 2, 2, HD.ToolbarButtons[k]:GetWide()-4, HD.ToolbarButtons[k]:GetTall()-4, Color(255, 255, 255))
			end
		end
		HD.IconLayout:SetPos( ScrW()/2-HD.IconLayout:GetWide()/2, 3 )
		
		--// Project Name
		local ix, iy = HD.IconLayout:GetPos()
			HD.ProjectText = vgui.Create( "DTextEntry", HD.Frame )
		HD.ProjectText:SetSize( 90, 25 )
		HD.ProjectText:SetPos( ix - HD.ProjectText:GetWide()-20, 5 )
		HD.ProjectText:SetText( HD.ProjectName )
		HD.ProjectText:SetFont("HD_Button")
		HD.ProjectText.OnChange = function( self, val )
			HD.ProjectName = self:GetText()
		end
		local LastCheck = 0
		HD.ProjectText.Think = function()
			if CurTime() > LastCheck and not HD.ProjectText:IsEditing() then
				HD.ProjectText:SetText( HD.ProjectName )
				LastCheck = CurTime() + 2
			end
		end

		--// Grid
			HD.Canvas = vgui.Create("DPanel", HD.Frame)
		HD.Canvas:SetSize(ScrW()-0, ScrH()-30)
		HD.Canvas:SetPos( 0, HD.Y_BUFFER)
		local NextCheck = 0
		function HD.Canvas:PaintOver(w,h)
			-- Drawing the shapes here
			local i = 1
			for i = 1, HD.Layers do
				HD.DrawnObjects[i] = HD.DrawnObjects[i] or {}
				for class, objects in pairs(HD.DrawnObjects[i]) do
					if class == "draw.RoundedBox" then
						for id, data in pairs(objects) do
							if HD.LayerView then
								local col = nil
								local r,g,b,a = data.color.r, data.color.g, data.color.b, data.color.a
								if i == HD.CurLayer then
									col = Color(r,g,b,a)
								else
									a = math.Clamp(a-100, 100, 255)
									col = Color(r,g,b,a)
								end
								draw.RoundedBox(data.corner, data.x, data.y, data.width, data.height, col)
								draw.DrawText( HD.GetShapeLayer(id) or "", "Trebuchet24", data.x + 5, data.y, Color(255,255,255) )
							else
								draw.RoundedBox(data.corner, data.x, data.y, data.width, data.height, data.color)
							end
						end
					elseif class == "surface.DrawTexturedRect" then
						for id, data in pairs(objects) do
							local color = data.color-- Is our texture colored?
							if color == HD.DefaultCol then color = Color(255,255,255) end -- If not, use white
							
							if type(data.texture) == "IMaterial" then
								surface.SetMaterial( data.texture )
								surface.SetDrawColor( color )
								surface.DrawTexturedRect( data.x, data.y, data.width, data.height )
							else
								surface.SetTexture( data.texture )
								surface.SetDrawColor( color )
								surface.DrawTexturedRect( data.x, data.y, data.width, data.height )
							end
						end
					elseif class == "draw.DrawText" then
						for id, data in pairs(objects) do
							draw.DrawText( data.text, data.font, data.x, data.y, data.color)
						end
					else
					
					end
				end
			end
			
			-- Draws the area where you are "supposed" to be able to drag
			for id, v in pairs(HD.Boundaries) do
				if HD.GetShapeType(id) != "draw.DrawText" and HD.GetShapeLayer(id) == HD.CurLayer then 
					local gs = 20
					local farx, fary = v.farx, v.fary
					local minx, miny = farx-gs, fary-gs
					
					local x, y = minx, miny
					local width, height = farx-minx, fary-miny
					
					surface.SetDrawColor(150,150,150)
					surface.SetMaterial( i_grabber )
					surface.DrawTexturedRect( x+5, y+5, width-10, height-10 )
				end
			end
		end
		HD.Canvas.Paint = function()
			-- Grid drawing taken from Luabee's poly editor
			for i=HD.GridSize, ScrW(), HD.GridSize do
				surface.DrawLine(i, 0, i, ScrH())
				surface.DrawLine(0, i, ScrW(), i)
			end
		end
		HD.Canvas.OnMousePressed = function(self, mc)
			local mx, my = HD.GetMousePos()
			if mc == MOUSE_LEFT then
				local IsIn, id = HD.IsInShape(mx, my)
				local Lay = HD.GetShapeLayer(id)
				local Type = HD.GetShapeType(id)
				
				if HD.ClickColor then -- Grab the color of the current shape
					if IsIn then
						local col = HD.DrawnObjects[Lay][Type][id].color
						HD.Mixer:SetColor(col)
						HD.ChosenCol = col
						
						HD.ClickColor = false
						return
					end
				elseif HD.CurTool == HD.Tools.Color then -- Color shape
					if IsIn then
						local newcolor = HD.ChosenCol
						HD.DrawnObjects[Lay][Type][id].color = newcolor
						return
					end
				elseif HD.CurTool == HD.Tools.Delete then -- Delete shape
					if IsIn then
						HD.DrawnObjects[Lay][Type][id] = nil
						HD.Boundaries[id] = nil
						
						HD.CancelAlter()
						HD.ShapeCount = HD.ShapeCount - 1
						return
					end
				end
				
				-- Close open editor panels
				HD.CloseOpenInfoPanels()

				if IsIn then
					if HD.IsInSize(id, mx, my) then -- Size the current shape
						HD.SetTool(HD.Tools.Select, "Select")
						
						HD.CurMovingData = {}
						HD.Moving = false
					
						local entry = HD.DrawnObjects[Lay][HD.GetShapeType(id)][id]
						if entry then	
							HD.CurSizeID = id
							HD.Sizing = true
						end
					else -- Move the current shape
						HD.SetTool(HD.Tools.Select, "Select")
						
						HD.CurSizeID = nil
						HD.Sizing = false
						
						local bool, id, difx, dify = HD.IsInShape(mx, my)
						HD.CurMovingData = {id=id, x=difx, y=dify}
						HD.Moving = true
					end
				else -- Make sure nothing happens that we dont want to
					HD.CancelAlter()
				end
			elseif mc == MOUSE_RIGHT then
				local IsIn, id = HD.IsInShape(mx, my)
				if not IsIn then return end
				
				HD.SetTool(HD.Tools.Select, "Select")
				HD.OpenShapeSettings(id,mx,my)
			end
		end
		local NextAutosave, NextCheck = CurTime()+30, 0
		HD.Canvas.Think = function(self) -- Think functions for stuff that has to be accurate	
			-- Delayed functions
			if CurTime() > NextCheck then
				-- Autosave
				if HD.UseAutosave and CurTime() > NextAutosave and HD.ShapeCount > HD.AutosaveMinShapes then
					HD.Autosave()
					NextAutosave = CurTime() + HD.AutosaveIncrement
				end
				
				-- Update layers
				HD.DrawnObjects = HD.DrawnObjects or {}
				HD.Layers = table.Count(HD.DrawnObjects)
				
				-- Accurate shapes per layer count
				local i = 1
				for i = 1, HD.Layers do
					local Count = 0
					
					for k, v in pairs(HD.DrawnObjects[i]) do
						Count = Count + table.Count(v) -- Count # of each shape Type
					end
					HD.ShapesOnLayer[i] = Count
				end
				
				NextCheck = CurTime() + 1
			end
			
			-- Grab positions
			local mx, my = HD.GetMousePos()
			local InCanvas = HD.IsInCanvas(mx, my)
			local InShape, id = HD.IsInShape(mx, my)
			
			-- Cursor related stuff
			if not InCanvas then 
				HD.CancelAlter()
				return
			elseif InShape or HD.Moving and input.IsMouseDown( MOUSE_LEFT ) then
				HD.Cursor = "hand"
			else
				HD.Cursor = "arrow"
			end
			HD.Canvas:SetCursor(HD.Cursor)
		
			if HD.Moving and input.IsMouseDown( MOUSE_LEFT ) then
				local newx, newy = mx, my
				if InCanvas then
					local d = HD.CurMovingData
					local id, difx, dify = d.id, d.x, d.y
					local gs = HD.GridSize
					local offx, offy = gs/2, gs*1.5 -- Offsets so the shape wont move when clicked on
					
					newx, newy = math.SnapTo(newx - difx + offx, gs), math.SnapTo(newy - dify - offy, gs)
					
					HD.EditShape(id, {x=newx, y=newy}, "move")
				end
			elseif HD.Sizing and input.IsMouseDown( MOUSE_LEFT ) then
				local id = HD.CurSizeID
				local gs = HD.GridSize
				local entry = HD.Boundaries[id]
				if not entry then return end
				
				local x, y = entry.x, entry.y
				local farx, fary = entry.farx, entry.fary
				local minx, miny = farx-gs, fary-gs
					
				if HD.IsInCanvas then
					mx, my = math.Clamp(mx, x + 5, ScrW()), math.Clamp(my, y + 5, ScrH())

					HD.EditShape(id, {width=mx-x, height=my-y}, "size")
				end
			end
		end
		
		if firstime then -- Open Terms
			-- Invisible panel so clients cannot click the Editor
				local AntiClick = vgui.Create("DFrame")
			AntiClick:SetSize(ScrW(),ScrH())
			AntiClick:SetPos(0,0)
			AntiClick:SetTitle("")
			AntiClick:MakePopup()
			AntiClick:SetDraggable(false)
			AntiClick.btnMaxim:SetVisible( false )
			AntiClick.btnMinim:SetVisible( false )
			AntiClick.btnClose:SetVisible( true )
			AntiClick.Paint = function()
				draw.RoundedBox(0, 0, 0, AntiClick:GetWide(), AntiClick:GetTall(), Color(0,0,0,0))
			end
			
				local Frame = vgui.Create("DFrame", AntiClick)
			Frame:SetSize(300,300)
			Frame:SetPos(ScrW()/2-Frame:GetWide()/2,ScrH()/2-Frame:GetTall()/2)
			Frame:SetTitle("")
			Frame:SetDraggable(false)
			Frame.btnMaxim:SetVisible( false )
			Frame.btnMinim:SetVisible( false )
			Frame.btnClose:SetVisible( false )
			Frame.Paint = function()
				Derma_DrawBackgroundBlur( Frame ) 
				draw.RoundedBox(0, 0, 0, Frame:GetWide(), Frame:GetTall(), Color(39, 174, 96))
			end
			
			-- My own title and exit button because default derma is gross
				local Title = vgui.Create("DLabel", Frame) 
			Title:SetPos(15, 8) 
			Title:SetSize(30, 0)
			Title:SetColor(Color(255,255,255)) 
			Title:SetFont("HD_Title")
			Title:SetText("Terms of use") 
			Title:SizeToContents() 
				local Exit = vgui.Create( "DButton", Frame )
			Exit:SetText( "I accept" )
			Exit:SetTextColor( Color(255,255,255,255) )
			Exit:SetFont("HD_Button")
			Exit:SetSize( 70, 30 ) 
			Exit:SetPos( Frame:GetWide()/2-Exit:GetWide()/2, Frame:GetTall()-Exit:GetTall()-10 ) 
			Exit.Paint = function()
				draw.RoundedBox( 0, 0, 0, Exit:GetWide(), Exit:GetTall(), Color(200, 79, 79,255) )
			end
			Exit.DoClick = function()
				surface.PlaySound("buttons/button9.wav")
				Frame:Close()
				AntiClick:Close()
			end
			
				local Title = vgui.Create("DLabel", Frame) 
			Title:SetPos(10, 30) 
			Title:SetSize(30, 0)
			Title:SetColor(Color(255,255,255)) 
			Title:SetFont("HD_Smaller")
			Title:SetText([[
			1. You are not allowed to sell any scripts you make
				using this because it makes HUD creation very, very
				easy. Just to prevent a large amount of low effort
				scripts being sold.
				
			2. You can distribute HUDs created with this for free
				and you can use them on your personal servers! 
				All I ask is that you include some credit as to 
				how you made your HUD.
				
			3. You can add, remove, or modify the script as
				much as you want. Just please don't reupload
				it anywhere else.
			
			Have fun :)
			]]) 
			Title:SizeToContents() 
		else
			HD.Splash()
		end
	end
	
	local hud = {"CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo"}
	hook.Add( "HUDShouldDraw", "hide hud", function( name )
		if HD.DesignerOpen then
			for k, v in pairs(hud) do
				if name == v then return false end
			end
		end
	end)
end
