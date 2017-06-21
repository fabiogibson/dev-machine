#!/bin/sh

##################################################
# Helpers
##################################################
cmd_exists() {
	command -v "$@" > /dev/null 2>&1
}

git_clone() {
	env git clone --depth=1 $1 $2 || {
  		printf "Error: git clone of $1 failed\n"
  		exit 1
  	}
}

##################################################
# Package Managers
##################################################
pacman_install() {
	for pack in "$@"; do	
		printf Installing $pack\n
		sudo pacman -S --noconfirm $pack  || {
			printf "Error: Package installation failed for $pack\n"
			exit 1
		}
	done
}

yaourt_install() {
	for pack in "$@"; do	
		printf Installing $pack\n
		sudo yaourt -S --noconfirm $pack  || {
			printf "Error: Package installation failed for $pack\n"
			exit 1
		}
	done
}

npm_install() {
	for pack in "$@"; do
		sudo npm install -g $pack > /dev/null
	done
}

pip_install() {
	pyenv activate $1
	shift
	for pack in "$@"; do
		if ! cmd_exists $pack; then
	  		pip install $pack > /dev/null
		fi
	done
	pyenv deactivate
}

##################################################
# Installation Scripts
##################################################
install_pyenv() {
	export PYENV_VIRTUALENV_DISABLE_PROMPT=1
	export PYENV_ROOT="${HOME}/.pyenv"

	if [ ! -d "$PYENV_ROOT" ]; then
		echo Installing PyEnv...
		export PATH="${PYENV_ROOT}/bin:$PATH"
		(curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash) > /dev/null
		git_clone https://github.com/yyuu/pyenv-virtualenvwrapper.git ${PYENV_ROOT}/plugins/pyenv-virtualenvwrapper
	else
		echo Skipping PyEnv
	fi

	eval "$(pyenv init -)"
}
	
install_ohmyzsh() {
	umask g-w,o-w
	git_clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
}

get_dotfiles() {
	mkdir -p $1
	for file in $2; do
		curl -s -o $1/$2 https://raw.githubusercontent.com/fabiogibson/dev-machine/master/dotfiles/$2 2>&1	
	done
}

install_dotfiles() {
	get_dotfiles $HOME .zshrc .zshenv .tmux.conf
	get_dotfiles $HOME/.config/xfce4/terminal terminalrc
	
	if cmd_exists xfce4-about; then
		mkdir -p  $HOME/.config/xfce4/terminal
		curl -s -o $HOME/.config/xfce4/terminal/terminalrc https://raw.githubusercontent.com/fabiogibson/dev-machine/master/dotfiles/terminalrc 2>&1
		
		
		get_dotfile xfce4-panel.xml $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
		get_dotfile xfce4-keyboard-shortcuts.xml $HOME/.config/xfce4/xfconf/xfce-perchannel-xml
		
		curl -s -o $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml https://raw.githubusercontent.com/fabiogibson/dev-machine/master/dotfiles/xfce4-panel.xml 2>&1
		curl -s -o $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml https://raw.githubusercontent.com/fabiogibson/dev-machine/master/dotfiles/xfce4-keyboard-shortcuts.xml 2>&1
	fi
}

install_wrk() {
	if ! cmd_exists wrk; then
		git_clone https://github.com/wg/wrk.git ./tmp/wrk
		cd ./tmp/wrk
		make
		sudo cp wrk /usr/local/bin
	fi
}

install_aureola() {
	git_clone https://github.com/erikdubois/Aureola ./tmp/Aureola/ 
	./tmp/Aureola/install-conky.sh -y
	curl -s -o $HOME/.config/conky/conky.conf https://raw.githubusercontent.com/fabiogibson/dev-machine/master/dotfiles/conky.conf 2>&1	
}

##################################################
# Fonts
##################################################
install_powerline_fonts() {
	if [ ! -f "$HOME/.local/share/fonts/Meslo LG L DZ Regular for Powerline.ttf" ]; then
		git_clone https://github.com/powerline/fonts.git ./tmp/powerline_fonts/
		./tmp/powerline_fonts/install.sh "Meslo LG L DZ Regular for Powerline"
	fi
}

install_firacode() {
	if [ ! -f "$HOME/.local/share/fonts/FiraCode-Regular.ttf" ]; then
		git_clone https://github.com/tonsky/FiraCode.git ./tmp/firacode/
		cp ./tmp/firacode/distr/ttf/* $HOME/.local/share/fonts/
	fi
}

##################################################
# Configuration Scripts
##################################################
create_virtual_env() {
	pyenv install -s $1

	if [ ! -d "$PYENV_ROOT/versions/$2" ]; then
		echo Creating virtualenv $2 with Python $1
		pyenv virtualenv $1 $2
	else
		echo Skipping virtualenv $2
	fi
}

configure_git() {
	echo Setting up git globals...
	# use this hack to be able to invoke git diff instead of git difftool
	echo '#!/bin/sh\nmeld $2 $5' | sudo tee /usr/local/bin/meld_git > /dev/null
	/bin/cat <<EOM >/usr/local/bin/meld_git
	#!/bin/sh
	meld $2 $5
	EOM

	sudo chmod +x /usr/local/bin/meld_git

	git config --global user.name "Fabio Gibson"
	git config --global user.email "fabiogibson@hotmail.com"
	git config --global merge.tool meld_git
	git config --global diff.external meld_git	
}

##################################################
# Machine setup goes here
##################################################
mkdir -p ~/tmp/
pacman_install 	git

# Setup python enviroments
install_pyenv
create_virtual_env 3.6.1 py3
create_virtual_env 2.7.13 py2

# install global python tools
pip_install py3 powerline-status isort pep8 httpie
pip_install py2 thefuck tox

# set global python environments
pyenv global 3.6.1 2.7.13 py3 py2

pacman_install 				\
	zsh				\
	yaourt				\
	yaourt-gui-manjaro		\
	spacefm				\
	tmux 				\
	docker				\
	the_silver_searcher 		\
	autojump 			\
	conky				\
	synapse 			\
	nodejs				\
	npm				\
	vim 				\
	meld				\
	noto-fonts

yaourt_install 			\
	google-chrome 		\
	skypeforlinux-bin 	\
	moka-icon-theme-git

# install fonts
install_powerline_fonts
install_firacode

# install tools
install_wrk
install_aureola
install_ohmyzsh
npm_install mockserver browser-sync coffee-script typescript

# configure machine
install_dotfiles
configure_git

# create workspace directories
mkdir -p $HOME/.virtualenvs $HOME/Projects

# switch shell to zsh
chsh -s $(grep /zsh$ /etc/shells | tail -1)
env zsh

echo It\'s all done!
