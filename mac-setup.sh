#!/usr/bin/env sh

echo "Running Khan Installation Script 1.1"
echo "Warning: This is only tested on Mac OS 10.8 (Mountain Lion)"
echo "  After each statement, either something will open for you to"
echo "    interact with, or a script will run for you to use"
echo "  Press enter when a download/install is completed to go to"
echo "    the next step (including this one)"

read

read -p "Do you want to install everything? y/N " install_everything

if [ "$install_everything" == "y" ]; then
	install_clt="y"
	install_hipchat="y"
	install_homebrew="y"
	install_virtualenv="y"
	setup_mercurial="y"
	setup_github="y"
	install_repos="y"
	install_nginx="y"
	install_gae="y"
else
	read -p "Do you want to install the command line tools? y/N " install_clt
	read -p "Do you want to install hipchat? y/N " install_hipchat
	read -p "Do you want to install homebrew? y/N " install_homebrew
	read -p "Do you want to install virtualenv? y/N " install_virtualenv
	read -p "Do you want to set up mercurial? y/N " setup_mercurial
	read -p "Do you want to set up ssh keys with github? y/N " setup_github
	read -p "Do you want to install the KA repositories? y/N " install_repos
	read -p "Do you want to install nginx? y/N " install_nginx
	read -p "Do you want to install Google App Engine? y/N " install_gae
fi

echo "I'm going to:"
if [ "$install_clt" == "y" ]; then echo "  install command line tools"; fi
if [ "$install_hipchat" == "y" ]; then echo "  install hipchat"; fi
if [ "$install_homebrew" == "y" ]; then echo "  install homebrew"; fi
if [ "$install_virtualenv" == "y" ]; then echo "  install virtualenv"; fi
if [ "$setup_mercurial" == "y" ]; then echo "  setup mercurial"; fi
if [ "$setup_github" == "y" ]; then echo "  setup github and ssh keys"; fi
if [ "$install_repos" == "y" ]; then echo "  install KA repositories"; fi
if [ "$install_nginx" == "y" ]; then echo "  install nginx"; fi
if [ "$install_gae" == "y" ]; then echo "  install Google App Engine"; fi

read -p "Look good? y/N " looks_good

if [ "$looks_good" != "y" ]; then
	exit 1
fi

echo

# get user's name/email
read -p "Enter your full name: " name
read -p "Enter your github email: " gh_email
read -p "Enter your kiln email: " hg_email

if [ -z "$name" -o -z "$gh_email" -o -z "$hg_email" ]; then
	echo "You must enter names and emails"
	exit 1
fi

if [ "$install_clt" == "y" ]; then
	CLT_LOCATION="https://developer.apple.com/downloads/download.action?path=Developer_Tools/command_line_tools_os_x_mountain_lion_for_xcode__august_2012/command_line_tools_for_xcode_os_x_mountain_lion_aug_2012.dmg"

	echo "Downloading Command Line Tools (log in to start the download)"
	echo "Press enter when the download is done."
	# download the command line tools
	open $CLT_LOCATION

	read

	echo "Running Command Line Tools Installer"

	# attach the disk image
	hdiutil attach ~/Downloads/command_line_tools_for_xcode_os_x_mountain_lion_aug_2012.dmg > /dev/null
	echo "Type your password to install:"
	# install the command line tools
	sudo installer -package /Volumes/Command\ Line\ Tools\ \(Mountain\ Lion\)/Command\ Line\ Tools\ \(Mountain\ Lion\).mpkg -target /
	# detach the disk image
	hdiutil detach /Volumes/Command\ Line\ Tools\ \(Mountain\ Lion\)/ > /dev/null
fi

if [ "$install_hipchat" == "y" ]; then
	echo "Opening Hipchat website (log in and click download to install)"
	# open the hipchat page
	open "http://www.hipchat.com/"

	read
fi

if [ "$install_homebrew" == "y" ]; then
	echo "Installing Homebrew"
	# if homebrew is already installed, don't do it again
	if [ ! -d /usr/local/.git ]; then
		/usr/bin/ruby -e "$(/usr/bin/curl -fsSL https://raw.github.com/mxcl/homebrew/master/Library/Contributions/install_homebrew.rb)"
	fi
	# update brew
	brew update > /dev/null

	# make the cellar
	mkdir -p /usr/local/Cellar
	# export some useful directories
	export PATH=/usr/local/bin:/usr/local/sbin:$PATH
	# put these in .bash_profile too
	echo "export PATH=/usr/local/sbin:/usr/local/bin:\$PATH" >> ~/.bash_profile

	# brew doctor
	brew doctor
fi

if [ "$install_virtualenv" == "y" ]; then
	echo "Installing virtualenv"
	# install pip
	sudo easy_install --quiet pip
	# install virtualenv
	sudo pip install virtualenv -q

	echo "Setting up virtualenv"

	# make a virtualenv
	virtualenv -q --python=/usr/bin/python2.7 ~/.virtualenv/khan27
	echo "source ~/.virtualenv/khan27/bin/activate" >> ~/.bash_profile
	source ~/.virtualenv/khan27/bin/activate

	echo "Installing mercurial in virtualenv"
	# install mercurial in virtualenv
	pip -q install Mercurial
fi

if [ "$setup_mercurial" == "y" ]; then
	echo "Making khan directory"
	# start building our directory
	mkdir -p ~/khan/

	echo "Setting up your .hgrc.local"
	# make the dummy certificate
	yes "" | openssl req -new -x509 -extensions v3_ca -keyout /dev/null -out dummycert.pem -days 3650 -passout pass:pass 2> /dev/null
	sudo cp dummycert.pem /etc/hg-dummy-cert.pem
	rm dummycert.pem
	# setup the .hgrc
	echo "[ui]
username = $name <$hg_email>

[web]
cacerts = /etc/hg-dummy-cert.pem" > ~/.hgrc.local

	echo "%include ~/.hgrc.local" >> ~/.hgrc
fi

if [ "$setup_github" == "y" ]; then
	# setup git name/email
	git config --global user.name "$name"
	git config --global user.email "$gh_email"

	echo "Setting up ssh keys"

	# if there is no ssh key, make one
	if [ ! -e ~/.ssh/id_*sa ]; then
		ssh-keygen -t rsa -C "$gh_email" -f ~/.ssh/id_rsa
	fi

	# copy the public key
	cat ~/.ssh/id_rsa.pub | pbcopy

	echo "Opening github ssh keys"
	echo "Click 'Add SSH Key', paste into the box, and hit 'Add key'"
	# go to the github ssh keys site
	open "https://github.com/settings/ssh"

	read
fi

if [ "$install_repos" == "y" ]; then
	echo "Cloning stable"
	# get the stable branch
	hg clone -q https://$hg_email@khanacademy.kilnhg.com/Code/Website/Group/stable ~/khan/stable 2>/dev/null || (cd stable; hg pull -q -u)

	echo "Installing requirements"
	# install requirements into the virtualenv
	pip -q install -r ~/khan/stable/requirements.txt

	echo "Getting development tools"
	# download a bunch of developer tools
	mkdir -p ~/khan/devtools
	git clone -q https://github.com/Khan/kiln-review ~/khan/devtools/kiln-review 2>/dev/null || (cd ~/khan/devtools/kiln-review; git pull -q)
	hg clone -q https://bitbucket.org/brendan/mercurial-extensions-rdiff ~/khan/devtools/mercurial-extensions-rdiff 2>/dev/null || (cd ~/khan/devtools/mercurial-extensions-rdiff; hg -q pull -u)
	git clone -q https://github.com/Khan/khan-linter ~/khan/devtools/khan-linter 2>/dev/null || (cd ~/khan/devtools/khan-linter; git pull -q)
	git clone -q https://github.com/Khan/arcanist ~/khan/devtools/arcanist 2>/dev/null || (cd ~/khan/devtools/arcanist; git pull -q)
	git clone -q https://github.com/Khan/libphutil.git ~/khan/devtools/libphutil 2>/dev/null || (cd ~/khan/devtools/libphutil; git pull -q)
	git clone -q https://github.com/Khan/khan-dotfiles.git ~/khan/devtools/khan-dotfiles 2>/dev/null || (cd ~/khan/devtools/khan-dotfiles; git pull -q)
	curl -s https://khanacademy.kilnhg.com/Tools/Downloads/Extensions > /tmp/extensions.zip && (cd ~/khan/devtools; unzip -qo /tmp/extensions.zip kiln_extensions/kilnauth.py)
fi

if [ "$install_nginx" == "y" ]; then
	echo "Installing nginx"
	# install nginx
	brew install nginx > /dev/null

	echo "Backing up nginx.conf to nginx.conf.old"
	# make a backup of nginx config
	sudo cp /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.old

	echo "Setting up nginx"
	# setup the nginx configuration file
	cat ~/khan/devtools/khan-dotfiles/nginx.conf | sed "s/%USER/$USER/" > /usr/local/etc/nginx/nginx.conf

	# if not done before, add the new hosts to /etc/hosts
	if ! grep -q "ka.local" /etc/hosts; then
		echo "# KA local servers
127.0.0.1       exercises.ka.local
::1             exercises.ka.local
127.0.0.1       stable.ka.local
::1             stable.ka.local" | sudo tee -a /etc/hosts >/dev/null
	fi

	# copy the launch plist
	sudo cp /usr/local/Cellar/nginx/*/homebrew.mxcl.nginx.plist /Library/LaunchDaemons
	# delete the username key so it is run as root
	sudo /usr/libexec/PlistBuddy -c "Delete :UserName" /Library/LaunchDaemons/homebrew.mxcl.nginx.plist 2>/dev/null
	# load it
	sudo launchctl load -w /Library/LaunchDaemons/homebrew.mxcl.nginx.plist
fi

if [ "$install_gae" == "y" ]; then
	APP_ENGINE_VERSION="1.7.0"

	echo "Installing Google App Engine Launcher"
	curl -s http://googleappengine.googlecode.com/files/GoogleAppEngineLauncher-$APP_ENGINE_VERSION.dmg > ~/Downloads/GoogleAppEngineLauncher-$APP_ENGINE_VERSION.dmg
	hdiutil attach ~/Downloads/GoogleAppEngineLauncher-$APP_ENGINE_VERSION.dmg > /dev/null
	cp -r /Volumes/GoogleAppEngineLauncher-*/GoogleAppEngineLauncher.app /Applications/
	hdiutil detach /Volumes/GoogleAppEngineLauncher-* > /dev/null

	echo "Setting up Google App Engine Launcher"

	curl -s "https://dl.dropbox.com/s/ruwcqsq2fqhv6sv/current.sqlite?dl=1" -o ~/khan/stable/datastore/current.sqlite
	mkdir -p ~/Library/Application\ Support/GoogleAppEngineLauncher
	cat ~/khan/devtools/khan-dotfiles/GAEProjects.plist | sed "s/%USER/$USER/" > ~/Library/Application\ Support/GoogleAppEngineLauncher/Projects.plist

	(cd /Applications/GoogleAppEngineLauncher.app/Contents/Resources/GoogleAppEngine-default.bundle/Contents/Resources/; unzip -qq google_appengine.zip; touch google_appengine)
	sudo mkdir -p /usr/local/bin
	for script in api_server.py appcfg.py bulkload_client.py bulkloader.py dev_appserver.py download_appstats.py gen_protorpc.py google_sql.py remote_api_shell.py; do
		sudo ln -s /Applications/GoogleAppEngineLauncher.app/Contents/Resources/GoogleAppEngine-default.bundle/Contents/Resources/google_appengine/$script /usr/local/bin/$script
	done

fi

echo "You might be done!"
