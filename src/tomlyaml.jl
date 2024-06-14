using TOML
using YAML

INDIVIDUAL_PAGES=false
INCLUDED_CATEGORIES = ["article", "conference_publication", "conference_presentation"]
OUTPUT_DIR = "publications"

pubtype(t) = begin
  @show t
  lookuptable = Dict(
      "Peer Reviewed Journal Articles" => "article",
      "Peer Reviewed Conference Publications" => "conference_publication",
      "Panels" => "panel",
      "Conference Presentations" => "conference_presentation",
      "Invited Talks" => "talk",
      "Posters" => "poster",
      "Technical Reports" => "report")
  return get(lookuptable, t, "PUBLICATION_TYPE")
end

distinct_keys(type) = begin
  t = pubtype(type)
  println("Processing Publications of Type $t")
  (t, map(type["Activities"]) do p
    sort(collect(keys(p)))
  end |> unique)
end

strip_punc(s) = replace(s, r"[^a-zA-Z0-9_]" => "")
underscore_punc(s) = replace(s, r"[^a-zA-Z0-9_]" => "_")
extract_year(s) = begin
  m = match(r"(20)\d{2}", s)
  if isnothing(m)
    return s
  end
  m.match
end

cv = TOML.parsefile("cv.toml")

# Debugging Info to make sure the keys are correct in the toml file.
map(distinct_keys, cv["Research"]["Categories"])

mkpath(OUTPUT_DIR)

map(cv["Research"]["Categories"]) do type
  t = pubtype(type["Name"])
  if !(t ∈ INCLUDED_CATEGORIES)
    println("Skipping Category: $t")
    return []
  end
  println("Processing Publications of Type $t")
  listing = Dict()
  listing["template"] = "table"
  listing["contents"] = []
  map(type["Activities"]) do p
    # Get the fields we expect
    date = get(p, "Date", "")
    venue = get(p, "Venue", "")
    authors = get(p, "Authors", "")
    title = get(p, "Title", "")
    url = get(p, "URL", "")

    href = "<a href=\"$url\" class=\"btn btn-secondary\">DOI</a>"
    # Normalizing the keys to what the Quarto Template expects
    p["title"] = title
    p["author"] = authors
    p["type"] = t
    p["year"] = @show extract_year(date)
    p["date"] = date
    p["publication"] = venue
    if contains(url, "doi")
      p["doi"] = p["URL"]
    end
    if contains(url, "arxiv") || contains(url, "arXiv")
      p["preprint"] = p["URL"]
    end
    p["materials"] = ""
    p["toc"] = false
    p["href"] = href


    if INDIVIDUAL_PAGES
      # writing individual YAML files for each page
      s = YAML.yaml(p)
      s = "---\n$s---\n\n"# Abstract\nAbstract to be entered."
      pagetitle = p["Title"]
      slug = replace(pagetitle, " "=>"_") |> lowercase |> strip_punc
      file = "$slug.md"
      folder = joinpath(OUTPUT_DIR,t)
      mkpath(folder)
      path = joinpath(folder, file)
      @show path
      open(path, "w") do fp
        write(fp, s)
      end
    else
    # write one YAML file for the contents of all pages.
      push!(listing["contents"], p)
    end
  end
  if !INDIVIDUAL_PAGES
    mkpath(joinpath(OUTPUT_DIR, t))
    YAML.write_file(joinpath(OUTPUT_DIR, t,"listing.yaml"), listing["contents"])
  end
end
