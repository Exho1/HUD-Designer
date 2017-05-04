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

	-- Gets the ratio of the screen size to the canvas size
	-- Multiply shape size by these to get their screen dimensions
	Designer.canvasConst.wratio = ScrW() / wCutOff
	Designer.canvasConst.hratio = ScrH() / hCutOff

1:
		1:
				color:
						a	=	255
						b	=	0
						g	=	0
						r	=	255
				h	=	300
				id	=	2
				layer	=	1
				special:
				type	=	rect
				w	=	300
				x	=	60
				y	=	60
		2:
				color:
						a	=	255
						b	=	255
						g	=	255
						r	=	255
				font	=	DesignerDefault
				h	=	19
				id	=	3
				text	=	Hello World!
				type	=	text
				w	=	89
				x	=	60
				y	=	60
] 


Layer: 	3	Type	draw.RoundedBox
SHAPE DATA
color:
		a	=	241
		b	=	225
		g	=	167
		r	=	33
corner	=	4
height	=	340
width	=	80
x	=	40
y	=	660
END SHAPE DATA





						y	=	660
4:
		draw.DrawText:
				9:
						color:
								a	=	255
								b	=	255
								g	=	255
								r	=	255
						font	=	Trebuchet24
						height	=	24
						text	=	Round 1
						width	=	68
						x	=	150
						y	=	960
				10:
						color:
								a	=	255
								b	=	255
								g	=	255
								r	=	255
						font	=	Trebuchet24
						format	=	lp:Team()
						text	=	%team%
						x	=	150
						y	=	930
				11:
						color:
								a	=	255
								b	=	255
								g	=	255
								r	=	255
						font	=	Trebuchet24
						height	=	24
						text	=	Warmth
						width	=	67
						x	=	48
						y	=	960

