#!/bin/bash

# Note: for this to work successfully in Putty, set Terminal-type String as "xterm-256color" (in Connection>Data)

# install pathogen and initialize .vimrc
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSlo ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim
git clone https://github.com/altercation/vim-colors-solarized.git ~/.vim/bundle/vim-colors-solarized
git clone https://github.com/morhetz/gruvbox.git ~/.vim/bundle/gruvbox
echo "execute pathogen#infect()
if !exists(\"g:syntax_on\")
    syntax_on
endif
filetype plugin indent on
set background=dark" > ~/.vimrc
# choose your color scheme:
# echo "colorscheme solarized" >> ~/.vimrc
echo "colorscheme gruvbox" >> ~/.vimrc
# install airline
git clone https://github.com/vim-airline/vim-airline ~/.vim/bundle/vim-airline
git clone https://github.com/vim-airline/vim-airline-themes ~/.vim/bundle/vim-airline-themes
echo "let g:airline_solarized_bg='dark'" >> ~/.vimrc
# add glyph fonts (those arrows in the airline)
git clone https://github.com/powerline/fonts.git --depth=1
bash fonts/install.sh
rm -rf fonts
echo "let g:airline_powerline_fonts = 1" >> ~/.vimrc
# add git status to airline
git clone https://github.com/tpope/vim-fugitive.git ~/.vim/bundle/vim-fugitive
vim -u NONE -c "helptags ~/.vim/bundle/vim-fugitive/doc" -c q
# add NERDTree
git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree
vim -u NONE -c ":helptags ~/.vim/bundle/nerdtree/doc" -c q
echo "map <C-n> :NERDTreeToggle<CR>" >> ~/.vimrc
echo "nmap <C-N><C-N> :set invnumber<CR>" >> ~/.vimrc
echo "\" Set spaces instead of tabs
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround
set expandtab

\" for yaml files, 2 spaces
autocmd Filetype yml setlocal ts=2 sw=2 expandtab
autocmd Filetype yaml setlocal ts=2 sw=2 expandtab

\" history
set history=700
set undolevels=700

\" <Ctrl-l> redraws the screen and removes any search highlighting.
nnoremap <silent> <C-l> :nohl<CR><C-l>

\" Turn on mouse scroll
set mouse=a

\" indexes
highlight LineNr ctermfg=grey
highlight clear SignColumn
highlight clear LineNr
set cursorline

\" disable beep
set visualbell" >> ~/.vimrc
# add fancy tab indentation marks (indentLine)
git clone https://github.com/Yggdroot/indentLine.git ~/.vim/bundle/indentLine
