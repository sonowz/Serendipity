# Serendipity : Random Science Pack Recipes in Factorio

![factorio 0.16](https://badgen.net/badge/factorio/0.16/orange)
![release](https://badgen.net/github/release/dnsdhrj/serendipity)

<img src="https://github.com/dnsdhrj/Serendipity/blob/master/doc/images/sci1-1.png" align="left">
<img src="https://github.com/dnsdhrj/Serendipity/blob/master/doc/images/sci1-2.png" align="left">
<img src="https://github.com/dnsdhrj/Serendipity/blob/master/doc/images/sci2.png">
<img src="https://github.com/dnsdhrj/Serendipity/blob/master/doc/images/sci3.png" align="left">
<img src="https://github.com/dnsdhrj/Serendipity/blob/master/doc/images/hitech.png">


## Features
- Random science pack recipe that is highly *reasonable*
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
  - Turning on `double recipe` option is recommended in such cases, so that you can discard that recipe

## Possible Features
- Generate alternative science pack recipe (which is harder, but low cost)
- Support fixed recipe so that game doesn't break when items are changed by other mods
