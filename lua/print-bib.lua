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

	local is_metamap = (type(bib_files) == "table" or type(bib_files) == "userdata") and bib_files.t == "MetaMap"
	if is_metamap then
		for _, v in pairs(bib_files) do
			local p = pandoc.utils.stringify(v)
			dbg("Inserting file (map): " .. p)
			table.insert(files, p)
		end
	elseif type(bib_files) == "table" then
		-- Assume it's a list of strings (or Meta objects) – iterate
		for _, b in ipairs(bib_files) do
			local p = pandoc.utils.stringify(b)
			dbg("Inserting file (list): " .. p)
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

	-- Build SimpleTable rows (collect entries with year for sorting)
	local entries = {}

	for i, ref in ipairs(refs) do
		-- Authors
		local authors = {}
		if type(ref.author) == "table" then
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

		-- Year (extract from issued date-parts if available)
		local year_str = ""
		if ref.issued and ref.issued["date-parts"] and ref.issued["date-parts"][1] then
			year_str = tostring(ref.issued["date-parts"][1][1] or "")
		elseif ref.year then
			year_str = tostring(ref.year)
		end

		-- Venue (journal, conference, or speech event)
		local venue_str = ""
		if ref["container-title"] then
			venue_str = tostring_el(ref["container-title"])
		elseif ref["collection-title"] then
			venue_str = tostring_el(ref["collection-title"])
		elseif ref.type == "speech" then
			local ev_title = ""
			if ref["event-title"] then
				ev_title = tostring_el(ref["event-title"])
			end
			local ev_place = ""
			if ref["event-place"] then
				ev_place = tostring_el(ref["event-place"])
			end
			if ev_title ~= "" then
				venue_str = ev_title
				if ev_place ~= "" then
					venue_str = venue_str .. " (" .. ev_place .. ")"
				end
			elseif ev_place ~= "" then
				venue_str = ev_place
			end
		end

		-- DOI (as hyperlink if present, displayed as "DOI")
		local doi_inline = pandoc.Str("")
		if ref.DOI then
			local url = "https://doi.org/" .. tostring_el(ref.DOI)
			doi_inline = pandoc.Link(pandoc.Str("DOI"), url)
		end

		-- Debug line
		local line =
			string.format("%d. %s. %s. %s. %s. %s", i, author_str, title_str, year_str, venue_str, ref.DOI or "")
		dbg("entry " .. i .. ": " .. line)

		-- Determine item type for display
		local item_type = ""
		local t = ref.type or ""
		if t == "article-journal" or t == "journal-article" then
			item_type = "Article"
		elseif t == "paper-conference" or t == "conference-paper" or t == "proceedings" then
			item_type = "Proceedings"
		elseif t == "speech" or t == "presentation" then
			item_type = "Presentation"
		elseif t == "poster" then
			item_type = "Poster"
		elseif t == "preprint" then
			item_type = "Preprint"
		end

		-- Store entry data for later sorting
		local entry = {
			year = year_str,
			item_type = item_type,
			author = author_str,
			title = title_str,
			venue = venue_str,
			doi = doi_inline,
		}
		table.insert(entries, entry)
	end

	-- Sort entries by year descending (numeric; missing years treated as 0)
	table.sort(entries, function(a, b)
		local ya = tonumber(a.year) or 0
		local yb = tonumber(b.year) or 0
		return ya > yb
	end)

	-- Build rows from sorted entries
	local rows = {}
	for _, e in ipairs(entries) do
		local cells = {
			{ pandoc.Plain(pandoc.Str(e.year)) },
			{ pandoc.Plain(pandoc.Str(e.item_type)) },
			{ pandoc.Plain(pandoc.Str(e.author)) },
			{ pandoc.Plain(pandoc.Str(e.title)) },
			{ pandoc.Plain(pandoc.Str(e.venue)) },
			{ pandoc.Plain(e.doi) },
		}
		table.insert(rows, cells)
	end

	-- Build the SimpleTable (no column widths, left-aligned)
	-- Header cells (each a list of Blocks)
	local header_cells = {
		{ pandoc.Plain(pandoc.Str("Year")) },
		{ pandoc.Plain(pandoc.Str("Type")) },
		{ pandoc.Plain(pandoc.Str("Authors")) },
		{ pandoc.Plain(pandoc.Str("Title")) },
		{ pandoc.Plain(pandoc.Str("Venue")) },
		{ pandoc.Plain(pandoc.Str("DOI")) },
	}
	-- Caption as Inlines (empty)
	local caption = pandoc.Inlines({})
	local simple_tbl = pandoc.SimpleTable(
		caption,
		{ pandoc.AlignLeft, pandoc.AlignLeft, pandoc.AlignLeft, pandoc.AlignLeft, pandoc.AlignLeft, pandoc.AlignLeft },
		{ 0, 0, 0, 0, 0, 0 },
		header_cells,
		rows
	)
	local tbl = pandoc.utils.from_simple_table(simple_tbl)
	table.insert(doc.blocks, tbl)

	dbg("filter finished – appended table with " .. #rows .. " rows")
	return doc
end
