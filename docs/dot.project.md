# It's the Dotfile Project!
...it's the TODO-tfile.
...the to-DOT-file...
...the to-doot. file.

### === Inbox ===

nested tmux sessions, to keep timers up top

* [ ] fix ls colors
  * white on green for directories is abysmal
* [ ] tmux pane switching when CTRL is held, too.
* [ ] shortcuts for:
  * [ ] this damn checkbox
  * [ ] tmux sync panes
    * [ ] can I mark panes to sync?
  * [ ] change vim dracula theme so that Markdown highlights will pop more.
    * I'm lookin' at you, h1.
  * [ ] :noh

change all vim on/off bindings to use "i" and "o"
change all tab left/right bindings to use "m" and "n"


## Dotfile Management

* [X] install dotbot!
* [ ] figure out dotbot!
* [ ] rename to .dotdot
* [ ] separate dots from new Arch install
* [X] env variables for dotdots
* [ ] fix omz symlink
* [ ] fix .gitignore mess
* [ ] fix git submodule mess 


# Terminal Environment

## Zsh and OMZ

* [X] dracula theme. minimal powerline.
* [ ] git-prompt
* [ ] learn about `zcompile`
* [ ] zsh-poetry needs an install handler (gh:darvid/zsh-poetry)
* [X] need a `fzf` theme
* [ ]  
* [ ]  


## tmux 

* [X] I need to disable <C-Left, Right, ...> for tmux pane nav...
* [X] alias to start a new tmux session with given name
* [ ] needs to stop renaming my windows.
* [ ] more functional statusline icons.
* [ ] padding each pane by a couple characters.
* [ ] give panes a name
* [ ] need a whole category of custom pane resizing keybinds
* [ ] make pane borders clear, except active
* [ ] okay, but first define a shortcut group for this kind of thing.
* [ ] if I've got the path of a any active pane, can I run commands like, oh, I dunno,
  git status, and display it in the statusline for each pane?
  I wonder if I could steal from gitprompt to write that
* [ ] tmux session manager
* [ ] tmux pane padding
* [ ] I'd really like the active pane title to change to a different color
* [ ] remove arrows from tmux window bar
* [ ] maybe changing that will fix the weirdness with the `pane` indicator, too.
* [ ] remove whole third line
* [ ] either change the date to MM/DD/YY, or add it alongside

> NOTE: Preferred `strftime` format:  
>   Time: 8:45pm      -  "%l:%M%P"
>   Date: Thu, Mar 03 - "%a, %b %d"  


### Control Scheme Ideas

Rename {session, window, pain}
* prefix, C-r, {s,w,p}
  * rename



## nvim

* [ ] code completion needs to be turned the fuck off.
  * [ ] but I'd like to know the shortcuts for fzf and go-to-definition.
*   [ ] and python symbol autocomplete.
* [ ] change command character from : to ;
* [ ] change normal mode cursor, so that it doesn't obscure the character beneath
* [X] colorcolumn=88
* [X] set number
* [X] set relativenumber
* [ ] markdown helper plugin
  * [ ] or just a `ftplugin` to set syntax for .md's 
* [ ] statusline oughta make some damn sense to me.
* [X] enable scroll pass-through from tmux
  *  `:set mouse=a` in vim. works like a charm.
* [X] why isn't my config loading properly for new sessions?
* [ ] set colorcolumn's color
* [ ] autosave
* [ ] scrollbars
* [X] `set scrolloff=30`
* [ ] figure out how to set indentation amounts, and per filetype.
  * [ ] set it to 2 spaces for markdown, 4 for python, 2 for default.
  * [ ] is this also where you'd adjust how <TAB> is interpreted?
* [ ] set 
* [ ]  
* [ ] god, airline's vim theme is driving me MAD.
* [ ] change vim window split to a different color. transparent, maybe?



### ftplugins

* markdown
  * checkbox shortcuts
    * check, create, delete

syntax
  * .zshrc -> zsh
  * .tmux.conf -> tmux



## nnn / ranger

* [ ] map a shortcut for opening a file in a separate tmux pane
  [StackExchange guide](https://unix.stackexchange.com/questions/82632/tmux-ranger-integration-opening-text-files-in-new-panes)
* [ ] theme ranger's syntax highlighting
* [ ] I need a way to quickly open files with a certain command.
  * e.g. `nnn` needs a fast way to open .md files with `glow -p`


## `most` / `less` / $PAGER

* [ ] `most` needs vim keybindings or `less` needs a theme.


## misc

* [ ] draculize neofetch
* [ ] suitable htop replacement

## `neomutt`

## Services

* mosh


# DE/WM

Let's bring this consistent desktop experience to... everything.


* [ ] day and night wallpapers. timer-automated slideshows for each.
  to that end: maybe let's split day into work hours and off-hours
  and sunrise. and sunset.
  and weekends. and holidays.
  and all through October.
  Well. Now this is a wallpaper engine for date/time/weather.
  ... that sure didn't take much.

## Windows

I haven't even LOOKED for dracula for Windows...
I bet AutoHotKey can give me window tiling, too. 

## i3

I need i3 to mimic my tmux config as much as possible.
I'm talkin' the exact same bar. 
I'm talkin' the exact same widgets and floating interfaces.
I'm talkin' the exact same lock window and power menu.



# Applications

## Windows Terminal
[X] kill bell sound.


## Chrome/Brave

[ ] dracula colors for dark mode extension
[ ] vim naigation. yep. I said it.
