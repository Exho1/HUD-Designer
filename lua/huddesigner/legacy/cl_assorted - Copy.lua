if CLIENT then
	-- A whole lot of derma
	
	HD = HD or {}
	local client = LocalPlayer()
	
	--// Tool functions 
	function HD.ToolFunctions(num)
		if num == HD.Tools.Create then -- Create shape
			if HD.CreateOpen then 
				HD.SetTool()
				HD.CreatePanel:SetVisible(false) HD.CreateOpen = false HD.CreatePanel = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Create
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
			local YMod = 0
			if #HD.Types > 3 then YMod = 55 end
			
				HD.CreatePanel = vgui.Create("DPanel", HD.Frame)
			HD.CreatePanel:SetSize(180, 70 + YMod)
			HD.CreatePanel:SetPos(px-(HD.CreatePanel:GetWide()/4), 40)
			HD.CreatePanel.Paint = function()
				local self = HD.CreatePanel
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
				local CurLay = vgui.Create("DLabel", HD.CreatePanel)
			CurLay:SetPos(35, 5) 
			CurLay:SetColor(Color(255,255,255)) 
			CurLay:SetFont("HD_Smaller")
			CurLay:SetText("")
			CurLay:SizeToContents() 
			
				local ShapeLayout = vgui.Create( "DIconLayout", HD.CreatePanel )
			ShapeLayout:SetSize( HD.CreatePanel:GetSize() )
			ShapeLayout:SetPos( 10, 10 )
			ShapeLayout:SetSpaceY( 5 )
			ShapeLayout:SetSpaceX( 5 ) 
				
			local i = 1
			local FakeTexture = Material( HD.FAKE_TEXTURE )
			local Count = 0 
			for i = 1, #HD.Types do	
				local ToDraw = HD.Types[i]
				
					local ShapeType = vgui.Create("DButton", ShapeLayout)
				ShapeType:SetSize(50, 50)
				ShapeType:SetTextColor(Color(255,255,255))
				ShapeType:SetFont("HD_Smaller")
				ShapeType:SetText("")
				ShapeType:SetTooltip(ToDraw)
				ShapeType.Paint = function()
					draw.RoundedBox(0, 0, 0, ShapeType:GetWide(), ShapeType:GetTall(), Color(255,255,255,255))
					
					if ToDraw == "draw.RoundedBox" then
						draw.RoundedBox(8, 5, 5, 40, 40, Color(90,90,90,255))
					elseif ToDraw == "draw.DrawText" then
						draw.DrawText( "TEXT", "HD_Title", 5, 15, Color(90,90,90,255))
					elseif ToDraw == "surface.DrawTexturedRect" then
						surface.SetMaterial( FakeTexture )
						surface.SetDrawColor(255,255,255)
						surface.DrawTexturedRect( 5, 5, 40, 40 )
					elseif ToDraw == "surface.CreateFont" then
						draw.DrawText( "Ff", "HD_Title", 16, 15, Color(90,90,90,255))
					else
					
					end
				end
				ShapeType.DoClick = function()
					surface.PlaySound("buttons/button9.wav")
					HD.SetType( ToDraw )
					
					if ToDraw == "draw.DrawText" then
						local font = "Arial24"
						local text = "Sample Text"
						local width, height = HD.GetTextSize(text, font)
						local x, y = HD.Canvas:GetWide()/2 - width/2, HD.Canvas:GetTall()/2 - height/2
						
						HD.AddText(HD.ShapeID, x, y, text, font, color, HD.CurLayer)
					elseif ToDraw == "draw.RoundedBox" then
						local width = 200
						local height = 200
						local x, y = HD.Canvas:GetWide()/2-width/2, HD.Canvas:GetTall()/2-height/2
						
						HD.AddShape(HD.ShapeID, x, y, width, height, HD.ChosenCol, {corner=4}, HD.CurLayer)
					elseif ToDraw == "surface.DrawTexturedRect" then
						local width = 200
						local height = 200
						local x, y = HD.Canvas:GetWide()/2-width/2, HD.Canvas:GetTall()/2-height/2
						local color = HD.ChosenCol
						
						if color == HD.DefaultCol then color = Color(255,255,255) end
						
						HD.AddShape(HD.ShapeID, x, y, width, height, color, {texture=FakeTexture}, HD.CurLayer)
					elseif ToDraw == "surface.CreateFont" then
						HD.FontCreator()
					else
					
					end
					
					HD.SetTool(HD.Tools.Select, "Select")
					HD.CreatePanel:SetVisible(false) HD.CreateOpen = false HD.CreatePanel = nil 
				end
				Count = Count + 1
				if Count % 3 == 0 and Count > 3 then
					local width, height = HD.CreatePanel:GetSize()
					HD.CreatePanel:SetSize(180, height + 55 )
				end	
			end
			HD.CreateOpen = true
		elseif num == HD.Tools.Demo then

			-- Send all of the drawn shape data to a HUDPaint hook
			hook.Add("HUDPaint", "HUD_Designer_Demo", function()
				draw.DrawText( "HUD Designer - Demo (WIP)", "HD_Title", 11, 11, Color(255,255,255))
				draw.DrawText( "HUD Designer - Demo (WIP)", "HD_Title", 10, 10, Color(0,0,0))
				
				local i = 1
				for i = 1, HD.Layers do
					HD.DrawnObjects[i] = HD.DrawnObjects[i] or {}
					for class, objects in pairs(HD.DrawnObjects[i]) do
						if class == "draw.RoundedBox" then
							for id, data in pairs(objects) do
								draw.RoundedBox(data.corner, data.x, data.y + HD.Y_BUFFER, data.width, data.height, data.color)
							end
						elseif class == "surface.DrawTexturedRect" then
							for id, data in pairs(objects) do
								local color = data.color-- Is our texture colored?
								if color == HD.DefaultCol then color = Color(255,255,255) end -- If not, use white
								
								if type(data.texture) == "IMaterial" then
									surface.SetMaterial( data.texture )
									surface.SetDrawColor( color )
									surface.DrawTexturedRect( data.x, data.y + HD.Y_BUFFER, data.width, data.height )
								else
									surface.SetTexture( data.texture )
									surface.SetDrawColor( color )
									surface.DrawTexturedRect( data.x, data.y + HD.Y_BUFFER, data.width, data.height )
								end
							end
						elseif class == "draw.DrawText" then
							for id, data in pairs(objects) do
								draw.DrawText( data.text, data.font, data.x, data.y + HD.Y_BUFFER, data.color)
							end
						else
						
						end
					end
				end
			end)
			
			HD.Frame:Close()
			chat.AddText( Color(39, 174, 96), "[HD]", Color(255,255,255), "Entered 'DEMO' mode! Type !hud in chat to reopen the menu")
		elseif num == HD.Tools.Color then -- Open color mixer panel
			HD.SetTool(HD.Tools.Color, "Color")
			
			if HD.ColMixerOpen then 
				HD.SetTool(nil)
				HD.ColMixer:SetVisible(false) HD.ColMixerOpen = false HD.ColMixer = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Color -- Parent related math
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
				HD.ColMixer = vgui.Create("DPanel", HD.Frame)
			HD.ColMixer:SetSize(260, 240)
			HD.ColMixer:SetPos(px-HD.ColMixer:GetWide()/4,40)
			HD.ColMixer.Paint = function()
				local self = HD.ColMixer
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
				HD.Mixer = vgui.Create( "DColorMixer", HD.ColMixer )
			HD.Mixer:SetSize(250, 230)
			HD.Mixer:SetPos(5, 5)
			HD.Mixer:SetPalette( false )
			HD.Mixer:SetAlphaBar( true ) 	
			HD.Mixer:SetWangs( true )
			HD.Mixer:SetColor( HD.ChosenCol or HD.DefaultCol )
			HD.Mixer.Think = function()
				HD.ChosenCol = HD.Mixer:GetColor()
			end
			
				local Picker = vgui.Create("DButton", HD.ColMixer)
			Picker:SetSize(50, 25)
			Picker:SetPos(HD.ColMixer:GetWide()-Picker:GetWide()-5, HD.ColMixer:GetTall()-Picker:GetTall()-20)
			Picker:SetTextColor(Color(0,0,0))
			Picker:SetTooltip("Click on a shape to use its color")
			Picker:SetText("Picker")
			Picker.DoClick = function()
				HD.ClickColor = true
			end
			
			HD.ColMixerOpen = true
		elseif num == HD.Tools.Grid then -- Open grid changing panel
			if HD.GridOpen then 
				HD.SetTool(nil)
				HD.GridEditor:SetVisible(false) HD.GridOpen = false HD.GridEditor = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Grid
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
				HD.GridEditor = vgui.Create("DPanel", HD.Frame)
			HD.GridEditor:SetSize(80, 65)
			HD.GridEditor:SetPos(px-(HD.GridEditor:GetWide()/4), 40)
			HD.GridEditor.Paint = function()
				local self = HD.GridEditor
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
				local GridEnabler = vgui.Create( "DCheckBoxLabel", HD.GridEditor )
			GridEnabler:SetPos( 5, 40 )
			GridEnabler:SetText( "Enabled" )
			GridEnabler:SetValue( HD.GridEnabled )	
			GridEnabler:SizeToContents()
			GridEnabler.OnChange = function( self, val )
				HD.GridEnabled = val
			end
			
				local Number = vgui.Create( "DNumberWang", HD.GridEditor )
			Number:SetDecimals( 0 )
			Number:SetMinMax( 2, 50 )
			Number:SetValue( HD.GridSize )
			Number:SetPos(5, 5)
			Number:SetSize(70, 25)
			Number.Think = function()
				if Number:GetValue() >= 2 and Number:GetValue() <= 50 then
					-- Gotta make sure that the grid can NEVER be too crazy otherwise your game crashes
					HD.GridSize = Number:GetValue()
				end
			end
			
			-- Custom button click functions cause control freak
			Number.Up.DoClick = function( button, mcode ) Number:SetValue( math.Clamp(Number:GetValue() + 2,2,50) ) end
			Number.Down.DoClick = function( button, mcode ) Number:SetValue( math.Clamp(Number:GetValue() - 2,2,50) ) end
			
			HD.GridOpen = true
		elseif num == HD.Tools.Layers then
			if HD.LayerOpen then 
				HD.SetTool(nil)
				HD.LayerSel:SetVisible(false) HD.LayerOpen = false HD.LayerView = false HD.LayerSel = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Layers
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
			local SizeAlter = 1
			if HD.Layers > 2 then SizeAlter = 2 end
			
				HD.LayerSel = vgui.Create("DScrollPanel", HD.Frame)
			HD.LayerSel:SetSize(180, 95*SizeAlter)
			HD.LayerSel:SetPos(px-(HD.LayerSel:GetWide()/4), 40)
			HD.LayerSel.Paint = function()
				local self = HD.LayerSel
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
				local CurLay = vgui.Create("DLabel", HD.LayerSel)
			CurLay:SetPos(35, 5) 
			CurLay:SetColor(Color(255,255,255)) 
			CurLay:SetFont("HD_Smaller")
			CurLay:SetText("Current Layer: "..HD.CurLayer)
			CurLay:SizeToContents() 
			CurLay.Think = function()
				CurLay:SetText("Current Layer: "..HD.CurLayer)
			end
			
			local i = 1
			local YBuffer = 30
			local BarBuffer = 15
			
			local Count = {}
			
			for i = 1, HD.Layers do	
				Count[i] = 0
					local Layer = vgui.Create("DButton", HD.LayerSel)
				Layer:SetPos(10, YBuffer)
				Layer:SetSize(HD.LayerSel:GetWide()-20-BarBuffer, 50)
				Layer:SetTextColor(Color(255,255,255))
				Layer:SetFont("HD_Smaller")
				Layer.Paint = function()
					local col = Color(90,90,90, 200)
					if Count[i] == 0 then col.a = 100 end
					if HD.CurLayer == i then col.a = 255 else col.a = 200 end
					draw.RoundedBox(0, 0, 0, Layer:GetWide(), Layer:GetTall(), col)
				end
				Layer.Think = function()
					if Count[i] == nil then Count[i] = 0 end
					Count[i] = HD.ShapesOnLayer[i]
					Layer:SetText("Layer: "..i.." Shapes: "..tostring(Count[i]))
				end
				Layer.DoClick = function()
					surface.PlaySound("buttons/button9.wav")
					HD.CurLayer = i
					HD.LayerView = true
				end
				
				YBuffer = YBuffer + Layer:GetTall() + 20
			end
			
				local NewLayer = vgui.Create("DButton", HD.LayerSel)
			NewLayer:SetPos(10, YBuffer)
			NewLayer:SetSize(HD.LayerSel:GetWide()-20-BarBuffer, 50)
			NewLayer:SetTextColor(Color(255,255,255))
			NewLayer:SetText("Add Layer")
			NewLayer:SetFont("HD_Smaller")
			NewLayer.Paint = function()
				local col = Color(90,90,90, 255)
				draw.RoundedBox(0, 0, 0, NewLayer:GetWide(), NewLayer:GetTall(), col)
			end
			NewLayer.DoClick = function()
				surface.PlaySound("buttons/button9.wav")
				HD.Layers = HD.Layers + 1
				HD.CurLayer = HD.Layers
				
				local i = 1
				for i = 1, HD.Layers do
					for k, v in pairs(HD.Tools) do
						HD.DrawnObjects[i] = HD.DrawnObjects[i] or {}
						HD.DrawnObjects[i][v] = HD.DrawnObjects[i][v] or {}
					end
				end
				
				HD.LayerSel:SetVisible(false) HD.LayerOpen = false HD.LayerView = false HD.LayerSel = nil 
				HD.ToolFunctions(HD.Tools.Layers)
			end
			
			HD.LayerOpen = true
		elseif num == HD.Tools.Info then
			if HD.InfoOpen then
				HD.SetTool(nil)
				HD.InfoBar:SetVisible(false) HD.InfoOpen = false HD.InfoBar = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Info -- Parent related math
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
				HD.InfoBar = vgui.Create("DPanel", HD.Frame)
			HD.InfoBar:SetSize(120, 150)
			HD.InfoBar:SetPos(px-HD.InfoBar:GetWide()/4,40)
			HD.InfoBar.Paint = function()
				local self = HD.InfoBar
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
				draw.RoundedBox(0, 4, 4, self:GetWide()-8, self:GetTall()-8, Color(90, 90, 90))
			end
			
				local Title = vgui.Create("DLabel", HD.InfoBar)
			Title:SetPos(25, 5) 
			Title:SetColor(Color(255,255,255)) 
			Title:SetFont("HD_Smaller")
			Title:SetText("Information")
			Title:SizeToContents() 
			
				local L_CurLay = vgui.Create("DLabel", HD.InfoBar)
			L_CurLay:SetPos(10, 25) 
			L_CurLay:SetColor(Color(255,255,255)) 
			L_CurLay:SetFont("HD_Smaller")
			L_CurLay:SetText("Current Layer: "..HD.CurLayer)
			L_CurLay:SizeToContents() 
			L_CurLay.Think = function()
				L_CurLay:SetText("Current Layer: "..HD.CurLayer)
			end
			
				local L_LayCount = vgui.Create("DLabel", HD.InfoBar)
			L_LayCount:SetPos(10, 40) 
			L_LayCount:SetColor(Color(255,255,255)) 
			L_LayCount:SetFont("HD_Smaller")
			L_LayCount:SetText("Layer Count: "..HD.Layers)
			L_LayCount:SizeToContents() 
			L_LayCount.Think = function()
				L_LayCount:SetText("Layer Count: "..HD.Layers)
			end
			
				local L_ShaCount = vgui.Create("DLabel", HD.InfoBar)
			L_ShaCount:SetPos(10, 55) 
			L_ShaCount:SetColor(Color(255,255,255)) 
			L_ShaCount:SetFont("HD_Smaller")
			L_ShaCount:SetText("Shape Count: "..HD.ShapeCount-1)
			L_ShaCount:SizeToContents() 
			L_ShaCount.Think = function()
				L_ShaCount:SetText("Shape Count: "..HD.ShapeCount-1)
			end
			
				local L_GridSize = vgui.Create("DLabel", HD.InfoBar)
			L_GridSize:SetPos(10, 70) 
			L_GridSize:SetColor(Color(255,255,255)) 
			L_GridSize:SetFont("HD_Smaller")
			L_GridSize:SetText("Grid Size: "..HD.GridSize)
			L_GridSize:SizeToContents() 
			L_GridSize.Think = function()
				L_GridSize:SetText("Grid Size: "..HD.GridSize)
			end
			
				local L_GridOn = vgui.Create("DLabel", HD.InfoBar)
			L_GridOn:SetPos(10, 85) 
			L_GridOn:SetColor(Color(255,255,255)) 
			L_GridOn:SetFont("HD_Smaller")
			L_GridOn:SetText("Grid On: "..tostring(HD.GridEnabled))
			L_GridOn:SizeToContents() 
			L_GridOn.Think = function()
				L_GridOn:SetText("Grid On: "..tostring(HD.GridEnabled))
			end
			
			HD.InfoOpen = true
		elseif num == HD.Tools.Export then
			if HD.ExportOpen then 
				HD.SetTool(nil) 
				HD.Exporter:SetVisible(false) HD.ExportOpen = false HD.Exporter = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Export
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy

				HD.Exporter = vgui.Create("DPanel", HD.Frame)
			HD.Exporter:SetSize(150, 100)
			HD.Exporter:SetPos(px-(HD.Exporter:GetWide()/4), 40)
			HD.Exporter.Paint = function()
				local self = HD.Exporter
				draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
			end
			
			local ExportData
				local CheckBox1 = vgui.Create( "DCheckBoxLabel", HD.Exporter )
			CheckBox1:SetPos( 10, 60 )
			CheckBox1:SetText( "Scale Size" )
			CheckBox1:SetValue( HD.ScaleSize )	
			CheckBox1:SizeToContents()
			CheckBox1.OnChange = function( self, val )
				-- Save the value and create the new code
				HD.ScaleSize = val
				ExportData = HD.CreateExportCode()
			end
			
				local CheckBox2 = vgui.Create( "DCheckBoxLabel", HD.Exporter )
			CheckBox2:SetPos( 10, 80 )
			CheckBox2:SetText( "Scale Position" )
			CheckBox2:SetValue( HD.ScalePos )	
			CheckBox2:SizeToContents()
			CheckBox2.OnChange = function( self, val )
				HD.ScalePos = val
				ExportData = HD.CreateExportCode()
			end
			
			-- Prepare the code for exporting
			local SaveLocation = nil
			ExportData = HD.CreateExportCode()
			
			-- Labels for user choice
				local LabelChoice = vgui.Create("DLabel", HD.Exporter)
			LabelChoice:SetPos(35, 5) 
			LabelChoice:SetColor(Color(255,255,255)) 
			LabelChoice:SetFont("HD_Smaller")
			LabelChoice:SetText("Save code to")
			LabelChoice:SizeToContents()
			
				local Console = vgui.Create( "DButton", HD.Exporter )
			Console:SetText( "Console" )
			Console:SetTextColor( Color(0,0,0) )
			Console:SetPos( 10, 25 ) 
			Console:SetSize( 60, 30 ) 
			Console.Paint = function()
				draw.RoundedBox( 0, 0, 0, Console:GetWide(), Console:GetTall(), Color(255, 255, 255 ))
			end
			Console.DoClick = function() -- Print HUD code to console
				surface.PlaySound("buttons/button9.wav")
				SaveLocation = "console"
				LabelChoice:SetText("Code Saved")
				LabelChoice:SizeToContents()
				LabelChoice:SetPos(40, 5) 
				
				print("")
				print("")
				print("")
				
				print("--// HUD Code exported by "..LocalPlayer():Nick().." using Exho's HUD Designer //--")
				print("--// "..HD.ProjectName.." Exported on "..os.date("%c").." //--")
				print("")
				print("local lp = LocalPlayer()")
				print("local wep = LocalPlayer():GetActiveWeapon()")
				print("")
				for layer, id in pairs(ExportData) do
					print("--Layer: "..layer)
					for k, v in pairs(id) do
						print(v)
					end
					print("")
				end
				print("")
				print("--// End HUD Code //--")
				print("")
				print("")
				print("")
			end
			
				local TxtFile = vgui.Create( "DButton", HD.Exporter )
			TxtFile:SetText( "Text File" )
			TxtFile:SetTextColor( Color(0,0,0) )
			TxtFile:SetPos( 80, 25 ) 
			TxtFile:SetSize( 60, 30 ) 
			TxtFile.Paint = function()
				draw.RoundedBox( 0, 0, 0, TxtFile:GetWide(), TxtFile:GetTall(), Color(255, 255, 255 ))
			end
			TxtFile.DoClick = function()-- Print HUD code to a txt document
				surface.PlaySound("buttons/button9.wav")
				print("Export text")
				
				SaveLocation = "text"
				LabelChoice:SetText("Code Saved")
				LabelChoice:SizeToContents()
				LabelChoice:SetPos(40, 5) 
				
				-- Get a file name going
				local Banned = {"/", "\\", "?", "|", "<", ">", '"', ":" }
				local proj = HD.ProjectName
				for k, v in pairs(Banned) do -- Remove bad characters
					proj = string.gsub(proj, v, "-")
				end
				proj = string.gsub(proj, " ", "")
				local session = os.date("%H%M%S")
				session = string.gsub(session, ":", "")
				session = string.lower("export_"..proj.."_"..session)
	
				-- Create the code
				local Code = ""
				Code = Code.."--// HUD Code exported by "..LocalPlayer():Nick().." using Exho's HUD Designer //--\r\n"
				Code = Code.."--// "..HD.ProjectName.." Exported on "..os.date("%c").." //--\r\n\r\n"
				Code = Code.."local lp = LocalPlayer()\r\n"
				Code = Code.."local wep = LocalPlayer():GetActiveWeapon()\r\n\r\n"
					
				for layer, id in pairs(ExportData) do
					Code = Code.."--Layer: "..layer.."\r\n"
					for k, v in pairs(id) do
						Code = Code..v.."\r\n"
					end
					Code = Code.."\r\n"
				end
				Code = Code.."\r\n--// End HUD Code //--\r\n"
				
				-- Write to the directory
				file.CreateDir( "hud_designer" )
				file.Write( "hud_designer/"..session..".txt", Code)
			end
			
			HD.ExportOpen = true
		elseif num == HD.Tools.Save then -- Save current project in Json format
			HD.Save()
		elseif num == HD.Tools.Load then -- Load project from Json format
	
			if HD.LoadOpen then 
				HD.SetTool()
				HD.LoadSel:SetVisible(false) HD.LoadOpen = false HD.LayerView = false HD.LoadSel = nil 
				return 
			end
			
			local grandparent, parent = HD.IconLayout, HD.ToolbarButtons.Load
			local px, py = parent:GetPos()
			local gpx, gpy = grandparent:GetPos()
			px, py = px + gpx, py + gpy
			
			local Saves = file.Find( "hud_designer/save_*.txt", "DATA" ) -- Grab all the saves
			
			local SizeAlter = 1
			if #Saves > 2 then SizeAlter = 2 end
			
				HD.LoadSel = vgui.Create("DScrollPanel", HD.Frame)
			HD.LoadSel:SetSize(180, 95*SizeAlter)
			HD.LoadSel:SetPos(px-(HD.LoadSel:GetWide()/4), 40)
			HD.LoadSel.Paint = function()
				draw.RoundedBox(0, 0, 0, HD.LoadSel:GetWide(), HD.LoadSel:GetTall(), Color(39, 174, 96))
			end
			
				local CurLay = vgui.Create("DLabel", HD.LoadSel)
			CurLay:SetPos(25, 5) 
			CurLay:SetColor(Color(255,255,255)) 
			CurLay:SetFont("HD_Smaller")
			CurLay:SetText("Click on a save to load")
			CurLay:SizeToContents() 
			
			local SavePanels = {}
			local i = 1
			local YBuffer = 30
			local BarBuffer = 0
			if #Saves > 1 then BarBuffer = 15 end
			
			for i = 1, #Saves do	
				local txt = file.Read( "hud_designer/"..Saves[i], "DATA" )
				local tab = util.JSONToTable( txt ) 
				
				local name = tab.ProjectName or Saves[i]
				name = string.gsub(name, "save_", "")
				name = string.gsub(name, ".txt", "")
				name = string.gsub(name, "_", " ")
				
				local Count 
					SavePanels[i] = vgui.Create("DButton", HD.LoadSel)
				SavePanels[i]:SetPos(10, YBuffer)
				SavePanels[i]:SetSize(HD.LoadSel:GetWide()-20-BarBuffer, 50)
				SavePanels[i]:SetTextColor(Color(255,255,255))
				SavePanels[i]:SetText(name)
				SavePanels[i].Paint = function()
					local col = Color(90,90,90, 250)
					draw.RoundedBox(0, 0, 0, SavePanels[i]:GetWide(), SavePanels[i]:GetTall(), col)
				end
				SavePanels[i].DoClick = function()
					HD.Load( Saves[i] )
				end
				
				YBuffer = YBuffer + SavePanels[i]:GetTall() + 20
			end
			
			HD.LoadOpen = true
			--HD.Load()
		end
	end
	
	--// Shape settings
	function HD.OpenShapeSettings(id,mx,my)
		if HD.ShapeOptions[id] then HD.ShapeOptions[id]:SetVisible(false) HD.ShapeOptions[id] = nil end
		
		HD.CancelAlter() -- Make sure no shapes are altered while open
		HD.ShapeOptions = HD.ShapeOptions or {}
		local ShapeStuff = HD.GetShapeData(id)
		local Type = HD.GetShapeType(id)
		local layer = HD.GetShapeLayer(id)
		
			HD.ShapeOptions[id] = vgui.Create("DFrame", HD.Frame)
		HD.ShapeOptions[id]:SetSize(150, 120)
		local x, y = math.Clamp( mx, 0, ScrW()-HD.ShapeOptions[id]:GetWide() ), math.Clamp( my, 0, ScrH()-HD.ShapeOptions[id]:GetTall())
		HD.ShapeOptions[id]:SetPos( x, y )
		HD.ShapeOptions[id]:SetTitle("")
		HD.ShapeOptions[id]:SetDraggable(true)
		HD.ShapeOptions[id].btnMaxim:SetVisible( false )
		HD.ShapeOptions[id].btnMinim:SetVisible( false )
		HD.ShapeOptions[id].btnClose:SetVisible( false )
		HD.ShapeOptions[id].Paint = function()
			local self = HD.ShapeOptions[id]
			draw.RoundedBox(0, 0, 0, self:GetWide(), self:GetTall(), Color(39, 174, 96))
		end
		HD.ShapeOptions[id].OnMousePressed = function()
			local self = HD.ShapeOptions[id]
			-- Make sure nothing moves
			HD.CurMovingData, HD.Moving, HD.CurSizeID, HD.Sizing = {}, false, nil, false
			
			-- Dragging code because I overrode the function
			self.Dragging = { gui.MouseX() - self.x, gui.MouseY() - self.y }
			self:MouseCapture( true )
			return
		end
		
		local Exit = vgui.Create( "DButton", HD.ShapeOptions[id] )
		Exit:SetText( "X" )
		Exit:SetTextColor( Color(255,255,255,255) )
		Exit:SetPos( HD.ShapeOptions[id]:GetWide() - 45, 5 ) 
		Exit:SetFont("HD_Button")
		Exit:SetSize( 40, 20 ) 
		Exit.Paint = function()
			draw.RoundedBox( 0, 0, 0, Exit:GetWide(), Exit:GetTall(), Color(200, 79, 79,255) )
		end
		Exit.DoClick = function()
			surface.PlaySound("buttons/button9.wav")
			HD.CurMovingData, HD.Moving, HD.CurSizeID, HD.Sizing = {}, false, nil, false
			HD.ShapeOptions[id]:Close()
			HD.ShapeOptions[id] = nil
		end
		
			local NumLayer = vgui.Create( "DNumberWang", HD.ShapeOptions[id] )
		NumLayer:SetDecimals( 0 )
		NumLayer:SetMinMax( 1, 500 )
		NumLayer:SetValue( HD.CurLayer )
		NumLayer:SetPos(20, 30)
		NumLayer:SetSize(60, 25)
		NumLayer:SetTooltip("Change your shape's layer")
		NumLayer.OnValueChanged = function()
			local new = NumLayer:GetValue()
			if new == nil or new == 0 then return end
			
			if HD.Layers < new then
				HD.Layers = new
			end

			HD.EditShape(id, {layer=HD.CurLayer, newlayer=new}, "layer")
			layer = HD.GetShapeLayer(id)
		end
		
		if Type == "draw.RoundedBox" then
				local NumCorner = vgui.Create( "DNumberWang", HD.ShapeOptions[id] )
			NumCorner:SetDecimals( 0 )
			NumCorner:SetMinMax( 0, 40 )
			NumCorner:SetValue( ShapeStuff.corner )
			NumCorner:SetPos(20, 80)
			NumCorner:SetSize(60, 25)
			NumCorner:SetTooltip("Change your shape's corner size")
			NumCorner.OnValueChanged = function()
				local new = NumCorner:GetValue()
				if new == nil then return end
				
				if new ~= ShapeStuff.corner then
					HD.EditShape(id, {corner=new}, "corner")
				end
			end
			-- Override click buttons to only move in increments of 2
			NumCorner.Up.DoClick = function( button, mcode ) NumCorner:SetValue( NumCorner:GetValue() + 2 ) end
			NumCorner.Down.DoClick = function( button, mcode ) NumCorner:SetValue( NumCorner:GetValue() - 2 ) end
		elseif Type == "draw.DrawText" then
				local Text = vgui.Create( "DTextEntry", HD.ShapeOptions[id] )	-- create the form as a child of frame
			Text:SetSize( 80, 25 )
			Text:SetPos( 20, 80 )
			Text:SetText( ShapeStuff.text )
			Text:SetFont("HD_Button")
			Text:SetTooltip("Enter your text here")
			Text.OnChange = function( self, val )
				HD.DrawnObjects[layer][Type][id].text = self:GetText() -- Set the new text
				
				local font = HD.DrawnObjects[layer][Type][id].font -- Adjust the size
				local width, height = HD.GetTextSize(self:GetText(), font)
				HD.DrawnObjects[layer][Type][id].width, HD.DrawnObjects[layer][Type][id].height = width, height
				
				local bound = HD.Boundaries[id] -- Gotta add new boundaries for the text
				HD.Boundaries[id].farx, HD.Boundaries[id].fary = bound.x + width, bound.y + height
			end
			
				local Font = vgui.Create( "DTextEntry", HD.ShapeOptions[id] )
			Font:SetSize( 80, 25 )
			Font:SetPos( 20, 130 )
			Font:SetText( ShapeStuff.font )
			Font:SetFont("HD_Button")
			Font:SetTooltip("Enter a valid font for your text")
			Font.OnEnter = function( self, val )
				HD.DrawnObjects[layer][Type][id].font = self:GetText() -- Set the new text
			end
			
			local Key = nil
				HD.ShapeOptions[id].Format = vgui.Create( "DComboBox", HD.ShapeOptions[id] )
			HD.ShapeOptions[id].Format:SetSize( 80, 25 )
			HD.ShapeOptions[id].Format:SetPos( 20, 180 )
			for k, v in pairs(HD.FormatTypes) do
				if v.code == HD.DrawnObjects[layer][Type][id].format then
					Key = k -- Grab the FormatType key
					break
				end
			end
			HD.ShapeOptions[id].Format:SetValue(Key or "Type")
			HD.ShapeOptions[id].Format:SetFont("HD_Button")
			HD.ShapeOptions[id].Format:SetTooltip("string.format Types")
			a = {}
			for n in pairs(HD.FormatTypes) do table.insert(a, n) end -- Sort the table alphabetically
			table.sort(a)
			for i,n in ipairs(a) do
				HD.ShapeOptions[id].Format:AddChoice(n) 
			end
			HD.ShapeOptions[id].Format.OnSelect = function( self, index, value )
				local fmat = HD.FormatTypes[value]
				
				if value == "None" then 
					HD.ShapeOptions[id].Format:SetValue("Type")
					HD.DrawnObjects[layer][Type][id].format = nil
					HD.DrawnObjects[layer][Type][id].text = "Sample Text"
					return
				end
				
				HD.DrawnObjects[layer][Type][id].text = fmat.text
				HD.DrawnObjects[layer][Type][id].format = fmat.code
			end
		elseif Type == "surface.DrawTexturedRect" then
			local TextureText = tostring(ShapeStuff.texturestring or ShapeStuff.texture)
			if TextureText == "___error" or TextureText == nil then TextureText = "Image Path" end
			
				local Texture = vgui.Create( "DTextEntry", HD.ShapeOptions[id] )
			Texture:SetSize( 80, 25 )
			Texture:SetPos( 20, 80 )
			Texture:SetText( TextureText )
			Texture:SetFont("HD_Button")
			Texture:SetTooltip("Relative to the materials/ directory")
			Texture.OnEnter = function( self, val )
				--scripted/breen_fakemonitor_1
				
				--local mat = surface.GetTextureID(self:GetText())
				local mat = Material( self:GetText() )
				
				HD.DrawnObjects[layer][Type][id].texture = mat
				HD.DrawnObjects[layer][Type][id].texturestring = self:GetText()
			end
		end
		
			local Label1 = vgui.Create("DLabel", HD.ShapeOptions[id])
		Label1:SetPos(5, 10) 
		Label1:SetColor(Color(255,255,255)) 
		Label1:SetFont("HD_Smaller")
		Label1:SetText("Shape Layer:")
		Label1:SizeToContents() 
			local Label2 = vgui.Create("DLabel", HD.ShapeOptions[id])
		Label2:SetPos(5, 60) 
		Label2:SetColor(Color(255,255,255)) 
		Label2:SetFont("HD_Smaller")
		if Type == "draw.RoundedBox" then
			Label2:SetText("Corner Size:")
		elseif Type == "draw.DrawText" then
			Label2:SetText("Text:")
		elseif Type == "surface.DrawTexturedRect" then
			Label2:SetText("Texture:")
		end
		Label2:SizeToContents() 
			local Label3 = vgui.Create("DLabel", HD.ShapeOptions[id])
		Label3:SetPos(100, 60) 
		Label3:SetColor(Color(255,255,255)) 
		Label3:SetFont("HD_Smaller")
		Label3:SetText("ID: "..id)
		Label3:SizeToContents() 
		if Type == "draw.DrawText" then
				local Label4 = vgui.Create("DLabel", HD.ShapeOptions[id])
			Label4:SetPos(5, 110) 
			Label4:SetColor(Color(255,255,255)) 
			Label4:SetFont("HD_Smaller")
			Label4:SetText("Font: ")
			Label4:SizeToContents() 
			
				local Label5 = vgui.Create("DLabel", HD.ShapeOptions[id])
			Label5:SetPos(5, 160) 
			Label5:SetColor(Color(255,255,255)) 
			Label5:SetFont("HD_Smaller")
			Label5:SetText("Format: ")
			Label5:SizeToContents() 
			
			local w, h = HD.ShapeOptions[id]:GetSize()
			HD.ShapeOptions[id]:SetSize(w, h+100)
		end
	end
end



