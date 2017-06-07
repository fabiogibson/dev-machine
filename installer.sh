#!/bin/sh
apt_install() {
	sudo apt-get update -y > /dev/null

	for pack in "$@"; do	
		echo Installing $pack
		sudo apt-get install -y $pack > /dev/null
	done
}

cmd_exists() {
	if command -v $1  1>/dev/null; then
		echo Skipping $1...
		return 0
	else
		echo Installing $1...
		return 1
	fi
}

install_pyenv() {
	export PYENV_VIRTUALENV_DISABLE_PROMPT=1

	if [ -z "$PYENV_ROOT" ]; then
	  export PYENV_ROOT="${HOME}/.pyenv"
	fi 

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
	echo Installing Oh-My-Zsh...
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" > /dev/null
}

install_powerline_fonts() {
	if [ ! -f "$HOME/.local/share/fonts/Meslo LG L DZ Regular for Powerline.ttf" ]; then
		echo Installing Powerline fonts...
		git clone https://github.com/powerline/fonts.git ./fonts/ 2>&1
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
}

install_ranger() {
	if ! cmd_exists ranger; then
		sudo git clone git://git.savannah.nongnu.org/ranger.git /opt/ranger 2>&1
		sudo ln -s /opt/ranger/ranger.py /usr/local/bin/ranger
	fi
}

install_docker() {
	if ! cmd_exists docker; then
		curl -sSL https://get.docker.com/ | sh
		sudo usermod -a -G docker `whoami`
	fi
}

install_nodejs() {
	if ! cmd_exists node; then
		curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
		apt_install nodejs
	fi
}

install_skype() {
	if ! cmd_exists skypeforlinux; then
		curl https://repo.skype.com/data/SKYPE-GPG-KEY | sudo apt-key add - 
		echo "deb [arch=amd64] https://repo.skype.com/deb stable main" | sudo tee /etc/apt/sources.list.d/skypeforlinux.list
		apt_install skypeforlinux
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
		if ! cmd_exists $pack; then
		        sudo npm install -g $pack > /dev/null
		fi
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


apt_install 				\
	git				\
	curl                            \
	build-essential 		\
	python-dev			\
	python3-dev                     \
	libffi-dev                      \
	python-setuptools		\
        python-software-properties	\
	openssl 			\
	libssl-dev			\
	libpq-dev			\
	libreadline-gplv2-dev           \
	libsqlite3-dev                  \
	bzip2                           \
	tk-dev                          \
	libgdbm-dev                     \
	libc6-dev                       \
	libbz2-dev                      \
	zsh 				\
	tmux 				\
	silversearcher-ag 		\
	autojump 			\
	conky-all 			\
	synapse 			\
	vim 				\
	meld				

install_pyenv
create_virtual_env 3.6.1 py3
create_virtual_env 2.7.13 py2

# install global python tools
pip_install py3 youtube-dl powerline-status isort pep8 httpie
pip_install py2 rename fabric thefuck tox

# set global python environments
pyenv global 3.6.1 2.7.13 py3 py2

install_ohmyzsh
install_powerline_fonts
install_docker
install_skype
install_wrk
install_ranger
install_nodejs
npm_install tern mockserver browser-sync

if ! cmd_exists coffee; then
	npm_install coffee-script
fi

if ! cmd_exists tsc; then
	npm_install typescript
fi

install_dotfiles
configure_git

# create workspace directories
mkdir -p $HOME/.virtualenvs $HOME/Projects

# set zsh as default shell
echo Changing default shell to ZSH. Root password will be requested...
chsh -s `which zsh`

echo It\'s all done!
