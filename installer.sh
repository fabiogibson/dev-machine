#!/bin/sh
pacman_install() {
	for pack in "$@"; do	
		printf Installing $pack\n
		sudo pacman -S --noconfirm $pack  || {
			printf "Error: Package installation failed for $pack\n"
		}
	done
}

cmd_exists() {
	command -v "$@" > /dev/null 2>&1
}

install_pyenv() {
	export PYENV_VIRTUALENV_DISABLE_PROMPT=1
	export PYENV_ROOT="${HOME}/.pyenv"

	if [ ! -d "$PYENV_ROOT" ]; then
		echo Installing PyEnv...
		export PATH="${PYENV_ROOT}/bin:$PATH"
		(curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash) > /dev/null
		(git clone https://github.com/yyuu/pyenv-virtualenvwrapper.git ${PYENV_ROOT}/plugins/pyenv-virtualenvwrapper) > /dev/null
	else
		echo Skipping PyEnv
	fi

	eval "$(pyenv init -)"
}
	
install_ohmyzsh() {
	ZSH=~/.oh-my-zsh
	umask g-w,o-w

	env git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $ZSH || {
  		printf "Error: git clone of oh-my-zsh repo failed\n"
  		exit 1
  	}
}

install_powerline_fonts() {
	if [ ! -f "$HOME/.local/share/fonts/Meslo LG L DZ Regular for Powerline.ttf" ]; then
		echo Installing Powerline fonts...
		
		git clone --depth=1 https://github.com/powerline/fonts.git ./fonts/ || {
			printf "Error: git clone of powerline fonts failed\n"
			exit 1
		}
			
		./fonts/install.sh "Meslo LG L DZ Regular for Powerline" 2>&1
		rm -rf ./fonts
	else
		echo Skipping Powerline fonts...
	fi
}

install_dotfiles() {
	for file in zshrc zshenv conkyrc tmux.conf; do
		echo Creating $HOME/.$file
		curl -s -o $HOME/.$file https://raw.githubusercontent.com/fabiogibson/dev-machine/master/dotfiles/$file 2>&1	
	done
	
	if command -v xfce4-about  1>/dev/null; then
		mkdir -p  $HOME/.config/xfce4/terminal
		curl -s -o $HOME/.config/xfce4/terminal/terminalrc https://raw.githubusercontent.com/fabiogibson/dev-machine/master/dotfiles/terminalrc 2>&1
	fi
	
	for file in config.cson keymap.cson packages.txt; do
		curl -s -o $HOME/.atom/$file https://raw.githubusercontent.com/fabiogibson/dev-machine/master/atom/$file 2>&1
	done
	
	apm install --packages-file $HOME/.atom/packages.txt
}

install_ranger() {
	if ! cmd_exists ranger; then
		sudo git clone git://git.savannah.nongnu.org/ranger.git /opt/ranger
		sudo ln -s /opt/ranger/ranger.py /usr/local/bin/ranger
	fi
}



install_wrk() {
	if ! cmd_exists wrk; then
		git clone https://github.com/wg/wrk.git > /dev/null
		cd wrk && make > /dev/null
		sudo cp wrk /usr/local/bin
		cd - && rm -rf ./wrk
	fi
}

npm_install() {
	for pack in "$@"; do
		sudo npm install -g $pack > /dev/null
	done
}

create_virtual_env() {
	pyenv install -s $1

	if [ ! -d "$PYENV_ROOT/versions/$2" ]; then
		echo Creating virtualenv $2 with Python $1
		pyenv virtualenv $1 $2
	else
		echo Skipping virtualenv $2
	fi
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

configure_git() {
	echo Setting up git globals...
	# use this hack to be able to invoke git diff instead of git difftool
	echo '#!/bin/sh\nmeld $2 $5' | sudo tee /usr/local/bin/meld_git > /dev/null
	sudo chmod +x /usr/local/bin/meld_git

	git config --global user.name "Fabio Gibson"
	git config --global user.email "fabiogibson@hotmail.com"
	git config --global merge.tool meld_git
	git config --global diff.external meld_git	
}

pacman_install 				\
	git				\
	zsh				\
	yaourt				\
	tmux 				\
	docker				\
	the_silver_searcher 		\
	autojump 			\
	conky				\
	synapse 			\
	nodejs				\
	npm				\
	vim 				\
	atom				\
	apm				\
	meld				\
	noto-fonts

yaourt -S google-chrome --noconfirm
yaourt -S skypeforlinux-bin --noconfirm
yaourt -S moka-icon-theme-git --noconfirm

install_pyenv
create_virtual_env 3.6.1 py3
create_virtual_env 2.7.13 py2

# install global python tools
pip_install py3 youtube-dl powerline-status isort pep8 httpie
pip_install py2 rename fabric thefuck tox

# set global python environments
pyenv global 3.6.1 2.7.13 py3 py2

install_powerline_fonts

install_wrk
install_ranger

npm_install tern mockserver browser-sync coffee-script typescript

configure_git

# create workspace directories
mkdir -p $HOME/.virtualenvs $HOME/Projects

install_ohmyzsh
install_dotfiles

# switch shell to zsh
chsh -s $(grep /zsh$ /etc/shells | tail -1)
env zsh

echo It\'s all done!
exit 1
