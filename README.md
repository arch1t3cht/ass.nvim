# ass.nvim
A `neovim` plugin for editing `ass` subtitles. Main features are conceals, some basic line editing commands, playing video and audio, as well as a split editing mode allowing one to efficiently copy lines from one file to another.

## Prerequisites
`ass.nvim` requires neovim 0.5 or above, with `python3` support. For playing lines or showing video, `mpv` is required.

## Installation
Install with your favourite plugin manager, e.g. vim-plug:
```vim
Plug 'arch1t3cht/ass.nvim`
```
Then initialize the plugin as described below in configuration.

## Configuration & Usage
To initialize the plugin, write the following in `~/.config/nvim/init.lua`:
```lua
require'ass'.setup({
    conceal = true,
    mappings = true,
    remap = true,
})
```
The following is the full list of all configuration options, together with their default values:
```lua
{
    conceal = false,      -- whether to automatically enable conceal for .ass files
    mappings = false,     -- whether to create keybindings for the defined commands
    remap = false,        -- whether to remap existing keybindings
    mpv_options_video     -- options passed to mpv when previewing video
      = {"--pause"},
    mpv_options_audio     -- options passed to mpv when playing audio
      = {"--no-video", "--no-config", "--really-quiet"},
    line_hook             -- Filter hook to be run on the results of split editing, or manually via :AssFilter
      = function(line, oldline) return line end
}
```

More precise and flexible configuration options for mapping commands might be added in the future.

### Conceal
If `conceal = true` is set in the configuration, then `conceallevel` and `concealcursor` will be set when editing `ass` files. This will hide the metadata of any dialogue lines and replace them with the shortcut `D: `. In normal mode, this will include the currently selected line. To view the entire line, one can either switch to visual or insert mode, or use keybindings to toggle `conceallevel` and `concealcursor`.

### Modified mappings
if `remap = true` is set in the configuration, then when editing `ass` files, some line-based keybinds of vim will be replaced by commands more appropriate to the file format:
- instead of jumping to the first non-whitespace character in the line, `_` will jump to the beginning of the line text
- similarly, `I` will enter insert mode at the beginning of the line text, instead of the beginning of the buffer line
- instead of joining entire lines, `J` will join the texts of dialogue lines, keeping the start time of the first line, and the end time of the last line. This works both in normal and visual mode.

### Defined mappings
if `mappings = true` is set in the configurations, then keymaps will be created for various versions of various commands:

| Key | Command | Description |
| --- | ------- | ----------- |
|`<leader>av`|`:AssShow`| Show the current line in a video player |
|`<leader>as`|`:AssPlay line`| Play the current line |
|`<leader>at`|`:AssPlay all`| Play audio starting from the current line |
|`<leader>ae`|`:AssPlayBG begin`| Play the beginning of the current line |
|`<leader>ad`|`:AssPlayBG end`| Play the end of the current line |
|`<leader>aq`|`:AssPlayBG before`| Play the audio just before the current line |
|`<leader>aw`|`:AssPlayBG after`| Play the audio just after the current line |
|`<leader>ax`|`:AssLineSplit`| Split the current line at the cursor, and replace the following line with the second half |
|`<leader>af`|`:AssFilter`| Run the defined edit hook function on the current line, or the selected range |
|`<CR>`|`:AssReplaceMove`| When split editing, replace the left line by the right line and move both cursors |
|`<BS>`|`:AssReplace:AssSplitDown`| When split editing, replace the left line by the right line and only advance the right cursor |
|`<Tab>`|`:AssAppend`| When split editing, append the left line to the right line and only advance the right cursor |
|`<M-k>`|`:AssSplitUp`| When split editing, move the right cursor up |
|`<M-j>`|`:AssSplitDown`| When split editing, move the right cursor down |
|`<C-j>`|`j:AssSplitUp`| When split editing, move the left cursor up
|`<C-k>`|`k:AssSplitDown`| When split editing, move the left cursor down |

After `<leader>a`, the keybinds for playing audio match the analogous keybinds for Aegisub. See below for detailed descriptions of the commands.

## Commands
### Editing lines
The commands `:AssJoin` and `:AssJoinRange` accept a count and a range respectively, and join the described set of subtitle lines into one. They are the backend to the modified `J` command defined above - respectively in normal and in visual mode.

Similarly, the commands `:AssFilter` and `:AssFilterRange` respectively accept a count and a range, and apply the defined filter function `line_hook` to the described set of lines.

The command `:AssLineSplit` splits the current line at the cursor position, replacing the current line with the left half and the following line with the right half. This is useful when during split editing, two consecutive lines on the left are translated to a single joined line on the right.

### Showing or playing lines
For these commands to work, `mpv` needs to be installed, and an "Audio File" or resp. "Video File" needs to be given in the subtitle file (i.e. as saved by Aegisub in `[Aegisub Project Garbage]`).

The command `:AssShow` opens a paused video seeked to the beginning of the current line.

The commands `:AssPlay <mode>` and `:AssPlayBG <mode>` play audio related to the current line as described by `<mode>`, where `<mode>` is one of `line`, `all`, `begin`, `end`, `before`, `after` - see above for their meanings. The command `:AssPlay` runs in the foreground and will interrupt editing in the meantime, but can hence be stopped using `Ctrl+C`. The command `:AssPlayBG` will play the audio asynchronously in the background, which cannot be interrupted except by manually killing `mpv`. With the default mappings, the modes whose audio length is bounded independently of the line are played in the background, while the others are played in the foreground.

### Split editing
This feature was the main motivation for creating this plugin. Using `:AssSplit <file>` one can open a second subtitle file in a vertical split. This is intended for repeatedly copying or appending the text of lines in the right buffer to lines in the left buffer, as happens when translating timed subtitles using possibly differently timed and split lines from another file.

While the right buffer is also writeable, the intended use of split subtitle editing is for editing the left (i.e. the original) buffer. Thus, the user should usually have their cursor in the left window, unless when adjusting the cursor position in the right window.

### Keybinds

Following this convention, the current line in the right window will be highlighted, and the (vertical) cursor position in the right window will follow any (vertical) moves made by the cursor in the left window (but one can move the cursor in the right window freely when switching to the window). When `mappings = true` is set in the configuration, the keybinds `<C-j>`, `<C-k>` and `<M-j>`, `<M-k>` move only the cursor in the left, resp. right window. Similarly, `<M-e>`, `<M-y>` as well as `<M-d>`, `<M-i>` scroll the right buffer analogously to `<C-e>`, `<C-y>`, `<C-d>`, and `<C-u>`. [`<M-i>` has been used instead of `<M-u>` because the latter does not work for some unknown reason]

Furthermore, the following keybinds can be used for copying lines from the left to the right:
- `<CR>` replaces the text of the left line with that of the right line, and advances both cursors by one line. Can be used with a count.
- `<Tab>` appends the text of the right line to the left line, and advances the right cursor by one line. Can be used with a count.
- `<BS>` replaces the text of the left line with that of the right line, and advances only the right cursor by one line.
Note that while all these commands can be undone, the cursor position in the right window will not be restored when undoing `<Tab>` or `<BS>` (since I do not see how this could be realized).

#### Editing hook
By setting the config option `line_hook` to a user-defined lua function, a filter can be defined that will be applied every time a line on the left is modified using a line on the right. This hook can also be changed during runtime, by writing to `require'ass'.opts.line_hook`.

The given function `line_hook(line, oldline)` should accept two argument - `line` being the new `.ass` line (including all `.ass` fields), and `oldline` being the line before the modification. To modify the actual dialogue text, two helper functions `ass.get_line_dialogue(line)` and `ass.set_line_dialogue(line, diag)` are provided (where `ass` is obtained by `require'ass'`). The latter function returns the modified line without modifying the input arguments. Both functions return `nil` if the line is of invalid format.

This feature is intended for automatic processing of lines, like adding effects or spellchecking. The following is a simple example:
```lua
line_hook = function(line, oldline)
    local ass = require'ass'
    -- normalize some terms to American English
    return ass.set_line_dialogue(line, ass.get_line_dialogue(line)
        :gsub("colour", "color")
        :gsub("Colour", "Color")
        :gsub("flavour", "flavor")
        :gsub("Flavour", "Flavor")
    )
end,
```

#### Commands

The following commands are defined for editing subtitles in split windows
| Command | Description |
| ------- | ----------- |
|`:AssSplit <file>`| Open a new split window and read the given file |
|`:AssReplaceMove`| Takes a count n, and replace the left n lines at the cursor by the right n lines at the cursor, and move both cursors to the lines following this range. |
|`:AssAppend`| Takes a count n, and appends the right n lines at the cursor to the left line and moves the right cursor to the line following this range. |
|`:AssReplace`| Replaces the line at the left cursor by the line at the right cursor. |
|`:AssSplitUp`| Move the right cursor up by the given amount of lines (default=1) |
|`:AssSplitDown`| Move the right cursor down by the given amount of lines (default=1) |

The split window can be closed normally with `:q`.

## Acknowledgements
The syntax file is taken from [joeky888's Repository](https://github.com/joeky888/Ass.vim). Thanks to [PhosCity](https://github.com/PhosCity) for testing and other suggestions.
