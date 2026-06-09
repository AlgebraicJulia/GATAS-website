-- lua/print-bib.lua
-- Simple filter: dump the bibliography (meta.references) into the document body as plain text.
-- Verbose debugging info is printed to stderr (captured by Quarto).

-- Helper: turn any pandoc element into a plain string.
local function tostring_el(el)
	if not el then
		return ""
	end
	return pandoc.utils.stringify(el)
end

-- Simple debug logger (writes to stderr).
local function dbg(msg)
	io.stderr:write("[print-bib] " .. tostring(msg) .. "\n")
end

function Pandoc(doc)
	dbg("filter started")

	local meta = doc.meta
	-- Load bibliography entries from the files listed in metadata.bibliography
	local bib_files = meta.bibliography
	if not bib_files then
		dbg("no bibliography files listed in metadata")
		return doc
	end

	-- Gather file paths. Handles a plain list, a map (multibib), or a single entry.
	local files = {}
	if type(bib_files) == "table" then
		-- Assume it's a list of strings (or Meta objects) – iterate
		for _, b in ipairs(bib_files) do
			local p = pandoc.utils.stringify(b)
			dbg("Inserting file (list): " .. p)
			table.insert(files, p)
		end
	elseif type(bib_files) == "userdata" and bib_files.t == "MetaMap" then
		for _, v in pairs(bib_files) do
			local p = pandoc.utils.stringify(v)
			dbg("Inserting file (map): " .. p)
			table.insert(files, p)
		end
	else
		local p = pandoc.utils.stringify(bib_files)
		dbg("Inserting single file: " .. p)
		table.insert(files, p)
	end

	dbg("Collected bibliography files: " .. table.concat(files, ", "))

	local refs = {}
	for _, path in ipairs(files) do
		dbg("Reading bibliography file: " .. path)
		local f = io.open(path, "r")
		if f then
			local content = f:read("*a")
			f:close()
			local parsed = pandoc.json.decode(content)
			if parsed and type(parsed) == "table" then
				for _, entry in ipairs(parsed) do
					table.insert(refs, entry)
				end
			else
				dbg("Failed to parse JSON from " .. path)
			end
		else
			dbg("Unable to open file: " .. path)
		end
	end

	dbg("found " .. #refs .. " bibliography entries")

	-- Build SimpleTable rows
	local rows = {}

	for i, ref in ipairs(refs) do
		-- Authors
		local authors = {}
		if ref.author then
			for _, a in ipairs(ref.author) do
				local name = ""
				if a.given then
					name = name .. tostring_el(a.given) .. " "
				end
				if a.family then
					name = name .. tostring_el(a.family)
				end
				table.insert(authors, name)
			end
		elseif type(ref.author) == "string" then
			-- already a plain string
			table.insert(authors, ref.author)
		end
		local author_str = table.concat(authors, ", ")

		-- Title
		local title_str = tostring_el(ref.title)

		-- Year
		local year_str = ""
		if ref.issued and ref.issued[1] and ref.issued[1]["date-parts"] then
			year_str = tostring(ref.issued[1]["date-parts"][1][1] or "")
		end

		-- DOI (as plain URL)
		local doi_str = ""
		if ref.DOI then
			doi_str = "https://doi.org/" .. tostring_el(ref.DOI)
		end

		-- Debug line
		local line = string.format("%d. %s. %s. %s. %s", i, author_str, title_str, year_str, doi_str)
		dbg("entry " .. i .. ": " .. line)

		-- Append row cells (each cell is a list containing a Plain block)
		local cells = {
			pandoc.Plain(pandoc.Str(author_str)),
			pandoc.Plain(pandoc.Str(title_str)),
			pandoc.Plain(pandoc.Str(year_str)),
			pandoc.Plain(pandoc.Str(doi_str))
		}
		table.insert(rows, cells)
	end

	-- Header for the table (unused, kept for reference)
	local header = {
		pandoc.Str("Authors"),
		pandoc.Str("Title"),
		pandoc.Str("Year"),
		pandoc.Str("DOI")
	}

	-- Insert heading before the table
	table.insert(doc.blocks, pandoc.Header(1, pandoc.Str("Bibliography Dump (debug)")))
	-- Build the SimpleTable (no column widths, left-aligned)
	-- Header cells (each a list of Blocks)
	local header_cells = {
		{pandoc.Plain(pandoc.Str("Authors"))},
		{pandoc.Plain(pandoc.Str("Title"))},
		{pandoc.Plain(pandoc.Str("Year"))},
		{pandoc.Plain(pandoc.Str("DOI"))}
	}
	-- Caption as Inlines (empty)
	local caption = pandoc.Inlines({})
	local simple_tbl = pandoc.SimpleTable(
		caption,
		{pandoc.AlignLeft, pandoc.AlignLeft, pandoc.AlignLeft, pandoc.AlignLeft},
		{0,0,0,0},
		header_cells,
		rows
	)
	local tbl = pandoc.utils.from_simple_table(simple_tbl)
	table.insert(doc.blocks, tbl)

	dbg("filter finished – appended table with " .. #rows .. " rows")
	return doc
end
