# IDEAS

## 1 BIT PATTERNS

> When there is only 1 color used on transparent background 
> or, there is only 1 color used on a background of 1 color
> for a pattern within a dset pattern...

### HOW TO KNOW FG VS BG ON 1 BIT PATTERN
- The number of pixels in the pattern that are greatest in number map to current BG color
  - The user can choose a transparent BG
- The number of pixels in the pattern that have less pixels than the background color, map to current FG color
- Make the bin previews for that pattern always respect the current FG and BG color

### 1BIT SIGIL
- Draw a little sigil of a 1 in a rect in the top left of the bin preview [1b] to show that it's a 1 bit pattern
  - Do this using Tiny 5 font
    - Make the outline of this icon configurable in #THEME.cfg - 1BIT_PTN_SIGIL_BORDER_FG
    - Make the color of the [1b] configurable in #THEME.cfg - 1BIT_PTN_SIGIL_FONT_FG
    - Make the background color of the [1b] configurable in #THEME.cfg - 1BIT_PTN_SIGIL_BG
    - Make the padding around the 1b text (between the [ ] on all sides) configurable in #THEME.cfg 1BIT_PTN_SIGIL_PADDING

### WORKFLOW REASON
- Always use the mapped FG color for the non transparent pixels of the pattern when drawing 1 bit patterns 
- Always use the mapped BG color for the transparent pixels of the pattern when drawing 1 bit patterns
  - Since there is only one color on transparency...
    - This will make it faster and explicit for how it works vs. a behind-the-scenes hidden feature
    - We currently turn on the foreground color for drawing but not in the bin preview for this kind of setup
    - The issue with the way we are doing it now is when I change to a different 1 bit pattern
      - It uses the patterns color
      - Not my chosen FG color



## TEXT FORMATTING

### ATTRIBUTES

#### Per text entry:

- Font
- Font size
- Line Height
- Baseline
- Kerning
  - Character spacing between each (custom tuning)
- [x] Font Hinting
- [x] Monospace

#### Per selected character (or all if none selected):

- FG Color
- BG Color (inc. transparent)
- BOLD
- Italic
- Underline
- Strikethrough
