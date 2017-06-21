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

get_dotfiles() {
	mkdir -p $1
	for file in $2; do
		curl -s -o $1/$2 https://raw.githubusercontent.com/fabiogibson/dev-machine/master/dotfiles/$2 2>&1	
	done
}

safe_install() {
	install_cmd = $1
	shift
	
	for pack in "$@"; do
		printf "Installing package $pack\n"
		
		eval "$install_cmd $pack" || {
			printf "Error: Package $pack installation failed.\n"
			exit 1
		}
	done
}

##################################################
# Package Managers
##################################################
pacman_install() {
	safe_install "sudo pacman -S --noconfirm" $@
}

yaourt_install() {
	safe_install "sudo yaourt -S --noconfirm" $@
}

npm_install() {
	safe_install "sudo npm install -g" $@
}

pip_install() {
	pyenv activate $1
	shift
	safe_install "pip install" $@
	pyenv deactivate
}

##################################################
# Installation Scripts
##################################################
install_pyenv() {
	export PYENV_VIRTUALENV_DISABLE_PROMPT=1
	export PYENV_ROOT="${HOME}/.pyenv"

	if [ ! -d "$PYENV_ROOT" ]; then
		export PATH="${PYENV_ROOT}/bin:$PATH"
		echo Installing PyEnv...
		(curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash) 2>&1
		git_clone https://github.com/yyuu/pyenv-virtualenvwrapper.git ${PYENV_ROOT}/plugins/pyenv-virtualenvwrapper
	fi

	eval "$(pyenv init -)"
}
	
install_ohmyzsh() {
	umask g-w,o-w
	git_clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
}

install_dotfiles() {
	get_dotfiles $HOME .zshrc .zshenv .tmux.conf
	get_dotfiles $HOME/.config/xfce4/terminal terminalrc
	get_dotfiles $HOME/.config/xfce4/xfconf/xfce-perchannel-xml xfce4-panel.xml xfce4-keyboard-shortcuts.xml
}

install_wrk() {
	if ! cmd_exists wrk; then
		git_clone https://github.com/wg/wrk.git ./tmp/wrk
		cd ./tmp/wrk
		make
		sudo cp wrk /usr/local/bin
		cd ~
	fi
}

install_aureola() {
	git_clone https://github.com/erikdubois/Aureola ./tmp/aureola/ 
	./tmp/aureola/install-conky.sh -y
	get_dotfiles $HOME/.config/conky conky.conf
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
	fi
}

configure_git() {
	echo Setting up git globals...
	# use this hack to be able to invoke git diff instead of git difftool
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
