export ZSH=${HOME}/.oh-my-zsh

ZSH_THEME="af-magic"
ZSH_TMUX_AUTOSTART="true"

plugins=(git docker autojump archlinux tmux common-aliases django extract httpie)

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

# load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# custom alias
alias ll='ls -l --color -h --group-directories-first'
alias l='ls --color -h --group-directories-first'
alias ls='l'
