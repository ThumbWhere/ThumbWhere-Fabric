apt-get -y install ubuntu-restricted-extras
su - teamcity
wget http://download.jetbrains.com/teamcity/TeamCity-8.0.4.tar.gz
git clone git://github.com/ariya/phantomjs.git
cd phantomjs
git checkout 1.9
apt-get install ubuntu-restricted-extras
./build.sh  --confirm
