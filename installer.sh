#!/bin/sh

##################################################
# Helpers
##################################################
cmd_exists() {
	command -v $1 > /dev/null 2>&1
}

git_clone() {
	if [ ! -d "$2" ]; then
    		umask g-w,o-w
		env git clone --depth=1 $1 $2 || {
			printf "Error: git clone of $1 failed\n"
			exit 1
		}
	fi
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


sysctl_enable() {
	for unit in "$@"; do
		sudo systemctl start $unit
		sudo systemctl enable $unit
	done
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
	export PATH="${PYENV_ROOT}/bin:$PATH"
	remote_bash https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer
	eval "$(pyenv init -)"
}
	
install_ohmyzsh() {
	git_clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
	# install spaceship theme
	curl -o ~/.oh-my-zsh/custom/themes/spaceship.zsh-theme https://raw.githubusercontent.com/denysdovhan/spaceship-zsh-theme/master/spaceship.zsh
	# install my envrc plugin
	curl --create-dirs -o ~/.oh-my-zsh/custom/plugins/envrc/envrc.plugin.zsh https://raw.githubusercontent.com/fabiogibson/envrc-zsh-plugin/master/envrc.plugin.zsh
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
	cd $HOME
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
	copy_dotfiles $HOME/.config albert
	copy_dotfiles $HOME/.config/xfce4/terminal terminal
	copy_dotfiles $HOME/.config/xfce4/xfconf/xfce-perchannel-xml xfce4
	copy_dotfiles $HOME/.config/autostart autostart
	copy_dotfiles $HOME/.config/conky conky
}

configure_git() {
	echo Setting up git globals...
	# use this hack to be able to invoke git diff instead of git difftool
	printf '#!/bin/sh\nmeld $2 $5' > $tmpdir/meld_git & sudo cp $tmpdir/meld_git /usr/local/bin
	sudo chmod +x /usr/local/bin/meld_git
	git config --global user.name "Fabio Gibson"
	git config --global user.email "fabiogibson@hotmail.com"
	git config --global merge.tool meld_git
	git config --global diff.external meld_git	
}

##################################################
# Machine setup goes here
##################################################

# clone this repository in $HOME/tmp
tmpdir=$HOME/tmp
mkdir -p $tmpdir
git_clone https://github.com/fabiogibson/dev-machine.git $tmpdir/dev-machine

# sync pacman and upgrade system packages
sudo pacman -Syyu --noconfirm

# ensure yaourt is available.
pacman_install yaourt

# install dockbarx with xfce-plugin before setting up python enviroments.
yaourt_install dockbarx xfce4-dockbarx-plugin

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
	base-devel			\
	openssl				\
	openssh				\
	libffi				\
	wget				\
	zsh				\
	tmux 				\
	docker				\
	docker-compose			\
	vnstat				\
	the_silver_searcher 		\
	autojump 			\
	xclip				\
	conky				\
	nodejs				\
	npm				\
	vim 				\
	meld				\
	chromium			\
	pgadmin3			\
	arc-gtk-theme			\
	arc-icon-theme			\
	xfce4-weather-plugin		\
	xfce4-clipman-plugin		\
	noto-fonts			\
	numlockx			\
	
yaourt_install 				\
	sublime-text-dev		\
	skypeforlinux-bin 		\
	slack-desktop			\
	enpass-bin			\
	albert

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

# enable systemctl units
sysctl_enable docker vnstat.service

# add current user to docker group
sudo usermod -aG docker `whoami`

# create workspace directories
mkdir -p $HOME/Projects

# switch shell to zsh
chsh -s $(grep /zsh$ /etc/shells | tail -1)
env zsh
