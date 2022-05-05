
if SERVER then
	AddCSLuaFile("parsers/dxt1.lua")
end



local parsers = {
	[13] = include("parsers/dxt1.lua"),
}


local function parseMipmaps(mat, width, height, headerData)
	local pixels = {}

	local frameCount = headerData.frames
	local mipmapCount = headerData.mipmapCount
	local depth = headerData.depth

	if depth == 0 then depth = 1 end

	local zSlicers = 1

	local preW = width
	local preH = height

	local mipSizes = {}
	for i = 1, mipmapCount do
		mipSizes[mipmapCount - i + 1] = {preW, preH}
		
		preW = math.max(1, math.ceil(preW / 2))
		preH = math.max(1, math.ceil(preH / 2))
	end

	-- PrintTable(mipSizes)	

	local images = {}

	for mipmapID = 1, mipmapCount do
		local frames = {}

		for frameID = 1, frameCount do
			local frame = {}
			for faceID = 1, depth do
				local face = {}
				for sliceID = 1, zSlicers do
					local mipWidth, mipHeight = mipSizes[mipmapID][1], mipSizes[mipmapID][2]

					-- print(mipWidth, mipHeight)

					local parserFunc = parsers[headerData.highResImageFormat]
					if not parserFunc then
						print("Parser not implemented for image id", headerData.lowResImageFormat)
						return
					end
					local pixels = parserFunc(mat, mipWidth, mipHeight, headerData)

					face[sliceID] = pixels
				end
				frame[faceID] = face
			end
			frames[frameID] = frame
		end
		images[mipmapID] = frames
	end
	return images
end


local function readVTfFile(path)
	local mat = file.Open(path, "rb", "GAME")

	local header = mat:Read(4)
	local version = mat:ReadLong() .. "." .. mat:ReadLong()
	local headerSize = mat:ReadLong()
	local width = mat:ReadShort()
	local height = mat:ReadShort()
	local flags = mat:ReadLong()
	local frames = mat:ReadShort()
	local firstFrame = mat:ReadShort()
	local padding0 = mat:Read(4)
	local reflectivity = mat:ReadFloat() .. " " .. mat:ReadFloat() .. " " .. mat:ReadFloat()
	local padding1 = mat:Read(4)
	local bumpmapScale = mat:ReadFloat()
	local highResImageFormat = mat:ReadLong()
	local mipmapCount = mat:ReadByte()
	local lowResImageFormat = mat:ReadLong()
	local lowResImageWidth = mat:ReadByte()
	local lowResImageHeight = mat:ReadByte()

	local headerData = {
		version = version,
		width = width,
		height = height,
		flags = flags,
		frames = frames,
		firstFrame = firstFrame,
		reflectivity = reflectivity,
		bumpmapScale = bumpmapScale,
		highResImageFormat = highResImageFormat,
		mipmapCount = mipmapCount,
		lowResImageFormat = lowResImageFormat,
		lowResImageWidth = lowResImageWidth,
		lowResImageHeight = lowResImageHeight
	}


	local depth = 0

	if version == "7.2" then
		depth = mat:ReadShort()
		headerData.depth = depth
		-- print("Depth", depth)

	elseif version == "7.3" then
		local padding2 = mat:Read(3)
		local numResources = mat:ReadLong()		
		local padding3 = mat:Read(8)
	end


	mat:Seek(headerSize)

	local parserFunc = parsers[headerData.lowResImageFormat]
	
	if not parserFunc then
		print("Parser not implemented for image id", headerData.lowResImageFormat)
		return
	end
	local pixels = 	parserFunc(mat, lowResImageWidth, lowResImageHeight, headerData)
	-- PrintTable(pixels)

	local highQualityPixels = parseMipmaps(mat, width, height, headerData)

	mat:Close()

	return {
		headerData = headerData,
		pixels = pixels,
		highQualityPixels = highQualityPixels
	}
end

if SERVER then AddCSLuaFile("texture_meta.lua") end
local texture_meta = include("texture_meta.lua")
VTFParser = VTFParser or {}
// We expose this function instead of raw readVTfFile
// because highQualityPixels are stored VERY weirdly
function VTFParser.Material(path)
	local data = readVTfFile("materials/" .. path .. ".vtf")

	local textureInfo = {
		name = path,
		width = data.headerData.width,
		height = data.headerData.height,
		pixels = data.highQualityPixels[data.headerData.mipmapCount][1][1][1], 
	}

	setmetatable(textureInfo, texture_meta)

	return textureInfo
end