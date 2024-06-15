using YAML
INPUT_DIR = "publications"
OUTPUT_DIR = "project"

paths = joinpath.(INPUT_DIR, ["article", "conference_publication", "conference_presentation"], "listing.yaml")

deca = []
algopt = []

map(paths) do pth
  @show pth
  data = YAML.load_file(pth)
  map(data) do record
    author = @show record["author"]
    if contains(author, "Morris") || (contains(author, "Baas") & !contains(author, "Libkind"))
      push!(deca, record)
    end
    if contains(author, "Hanks") & !contains(author, "Brown") || contains(author, "Libkind")
      push!(algopt, record)
    end
    return record
end
end;

map(["decapodes.yaml" => deca, "optimization.yaml"=>algopt]) do (listing, data)
  YAML.write_file(joinpath(OUTPUT_DIR, listing), data)
end