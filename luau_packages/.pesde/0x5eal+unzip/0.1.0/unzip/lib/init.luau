local inflate = require("./inflate")
local validateCrc = require("./utils/validate_crc")
local path = require("./utils/path")

-- The maximum supported PKZIP format specification version that we support
local MAX_SUPPORTED_PKZIP_VERSION = 63

-- Little endian constant signatures used in the ZIP file format
local SIGNATURES = table.freeze({
	-- Marks the beginning of each file in the ZIP
	LOCAL_FILE = 0x04034b50,
	-- Marks the start of an data descriptor
	DATA_DESCRIPTOR = 0x08074b50,
	-- Marks entries in the central directory
	CENTRAL_DIR = 0x02014b50,
	-- Marks the end of the central directory
	END_OF_CENTRAL_DIR = 0x06054b50,
})

-- Decompression routines for each supported compression method
local DECOMPRESSION_ROUTINES: { [number]: { name: CompressionMethod, decompress: (buffer, number, validateCrc.CrcValidationOptions) -> buffer } } =
	{
		-- `STORE` decompression method - No compression
		[0x00] = {
			name = "STORE" :: CompressionMethod,
			decompress = function(buf, _, validation): buffer
				validateCrc(buf, validation)
				return buf
			end,
		},

		-- `DEFLATE` decompression method - Compressed raw deflate chunks
		[0x08] = {
			name = "DEFLATE" :: CompressionMethod,
			decompress = function(buf, uncompressedSize, validation): buffer
				local decompressed = inflate(buf, uncompressedSize)
				validateCrc(decompressed, validation)
				return decompressed
			end,
		},
	}

-- Set of placeholder entry properties for incompatible entries
local EMPTY_PROPERTIES: ZipEntryProperties = table.freeze({
	versionMadeBy = 0,
	compressedSize = 0,
	size = 0,
	attributes = 0,
	timestamp = 0,
	crc = 0,
})

-- Lookup table for the OS that created the ZIP
local MADE_BY_OS_LOOKUP: { [number]: MadeByOS } = {
	[0x0] = "FAT",
	[0x1] = "AMIGA",
	[0x2] = "VMS",
	[0x3] = "UNIX",
	[0x4] = "VM/CMS",
	[0x5] = "Atari ST",
	[0x6] = "OS/2",
	[0x7] = "MAC",
	[0x8] = "Z-System",
	[0x9] = "CP/M",
	[0xa] = "NTFS",
	[0xb] = "MVS",
	[0xc] = "VSE",
	[0xd] = "Acorn RISCOS",
	[0xe] = "VFAT",
	[0xf] = "Alternate MVS",
	[0x10] = "BeOS",
	[0x11] = "TANDEM",
	[0x12] = "OS/400",
	[0x13] = "OS/X",
}

local ZipEntry = {}
export type ZipEntry = typeof(setmetatable({} :: ZipEntryInner, { __index = ZipEntry }))
-- stylua: ignore
type ZipEntryInner = {
	name: string,              -- File path within ZIP, '/' suffix indicates directory

	versionMadeBy: {           -- Version of software and OS that created the ZIP
		software: string,      -- Software version used to create the ZIP
		os: MadeByOS,          -- Operating system used to create the ZIP
	},

	compressedSize: number,    -- Compressed size in bytes
	size: number,              -- Uncompressed size in bytes
    offset: number,            -- Absolute position of local header in ZIP
    timestamp: number,         -- MS-DOS format timestamp
    method: CompressionMethod, -- Method used to compress the file
    crc: number,               -- CRC32 checksum of uncompressed data
    isDirectory: boolean,      -- Whether the entry is a directory or not
    isText: boolean,           -- Whether the entry is plain ASCII text or binary
    attributes: number,        -- File attributes
    parent: ZipEntry?,         -- The parent of the current entry, nil for root
    children: { ZipEntry },    -- The children of the entry
}

-- stylua: ignore
export type MadeByOS =
	| "FAT"           -- 0x0; MS-DOS and OS/2 (FAT / VFAT / FAT32 file systems)
	| "AMIGA"         -- 0x1; Amiga
	| "VMS"	          -- 0x2; OpenVMS
	| "UNIX"          -- 0x3; Unix
	| "VM/CMS"        -- 0x4; VM/CMS
	| "Atari ST"      -- 0x5; Atari ST
	| "OS/2"          -- 0x6; OS/2 HPFS
	| "MAC"           -- 0x7; Macintosh
	| "Z-System"      -- 0x8; Z-System
	| "CP/M"          -- 0x9; Original CP/M
	| "NTFS"          -- 0xa; Windows NTFS
	| "MVS"           -- 0xb; OS/390 & VM/ESA
	| "VSE"           -- 0xc; VSE
	| "Acorn RISCOS"  -- 0xd; Acorn RISCOS
	| "VFAT"          -- 0xe; VFAT
	| "Alternate MVS" -- 0xf; Alternate MVS
	| "BeOS"          -- 0x10; BeOS
	| "TANDEM"        -- 0x11; Tandem
	| "OS/400"        -- 0x12; OS/400
	| "OS/X"          -- 0x13; Darwin
	| "Unknown"       -- 0x14 - 0xff; Unused
export type CompressionMethod = "STORE" | "DEFLATE"
export type ZipEntryProperties = {
	versionMadeBy: number,
	compressedSize: number,
	size: number,
	attributes: number,
	timestamp: number,
	method: CompressionMethod?,
	crc: number,
}

function ZipEntry.new(offset: number, name: string, properties: ZipEntryProperties): ZipEntry
	local versionMadeByOS = bit32.rshift(properties.versionMadeBy, 8)
	local versionMadeByVersion = bit32.band(properties.versionMadeBy, 0x00ff)

	return setmetatable(
		{
			name = name,
			versionMadeBy = {
				software = string.format("%d.%d", versionMadeByVersion / 10, versionMadeByVersion % 10),
				os = MADE_BY_OS_LOOKUP[versionMadeByOS] :: MadeByOS,
			},
			compressedSize = properties.compressedSize,
			size = properties.size,
			offset = offset,
			timestamp = properties.timestamp,
			method = properties.method,
			crc = properties.crc,
			isDirectory = string.sub(name, -1) == "/",
			attributes = properties.attributes,
			parent = nil,
			children = {},
		} :: ZipEntryInner,
		{ __index = ZipEntry }
	)
end

function ZipEntry.isSymlink(self: ZipEntry): boolean
	return bit32.band(self.attributes, 0xA0000000) == 0xA0000000
end

function ZipEntry.getPath(self: ZipEntry): string
	local path = self.name
	local current = self.parent

	while current and current.name ~= "/" do
		path = current.name .. path
		current = current.parent
	end

	return path
end

function ZipEntry.getSafePath(self: ZipEntry): string?
	local pathStr = self:getPath()

	if path.isSafe(pathStr) then
		return pathStr
	end

	return nil
end

function ZipEntry.sanitizePath(self: ZipEntry): string
	local pathStr = self:getPath()
	return path.sanitize(pathStr)
end

function ZipEntry.compressionEfficiency(self: ZipEntry): number?
	if self.size == 0 or self.compressedSize == 0 then
		return nil
	end

	local ratio = 1 - self.compressedSize / self.size
	return math.round(ratio * 100)
end

function ZipEntry.isFile(self: ZipEntry): boolean
	return not (self.isDirectory and self:isSymlink())
end

export type UnixMode = { perms: string, typeFlags: string }
function ZipEntry.unixMode(self: ZipEntry): UnixMode?
	if self.versionMadeBy.os ~= "UNIX" then
		return nil
	end

	local mode = bit32.rshift(self.attributes, 16)
	local typeFlags = bit32.band(self.attributes, 0x1FF)
	local perms = bit32.band(mode, 0x01FF)

	return {
		perms = string.format("0o%o", perms),
		typeFlags = string.format("0o%o", typeFlags),
	}
end

local ZipReader = {}
export type ZipReader = typeof(setmetatable({} :: ZipReaderInner, { __index = ZipReader }))
-- stylua: ignore
type ZipReaderInner = {
    data: buffer,                         -- The buffer containing the raw bytes of the ZIP
    comment: string,                      -- Comment associated with the ZIP
    entries: { ZipEntry },                -- The decoded entries present
    directories: { [string]: ZipEntry },  -- The directories and their respective entries 
    root: ZipEntry,                       -- The entry of the root directory
}

function ZipReader.new(data): ZipReader
	local root = ZipEntry.new(0, "/", EMPTY_PROPERTIES)
	root.isDirectory = true

	local this = setmetatable(
		{
			data = data,
			entries = {},
			directories = {},
			root = root,
		} :: ZipReaderInner,
		{ __index = ZipReader }
	)

	this:parseCentralDirectory()
	this:buildDirectoryTree()
	return this
end
function ZipReader.parseCentralDirectory(self: ZipReader): ()
	-- ZIP files are read from the end, starting with the End of Central Directory record
	-- The EoCD is at least 22 bytes and contains pointers to the rest of the ZIP structure
	local bufSize = buffer.len(self.data)

	-- Start from the minimum possible position of EoCD (22 bytes from end)
	local minPos = math.max(0, bufSize - (22 + 65535) --[[ max comment size: 64 KiB ]])
	local pos = bufSize - 22

	-- Search backwards for the EoCD signature
	while pos >= minPos do
		if buffer.readu32(self.data, pos) == SIGNATURES.END_OF_CENTRAL_DIR then
			break
		end
		pos -= 1
	end

	-- Verify we found the signature
	if pos < minPos then
		error("Could not find End of Central Directory signature")
	end

	-- End of Central Directory format:
	-- Offset  Bytes  Description
	-- 0       4      End of central directory signature
	-- 4       2      Number of this disk
	-- 6       2      Disk where central directory starts
	-- 8       2      Number of central directory records on this disk
	-- 10      2      Total number of central directory records
	-- 12      4      Size of central directory (bytes)
	-- 16      4      Offset of start of central directory
	-- 20      2      Comment length (n)
	-- 22      n      Comment

	local cdSize = buffer.readu32(self.data, pos + 12)
	local cdEntries = buffer.readu16(self.data, pos + 10)
	local cdOffset = buffer.readu32(self.data, pos + 16)

	-- Strict validation of CD boundaries and entry count
	if cdOffset >= bufSize or cdOffset + cdSize > bufSize then
		error("Invalid Central Directory offset or size")
	end

	-- Track actual entries found
	local entriesFound = 0
	pos = cdOffset
	while pos < cdOffset + cdSize do
		if buffer.readu32(self.data, pos) ~= SIGNATURES.CENTRAL_DIR then
			error("Invalid Central Directory entry signature")
		end

		-- Central Directory Entry format:
		-- Offset  Bytes  Description
		-- 0       4      Central directory entry signature
		-- 4       2      Version made by
		-- 8       2      General purpose bitflags
		-- 10      2      Compression method (8 = DEFLATE)
		-- 12      4      Last mod time/date
		-- 16      4      CRC-32
		-- 20      4      Compressed size
		-- 24      4      Uncompressed size
		-- 28      2      File name length (n)
		-- 30      2      Extra field length (m)
		-- 32      2      Comment length (k)
		-- 36      2      Internal file attributes
		-- 38      4      External file attributes
		-- 42      4      Local header offset
		-- 46      n      File name
		-- 46+n    m      Extra field
		-- 46+n+m  k      Comment

		local versionMadeBy = buffer.readu16(self.data, pos + 4)
		local _bitflags = buffer.readu16(self.data, pos + 8)
		local timestamp = buffer.readu32(self.data, pos + 12)
		local compressionMethod = buffer.readu16(self.data, pos + 10)
		local crc = buffer.readu32(self.data, pos + 16)
		local compressedSize = buffer.readu32(self.data, pos + 20)
		local size = buffer.readu32(self.data, pos + 24)
		local nameLength = buffer.readu16(self.data, pos + 28)
		local extraLength = buffer.readu16(self.data, pos + 30)
		local commentLength = buffer.readu16(self.data, pos + 32)
		local internalAttrs = buffer.readu16(self.data, pos + 36)
		local externalAttrs = buffer.readu32(self.data, pos + 38)
		local offset = buffer.readu32(self.data, pos + 42)
		local name = buffer.readstring(self.data, pos + 46, nameLength)

		table.insert(
			self.entries,
			ZipEntry.new(offset, name, {
				versionMadeBy = versionMadeBy,
				compressedSize = compressedSize,
				size = size,
				crc = crc,
				method = DECOMPRESSION_ROUTINES[compressionMethod].name :: CompressionMethod,
				timestamp = timestamp,
				attributes = externalAttrs,
				isText = bit32.band(internalAttrs, 0x0001) ~= 0,
			})
		)

		pos = pos + 46 + nameLength + extraLength + commentLength
		entriesFound += 1
	end

	if entriesFound ~= cdEntries then
		error("Found different entries than specified in Central Directory")
	end

	local cdCommentLength = buffer.readu16(self.data, pos + 20)
	self.comment = buffer.readstring(self.data, pos + 22, cdCommentLength)
end

function ZipReader.buildDirectoryTree(self: ZipReader): ()
	-- Sort entries to process directories first; I could either handle
	-- directories and files in separate passes over the entries, or sort
	-- the entries so I handled the directories first -- I decided to do
	-- the latter
	table.sort(self.entries, function(a, b)
		if a.isDirectory ~= b.isDirectory then
			return a.isDirectory
		end
		return a.name < b.name
	end)

	for _, entry in self.entries do
		local parts = {}
		-- Split entry path into individual components
		-- e.g. "folder/subfolder/file.txt" -> {"folder", "subfolder", "file.txt"}
		for part in string.gmatch(entry.name, "([^/]+)/?") do
			table.insert(parts, part)
		end

		-- Start from root directory
		local current = self.root
		local path = ""

		-- Process each path component
		for i, part in parts do
			path ..= part

			if i < #parts or entry.isDirectory then
				-- Create missing directory entries for intermediate paths
				if not self.directories[path] then
					if entry.isDirectory and i == #parts then
						-- Existing directory entry, reuse it
						self.directories[path] = entry
					else
						-- Create new directory entry for intermediate paths or undefined
						-- parent directories in the ZIP
						local dir = ZipEntry.new(0, path .. "/", {
							versionMadeBy = 0,
							compressedSize = 0,
							size = 0,
							crc = 0,
							compressionMethod = "STORED",
							timestamp = entry.timestamp,
							attributes = entry.attributes,
						})

						dir.versionMadeBy = entry.versionMadeBy
						dir.isDirectory = true
						dir.parent = current
						self.directories[path] = dir
					end

					-- Track directory in both lookup table and parent's children
					table.insert(current.children, self.directories[path])
				end

				-- Move deeper into the tree
				current = self.directories[path]
				continue
			end

			-- Link file entry to its parent directory
			entry.parent = current
			table.insert(current.children, entry)
		end
	end
end

function ZipReader.findEntry(self: ZipReader, path: string): ZipEntry?
	if path == "/" then
		-- If the root directory's entry was requested we do not
		-- need to do any additional work
		return self.root
	end

	-- Normalize path by removing leading and trailing slashes
	-- This ensures consistent lookup regardless of input format
	-- e.g., "/folder/file.txt/" -> "folder/file.txt"
	path = string.gsub(path, "^/", ""):gsub("/$", "")

	-- First check regular files and explicit directories
	for _, entry in self.entries do
		-- Compare normalized paths
		if string.gsub(entry.name, "/$", "") == path then
			return entry
		end
	end

	-- If not found, check virtual directory entries
	-- These are directories that were created implicitly
	return self.directories[path]
end

type ExtractionOptions = {
	followSymlinks: boolean?,
	decompress: boolean?,
	type: ("binary" | "text")?,
	skipCrcValidation: boolean?,
	skipSizeValidation: boolean?,
}
function ZipReader.extract(self: ZipReader, entry: ZipEntry, options: ExtractionOptions?): buffer | string
	-- Local File Header format:
	-- Offset  Bytes  Description
	-- 0       4      Local file header signature
	-- 4       2      Version needed to extract
	-- 6       2      General purpose bitflags
	-- 8       2      Compression method (8 = DEFLATE)
	-- 14      4      CRC32 checksum
	-- 18      4      Compressed size
	-- 22      4      Uncompressed size
	-- 26      2      File name length (n)
	-- 28      2      Extra field length (m)
	-- 30      n      File name
	-- 30+n    m      Extra field
	-- 30+n+m  -      File data

	if entry.isDirectory then
		error("Cannot extract directory")
	end

	local defaultOptions: ExtractionOptions = {
		followSymlinks = false,
		decompress = true,
		type = if entry.isText then "text" else "binary",
		skipValidation = false,
	}

	-- TODO: Use a `Partial` type function for this in the future!
	local optionsOrDefault: {
		followSymlinks: boolean,
		decompress: boolean,
		type: "binary" | "text",
		skipCrcValidation: boolean,
		skipSizeValidation: boolean,
	} = if options
		then setmetatable(options, { __index = defaultOptions }) :: any
		else defaultOptions

	local pos = entry.offset
	if buffer.readu32(self.data, pos) ~= SIGNATURES.LOCAL_FILE then
		error("Invalid local file header")
	end

	-- Validate that the version needed to extract is supported
	local versionNeeded = buffer.readu16(self.data, pos + 4)
	assert(MAX_SUPPORTED_PKZIP_VERSION >= versionNeeded, `Unsupported PKZip spec version: {versionNeeded}`)

	local bitflags = buffer.readu16(self.data, pos + 6)
	local crcChecksum = buffer.readu32(self.data, pos + 14)
	local compressedSize = buffer.readu32(self.data, pos + 18)
	local uncompressedSize = buffer.readu32(self.data, pos + 22)
	local nameLength = buffer.readu16(self.data, pos + 26)
	local extraLength = buffer.readu16(self.data, pos + 28)

	pos = pos + 30 + nameLength + extraLength

	if bit32.band(bitflags, 0x08) ~= 0 then
		-- The bit at offset 3 was set, meaning we did not have the file sizes
		-- and CRC checksum at the time of the creation of the ZIP. Instead, they
		-- were appended after the compressed data chunks in a data descriptor

		-- Data Descriptor format:
		-- Offset   Bytes   Description
		-- 0        0 or 4  0x08074b50 (optional signature)
		-- 0 or 4   4       CRC32 checksum
		-- 4 or 8   4       Compressed size
		-- 8 or 12  4       Uncompressed size

		-- Start at the compressed data
		local descriptorPos = pos
		while true do
			-- Try reading a u32 starting from current offset
			local leading = buffer.readu32(self.data, descriptorPos)

			if leading == SIGNATURES.DATA_DESCRIPTOR then
				-- If we find a data descriptor signature, that must mean
				-- the current offset points is the start of the descriptor
				break
			end

			if leading == entry.crc then
				-- If we find our file's CRC checksum, that means the data
				-- descriptor signature was omitted, so our chunk starts 4
				-- bytes before
				descriptorPos -= 4
				break
			end

			-- Skip to the next byte
			descriptorPos += 1
		end

		crcChecksum = buffer.readu32(self.data, descriptorPos + 4)
		compressedSize = buffer.readu32(self.data, descriptorPos + 8)
		uncompressedSize = buffer.readu32(self.data, descriptorPos + 12)
	end

	local content = buffer.create(compressedSize)
	buffer.copy(content, 0, self.data, pos, compressedSize)

	if optionsOrDefault.decompress then
		local compressionMethod = buffer.readu16(self.data, entry.offset + 8)
		local algo = DECOMPRESSION_ROUTINES[compressionMethod]
		if algo == nil then
			error(`Unsupported compression, ID: {compressionMethod}`)
		end

		if optionsOrDefault.followSymlinks then
			local linkPath = buffer.tostring(algo.decompress(content, 0, {
				expected = 0x00000000,
				skip = true,
			}))

			-- Check if the path was a relative path
			if path.isRelative(linkPath) then
				if string.sub(linkPath, -1) ~= "/" then
					linkPath ..= "/"
				end

				linkPath = path.canonicalize(`{(entry.parent or self.root).name}{linkPath}`)
			end

			optionsOrDefault.followSymlinks = false
			optionsOrDefault.type = "binary"
			optionsOrDefault.skipCrcValidation = true
			optionsOrDefault.skipSizeValidation = true
			content =
				self:extract(self:findEntry(linkPath) or error("Symlink path not found"), optionsOrDefault) :: buffer
		end

		content = algo.decompress(content, uncompressedSize, {
			expected = crcChecksum,
			skip = optionsOrDefault.skipCrcValidation,
		})

		-- Unless skipping validation is requested, we make sure the uncompressed size matches
		assert(
			optionsOrDefault.skipSizeValidation or uncompressedSize == buffer.len(content),
			"Validation failed; uncompressed size does not match"
		)
	end

	return if optionsOrDefault.type == "text" then buffer.tostring(content) else content
end

function ZipReader.extractDirectory(
	self: ZipReader,
	path: string,
	options: ExtractionOptions
): { [string]: buffer } | { [string]: string }
	local files: { [string]: buffer } | { [string]: string } = {}
	-- Normalize path by removing leading slash for consistent prefix matching
	path = string.gsub(path, "^/", "")

	-- Iterate through all entries to find files within target directory
	for _, entry in self.entries do
		-- Check if entry is a file (not directory) and its path starts with target directory
		if not entry.isDirectory and string.sub(entry.name, 1, #path) == path then
			-- Store extracted content mapped to full path
			files[entry.name] = self:extract(entry, options)
		end
	end

	-- Return a map of file to contents
	return files
end

function ZipReader.listDirectory(self: ZipReader, path: string): { ZipEntry }
	-- Locate the entry with the path
	local entry = self:findEntry(path)
	if not entry or not entry.isDirectory then
		-- If an entry was not found, we error
		error("Not a directory")
	end

	-- Return the children of our discovered entry
	return entry.children
end

function ZipReader.walk(self: ZipReader, callback: (entry: ZipEntry, depth: number) -> ()): ()
	-- Wrapper function which recursively calls callback for every child
	-- in an entry
	local function walkEntry(entry: ZipEntry, depth: number)
		callback(entry, depth)

		for _, child in entry.children do
			-- ooo spooky recursion... blame this if shit go wrong
			walkEntry(child, depth + 1)
		end
	end

	walkEntry(self.root, 0)
end

export type ZipStatistics = { fileCount: number, dirCount: number, totalSize: number }
function ZipReader.getStats(self: ZipReader): ZipStatistics
	local stats: ZipStatistics = {
		fileCount = 0,
		dirCount = 0,
		totalSize = 0,
	}

	-- Iterate through the entries, updating stats
	for _, entry in self.entries do
		if entry.isDirectory then
			stats.dirCount += 1
			continue
		end

		stats.fileCount += 1
		stats.totalSize += entry.size
	end

	return stats
end

return {
	-- Creates a `ZipReader` from a `buffer` of ZIP data.
	load = function(data: buffer)
		return ZipReader.new(data)
	end,
}
