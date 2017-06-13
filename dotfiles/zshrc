export ZSH=${HOME}/.oh-my-zsh

ZSH_THEME="robbyrussell"
ZSH_TMUX_AUTOSTART="true"

plugins=(git docker autojump archlinux tmux common-aliases django)

export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:$PATH"

# install gitignore
function gi() { curl -L -s https://www.gitignore.io/api/$@ > .gitignore ;}

# load pyenv and pyenv-virtualenvwrapper
eval "$(pyenv init -)"
pyenv virtualenvwrapper_lazy

# thefuck
eval $(thefuck --alias fuck)

# load oh-my-zsh
source $ZSH/oh-my-zsh.sh
