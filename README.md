# themeshow.nvim

Simple, fun theme browsing and selection for Neovim.

Philosophy: make theme exploration feel playful and fast. You should be able to scan a few favorites, expand to all available schemes if you want, and commit your choice in seconds.

## Features
- starts with a small curated list, expands to all installed colorschemes on demand
- left/right to cycle, enter to save, esc to cancel
- optional auto-advance mode for quick browsing
- writes your chosen theme back to `init.lua`

## Requirements
- Neovim 0.8+

## Installation (lazy.nvim)

```lua
{
  "GiantRavens/themeshow",
  config = function()
    require("themeshow").setup()
  end,
}
```

## Usage

Commands:
- `:ThemeShow` start manual browsing (no auto-advance)
- `:ThemeShowAuto [ms]` start auto-advance (default 2000 ms)
- `:ThemeShowStop` stop without saving

Keys while browsing:
- `Right` next theme
- `Left` previous theme
- `Enter` set current theme as default (writes to `init.lua`)
- `Esc` cancel

## How it decides which themes to show
- starts with a small list of your favorites
- when you cycle past the end, it expands to all available colorschemes

## Help docs
- If `:help themeshow` doesn’t work, run `:helptags` in Neovim to generate help tags.

## Customization
- edit the base list inside `lua/themeshow.lua`
- change auto-advance timing: `:ThemeShowAuto 1500`

## License
MIT
