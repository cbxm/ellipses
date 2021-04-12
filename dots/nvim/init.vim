" ========== .dotdot, it's time we talked vim. ==========
"
" Welcome to the scaffolding for my vim config!
"
" This guys sources a few different files. Or, he will eventually.
"
"


" ========== Plugins ==========

call plug#begin('~/.config/nvim/plugged')

" === Theme
Plug 'dracula/vim', { 'as': 'dracula'  }
Plug 'bling/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
" Plug 'edkolev/tmuxline.vim' [DEPRECATED]

" === Nav
Plug 'preservim/nerdtree'


" === Dev
Plug 'jiangmiao/auto-pairs'
" Plug 'airblade/vim-gitgutter'  " so obnoxious!
Plug 'davidhalter/jedi-vim'
Plug 'jkramer/vim-checkbox'
Plug 'tpope/vim-dadbod'
Plug 'kristijanhusak/vim-dadbod-ui'


call plug#end()
 

" ========== Personal Config ==========

" === Theme ============================================================================
" Dracula everything, obviously.
colorscheme dracula


" === UI ===============================================================================
" Set sidebar numbers.  
" set number
" set relativenumber
" NOTE: I don't want these on by default. I have keybinds for them now.


" cursor padding at the top and bottom when scrolling
set scrolloff=8
" I like to be reminded how wide my files are.
" ...thanks, Python.
" NOTE: Off by default. user <leader>nn to turn them (and line numbers) on.
" set colorcolumn=89
" set the color of the ruler on the right.
hi ColorColumn ctermbg=236 guibg=236
" Tell word wrap to break entire words
set linebreak


" === vim-markdown configuration =======================================================
let g:heckbox_states = [' ', 'X']
let g:insert_checkbox_prefix = '* '
let g:insert_checkbox_suffix = ' '


" === airline ==========================================================================
" Show buffers
let g:airline#extensions#tabline#enabled = 1
" How filenames are displayed
let g:airling#extensions#tabline#formatter = 'jsformatter'

" === Controls =========================================================================
" Set leader to semicolon
let mapleader = ";"
" Map `;s` to quick-save
nnoremap <Leader>s :update<CR>
" Cycle through buffers with <Leader>bb and bv
nnoremap <Leader>bb :bnext<CR>
nnoremap <Leader>bv :bprevious<CR>
" Shortcut to buffer list
nnoremap <Leader>ba :buffers<CR>

" === SORT LATER =======================================================================
set mouse=a
set ignorecase
set smartcase
set signcolumn=yes:1		" left padding

noremap <silent> <Leader>nn :set number<bar>set relativenumber<bar>set colorcolumn=89<CR>
noremap <silent> <Leader>nf :set nonumber<bar>set norelativenumber<bar>:set colorcolumn=""<CR>
noremap <silent> <Leader>cn :set colorcolumn=89<CR>
noremap <silent> <Leader>cf :set colorcolumn=""<CR>

" Allow buffers with unwritten changes to move to the background when
" switching to another buffer.
set hidden

" Shortcut to reload init.vim 
nnoremap <Leader>vr :source ~/.config/nvim/init.vim<CR>


" CTRL-Backspace an entire word
imap <C-BS> <C-W>
" ^^ didn't work...

set clipboard=unnamedplus


" Something to append = signs to the line.
" I don't completely understand it yet.
" See here:
" https://vi.stackexchange.com/questions/10500/insert-character-until-column-number
function! Append(c)
    exec 'norm '.(&cc - strlen(getline('.'))).'A'.nr2char(a:c)
endfunction
nnoremap <expr> m ':call Append('.getchar().")\<CR>"')'


" okay, it's my own attempt to write system yank shortcuts.
nnoremap <Leader>y "*y
nnoremap <Leader>Y "+y
vnoremap <Leader>y "*y
vnoremap <Leader>Y "+y

nnoremap <Leader>p "*p
nnoremap <Leader>P "+p
vnoremap <Leader>p "*p
vnoremap <Leader>P "+p


" ...and a voila.

nnoremap <Leader>ho :noh<CR>
