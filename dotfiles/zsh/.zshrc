export ZSH=${HOME}/.oh-my-zsh

ZSH_THEME="af-magic"
ZSH_TMUX_AUTOSTART="true"

plugins=(git docker autojump archlinux tmux common-aliases django)

export PYENV_ROOT="${HOME}/.pyenv"
export EDITOR=vim
export PATH="${PYENV_ROOT}/bin:$PATH"

# load pyenv and pyenv-virtualenvwrapper
eval "$(pyenv init -)"
pyenv virtualenvwrapper_lazy

# thefuck
eval $(thefuck --alias fk)

# Create gitgnore file
#
# usage: gitgnore language
gi() { 
  curl -L -s https://www.gitignore.io/api/$@ > .gitignore
}

# Interface to OS clipboard
#
# usage: clip           # show clipboard content
#        clip <file>    # copy file content to clipboard
#        cmd | clip     # copy output of cmd to clipboard
#
clip() {
  if [[ -t 0  && -z "$1" ]]; then
    # output contents of clipboard
    xclip -out -selection clipboard
  elif [[ -n "$1" ]]; then
    # copy file contents to clipboard
    xclip -in -selection clipboard < "$1"
  else
    # read from stdin
    xclip -in -selection clipboard
  fi
}

# Create a new directory and cd into it
#
mkcd() {
  if [ ! -n "$1" ]; then
    echo "Enter a directory name"
  elif [ -d $1 ]; then
    echo "\`$1' already exists"
  else
    mkdir $1 && cd $1
  fi
}

# Extract various archive formats
#
# usage: extract <file>
#
extract() {
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.tar.xz)    tar xJf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1   ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# load oh-my-zsh
source $ZSH/oh-my-zsh.sh
