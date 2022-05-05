
local texture_meta = {}
texture_meta.__index = texture_meta

function texture_meta:Width()
	return self.width
end

function texture_meta:Height()
	return self.height
end

function texture_meta:GetColor(x, y)
	return self.pixels[x][y]
end

function texture_meta:GetPixels()
	return self.pixels
end

function texture_meta:GetTrueTexture()
	// see if there is a true texture

	if self.true_texture then
		return self.true_texture
	end

	ErrorNoHaltWithStack("Not implemented: GetTrueTexture()\n")
	// create an ITexture populate the pixels and return it
end

return texture_meta