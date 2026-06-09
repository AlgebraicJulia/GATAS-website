-- lua/auto-gallery.lua
-- Builds a photo gallery at the end of a page from front-matter metadata.

local function meta_string(value)
  if not value then
    return ""
  end
  return pandoc.utils.stringify(value)
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

function Pandoc(doc)
  local gallery = doc.meta.gallery
  if not gallery or gallery.t ~= "MetaMap" then
    return doc
  end

  local images = gallery.images
  if not images or images.t ~= "MetaList" or #images == 0 then
    return doc
  end

  local columns = tonumber(meta_string(gallery.columns)) or 2
  if columns < 1 then
    columns = 1
  end

  local heading = meta_string(gallery.heading)
  if heading == "" then
    heading = "Photos"
  end

  local heading_level = tonumber(meta_string(gallery.heading_level)) or 3
  heading_level = clamp_heading_level(heading_level)

  local group = meta_string(gallery.group)
  if group == "" then
    group = "my-gallery"
  end

  local image_blocks = {}
  for _, item in ipairs(images) do
    if item.t == "MetaMap" then
      local src = meta_string(item.src)
      if src ~= "" then
        local caption = meta_string(item.caption)
        local img_attr = pandoc.Attr("", {}, { group = group })
        local image = pandoc.Image(caption, src, "", img_attr)
        table.insert(image_blocks, pandoc.Para({ image }))
      end
    end
  end

  if #image_blocks == 0 then
    return doc
  end

  local gallery_div = pandoc.Div(image_blocks, pandoc.Attr("", {}, { ["layout-ncol"] = tostring(columns) }))
  table.insert(doc.blocks, pandoc.Header(heading_level, heading))
  table.insert(doc.blocks, gallery_div)
  return doc
end