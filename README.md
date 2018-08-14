# Serendipity : Random Science Pack Recipes in Factorio

## Features
- Random science pack recipe that is highly resonable
- You will get recipe in which is similar to original recipe:
  - Total raw resource count (ex: `iron ore`, `coal`, `crude oil`)
  - Total time to produce
  - Complexity
- Set recipe difficulty
- Set random seed to get same recipe as before
- Mod support

## Notes
- Random seed must be changed in mod settings to generate new recipes
- Currently supports vanilla science pack only (ex: module lab from Bob's mod is not randomized)

## Compatibility
- Incompatible with mods that **removes** vanilla science pack item
  - Mods that **add** science pack item is compatible (ex: Bob's mod)
- Mods that adds ridiculous item chain or tech might result in ridiculous recipe
  - For Bob's mod, `raw diamond` could appear in science pack 1
  - For Bob's mod, `tungstic acid barrel` could appear in science pack 2
  - Turning on `double recipe` option is recommended in such mods, so that you can discard that recipe

## Possible Features
- Generate alternative science pack recipe (which is harder, but low cost)
