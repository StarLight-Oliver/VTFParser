local function rgb565Torgba(rgb565)
	local r = bit.band(bit.rshift(rgb565, 11), 0x1F)
	local g = bit.band(bit.rshift(rgb565, 5), 0x3F)
	local b = bit.band(rgb565, 0x1F)


	r = bit.bor( bit.lshift(r, 3), bit.rshift(r, 2) )
	g = bit.bor( bit.lshift(g, 2), bit.rshift(g, 4) )
	b = bit.bor( bit.lshift(b, 3), bit.rshift(b, 2) )

	-- print(r, g, b)

	return Color(r,g,b)
end

local blockSize = 4

local decompressBlock = function(mat)

	local c0 = mat:ReadShort()
	local c1 = mat:ReadShort()
	local code = mat:ReadULong()

	local color0 = rgb565Torgba(c0)
	local color1 = rgb565Torgba(c1)

	-- PrintTable({color0, color1})

	local block = {}

	for j = 1, blockSize do
		block[j] = {}
		for i = 1, blockSize do

			local finalColor = nil

			local positionCode = bit.band(bit.rshift(code, 2*(4*(j-1)+(i-1))), 0x03)

			if c0 > c1 then
				if positionCode == 0 then
					finalColor = color0
				elseif positionCode == 1 then
					finalColor = color1
				elseif positionCode == 2 then
					finalColor = Color(
						(2*color0.r + color1.r) / 3,
						(2*color0.g + color1.g) / 3,
						(2*color0.b + color1.b) / 3
					)
				elseif positionCode == 3 then
					finalColor = Color(
						(color0.r + 2*color1.r) / 3,
						(color0.g + 2*color1.g) / 3,
						(color0.b + 2*color1.b) / 3
					)
				end
			else
				if positionCode == 0 then
					finalColor = color0
				elseif positionCode == 1 then
					finalColor = color1
				elseif positionCode == 2 then
					finalColor = Color(
						(color0.r + color1.r) / 2,
						(color0.g + color1.g) / 2,
						(color0.b + color1.b) / 2
					)
				elseif positionCode == 3 then
					finalColor = Color(0,0,0)
				end
			end

			block[j][i] = finalColor
		end
	end
	return block
end

local function parseDX1(mat, width, height, headerData)
	/*
		The 2 16-bit color values are stored in little-endian format, 
		so the low byte of the 16-bit color comes first in each case. 
		The color values are stored in RGB order (from high bit to low bit) in 5_6_5 bits.
	*/

	local blockCountX = math.floor((width  + 3) / 4)
	local blockCountY = math.floor((height + 3) / 4)

	local pixels = {}

	local offset = 0
	for j = 0, blockCountY-1 do
		for i = 0, blockCountX-1 do
			local block = decompressBlock(mat)
			for jj = 1, blockSize do
				local yPos = j*blockSize + jj
				for ii = 1, blockSize do
					local xPos = i*blockSize + ii

					if not pixels[xPos] then
						pixels[xPos] = {}
					end

					if pixels[xPos][yPos] then
						print("Duplicate pixel at", xPos, yPos)
					end

					pixels[xPos][yPos] = block[jj][ii]
				end
			end
		end
	end

	return pixels
end

return parseDX1