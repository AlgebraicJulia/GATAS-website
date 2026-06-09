-- lua/auto-gallery.lua
-- Builds a photo gallery at the end of a page from front-matter metadata.

local function meta_string(value)
  if not value then
    return ""
  end
  return pandoc.utils.stringify(value)
end

local function debug_log(message)
  io.stderr:write("[auto-gallery] " .. message .. "\n")
end

local function page_title(doc)
  local title = meta_string(doc.meta.title)
  if title == "" then
    return "(untitled page)"
  end
  return title
end

local function as_list(value)
  if not value then
    return {}
  end

  if type(value) == "table" and value.t == "MetaList" then
    return value
  end

  if type(value) == "table" then
    return value
  end

  return {}
end

local function map_get(map, key)
  if not map then
    return nil
  end

  if type(map) == "table" then
    return map[key]
  end

  return nil
end

local function clamp_heading_level(level)
  if level < 1 then
    return 1
  end
  if level > 6 then
    return 6
  end
  return level
end

local function build_image_block(item, group)
  if type(item) ~= "table" then
    return nil
  end

  local src = meta_string(map_get(item, "src"))
  if src == "" then
    return nil
  end

  local caption = meta_string(map_get(item, "caption"))
  local img_attr = pandoc.Attr("", {}, { group = group })
  local image = pandoc.Image(caption, src, "", img_attr)
  return pandoc.Para({ image })
end

function Pandoc(doc)
  local title = page_title(doc)
  local gallery = doc.meta.gallery
  if not gallery then
    debug_log("no gallery metadata for page: " .. title)
    return doc
  end

  local images_meta = map_get(gallery, "images")
  if not images_meta then
    debug_log("gallery has no images list for page: " .. title)
    return doc
  end

  local images = as_list(images_meta)
  if type(images) ~= "table" or #images == 0 then
    debug_log("gallery images list is empty for page: " .. title)
    return doc
  end

  local columns = tonumber(meta_string(map_get(gallery, "columns"))) or 2
  if columns < 1 then
    columns = 1
  end

  local heading = meta_string(map_get(gallery, "heading"))
  if heading == "" then
    heading = "Photos"
  end

  local heading_level = tonumber(meta_string(map_get(gallery, "heading_level"))) or 3
  heading_level = clamp_heading_level(heading_level)

  local group = meta_string(map_get(gallery, "group"))
  if group == "" then
    group = "my-gallery"
  end

  local image_blocks = {}
  for _, item in ipairs(images) do
    local block = build_image_block(item, group)
    if block then
      table.insert(image_blocks, block)
    end
  end

  if #image_blocks == 0 then
    debug_log("no gallery images processed for page: " .. title)
    return doc
  end

  local gallery_div = pandoc.Div(image_blocks, pandoc.Attr("", {}, { ["layout-ncol"] = tostring(columns) }))
  table.insert(doc.blocks, pandoc.Header(heading_level, heading))
  table.insert(doc.blocks, gallery_div)
  return doc
end