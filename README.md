# VTFParser

This is a basic vtf parser written in glua.

I wrote this mainly because ITexture:GetColor was taking 20 mins to run for my code.
But the material file was able to be parsed in under a second, this lead me to believe that GetColor likley reads the texture from the file each time it is called.

This libraryy exposes all all the same functions that an ITexture would have but allows for faster reading of pixels.
Parsing of the file is obviously slower than using Material.

Currently only dxt1 files are supported and support with 7.3+ format is unlikely in its current state.

