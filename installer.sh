#!/bin/sh

##################################################
# Helpers
##################################################
cmd_exists() {
	command -v $1 > /dev/null 2>&1
}

git_clone() {
	umask g-w,o-w
	env git clone --depth=1 $1 $2 || {
  		printf "Error: git clone of $1 failed\n"
  		exit 1
  	}
}

copy_dotfiles() {
        mkdir -p $1
      	cp -a $tmpdir/dev-machine/dotfiles/$2/. $1
}

safe_install() {	
	for pack in ${@:2}; do
		printf "Installing package $pack\n"
		
		eval "$1 $pack" || {
			printf "Error: Package $pack installation failed.\n"
			exit 1
		}
	done
}

remote_bash() {
	(curl -L $1 | bash) 2>&1
}

##################################################
# Package Managers
##################################################
pacman_install() {
	safe_install "sudo pacman -S --noconfirm" $@
}

yaourt_install() {
	safe_install "yaourt -S --noconfirm" $@
}

npm_install() {
	safe_install "sudo npm install -g" $@
}

pip_install() {
	pyenv activate $1
	safe_install "pip install" ${@:2}
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
		printf "Installing PyEnv..."
		remote_bash https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer
		git_clone https://github.com/yyuu/pyenv-virtualenvwrapper.git ${PYENV_ROOT}/plugins/pyenv-virtualenvwrapper
	fi

	eval "$(pyenv init -)"
}
	
install_ohmyzsh() {
	git_clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
}

install_wrk() {
	if ! cmd_exists wrk; then
		git_clone https://github.com/wg/wrk.git $tmpdir/wrk
		make -C $tmpdir/wrk
		sudo cp $tmpdir/wrk/wrk /usr/local/bin
	fi
}

install_aureola() {
	git_clone https://github.com/erikdubois/Aureola $tmpdir/aureola
	$tmpdir/aureola/spark/install-conky.sh
}

##################################################
# Fonts
##################################################
install_powerline_fonts() {
	if [ ! -f "$HOME/.local/share/fonts/Meslo LG L DZ Regular for Powerline.ttf" ]; then
		git_clone https://github.com/powerline/fonts.git $tmpdir/powerline_fonts
		$tmpdir/powerline_fonts/install.sh "Meslo LG L DZ Regular for Powerline"
	fi
}

install_firacode() {
	if [ ! -f "$HOME/.local/share/fonts/FiraCode-Regular.ttf" ]; then
		git_clone https://github.com/tonsky/FiraCode.git $tmpdir/firacode
		cp $tmpdir/firacode/distr/ttf/* $HOME/.local/share/fonts/
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

install_dotfiles() {
	copy_dotfiles $HOME zsh
	copy_dotfiles $HOME tmux
	copy_dotfiles $HOME/.config/xfce4/terminal terminal
	copy_dotfiles $HOME/.config/xfce4/xfconf/xfce-perchannel-xml xfce4
	copy_dotfiles $HOME/.config/autostart autostart
	copy_dotfiles $HOME/.config/conky conky
	copy_dotfiles $HOME/.config/tint2 tint2
}

configure_git() {
	echo Setting up git globals...
	# use this hack to be able to invoke git diff instead of git difftool
	printf "#!/bin/sh\nmeld $2 $5" >> /usr/local/bin/meld_git
	sudo chmod +x /usr/local/bin/meld_git
	git config --global user.name "Fabio Gibson"
	git config --global user.email "fabiogibson@hotmail.com"
	git config --global merge.tool meld_git
	git config --global diff.external meld_git	
}

##################################################
# Machine setup goes here
##################################################
tmpdir=$HOME/tmp
mkdir -p $tmpdir
git_clone https://github.com/fabiogibson/dev-machine.git $tmpdir/dev-machine

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
	wget				\
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
	tint2				\
	noto-fonts

yaourt_install 				\
	google-chrome 			\
	numix-square-icon-theme-git
	#skypeforlinux-bin 	\
	#moka-icon-theme-git

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
