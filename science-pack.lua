-- This can't be generated dynamically,
-- since it needs human thinking
-- TODO: find a way to embrace new science pack mod

-- name: Name of science pack
-- depends: All packs that are prerequisites
--          ex) Production and high-tech mutually require each other, since they are mutually independant
-- force_strict: Always enable strict mode
function get_base_science_pack_meta()
  return {
    ["science-pack-1"] = {
      name = "science-pack-1",
      force_strict = true -- This should be easy recipe
    },
    ["science-pack-2"] = {
      name = "science-pack-2",
      depends = {"science-pack-1"},
    },
    ["science-pack-3"] = {
      name = "science-pack-3",
      depends = {"science-pack-1", "science-pack-2"}
    },
    ["military-science-pack"] = {
      name = "military-science-pack",
      depends = {"science-pack-1", "science-pack-2"}
    },
    ["production-science-pack"] = {
      name = "production-science-pack",
      depends = {"science-pack-1", "science-pack-2", "science-pack-3", "military-science-pack", "high-tech-science-pack"},
    },
    ["high-tech-science-pack"] = {
      name = "high-tech-science-pack",
      depends = {"science-pack-1", "science-pack-2", "science-pack-3", "military-science-pack", "production-science-pack"},
    }
  }
end