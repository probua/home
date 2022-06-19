set number
set relativenumber
set mouse=a
set numberwidth=1
set clipboard=unnamed
set showcmd
set ruler
set encoding=utf-8
set showmatch
set sw=4 
set laststatus=2
set splitbelow
set splitright
set cursorline

set termwinsize=10*0
"set noshowmode
syntax enable

call plug#begin('~/.vim/plugged')

" Temas
"Plug 'morhetz/gruvbox'

" Languages
Plug 'sheerun/vim-polyglot'

" IDE
Plug 'easymotion/vim-easymotion'
Plug 'scrooloose/nerdtree'
Plug 'christoomey/vim-tmux-navigator'

call plug#end()

"colorscheme gruvbox
"let g:gruvbox_contrast_dark = "hard"
let NERDTreeQuitOnOpen=1
let mapleader=" "

" Hotkeys
nmap <Leader>s <Plug>(easymotion-s2)
nmap <Leader>nt :NERDTreeFind<CR>
nmap <c-b> :NERDTreeToggle<CR>
nmap <c-t> :below terminal<CR>

" Tabs
nmap <tab> >>
nmap <s-tab> <<
vmap <tab> >gv
vmap <s-tab> <gv

" Split resize
nmap <s-left> 1<c-w><
nmap <s-right> 1<c-w>>
nmap <s-up> 1<c-w>+
nmap <s-down> 1<c-w>-

" Faster scrolling
nmap <c-up> 10k
nmap <c-down> 10j

cnoreabbrev nt NERDTreeToggle
command! NT :NERDTreeToggle
command! W :w
command! Wq :wq
command! WQ :wq
command! Q :q

" Alt-arrows
nmap <a-left> <c-h>
nmap <a-right> <c-l>
nmap <a-up> <c-k>
nmap <a-down> <c-j>

nmap <Leader>vs :vsplit<CR>
nmap <Leader>sp :split<CR>


