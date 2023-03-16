FROM ubuntu:18.04

# create user ubuntu
RUN apt update
RUN apt -y install sudo
RUN useradd -s /bin/bash -G sudo -m ubuntu
RUN echo "ubuntu:ubuntu" | chpasswd
RUN echo "root:root" | chpasswd
RUN echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo 
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# install etc
RUN apt -y install vim
RUN apt -y install git
RUN apt -y install curl
RUN apt -y install software-properties-common
RUN apt -y install mysql-server
RUN apt -y install libmysqlclient-dev
RUN add-apt-repository -y ppa:ondrej/php

# install PHP8
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt -y install php8.1 php8.1-bcmath php8.1-curl php8.1-mbstring php8.1-mysql php8.1-xml php8.1-pgsql

# install composer
RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer

# install MySQL
RUN cat /etc/mysql/mysql.conf.d/mysqld.cnf | sed -e '/utf8/d' | sed -e '/sql_mode/d' | sed -e '$acharacter-set-server=utf8\nsql_mode=STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' | sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf
RUN sudo usermod -d /var/lib/mysql mysql

# install nvm, node
USER ubuntu
RUN sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
RUN sudo echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
RUN sudo echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
RUN sudo echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >>  ~/.bashrc
RUN sudo curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
RUN sudo apt-get install -y nodejs

# install yarn
RUN sudo curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
RUN sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
RUN sudo apt update && sudo apt install -y yarn

# install rvm
RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "rvm requirements"
RUN /bin/bash -l -c "rvm install 3.0.0"
RUN /bin/bash -l -c "rvm --default use 3.0.0"
RUN /bin/bash -l -c "gem install rails -v 6.1.3.1"
RUN sudo echo "PATH=$PATH:$HOME/.rvm/bin" >> ~/.bashrc 
RUN sudo echo '[[ -s "/home/ubuntu/.rvm/scripts/rvm" ]] && . "/home/ubuntu/.rvm/scripts/rvm"' >> ~/.bashrc 

USER root
# 日本時間（JST）の設定
RUN DEBIAN_FRONTEND=noninteractive apt -y install tzdata
RUN echo 'Asia/Tokyo' > /etc/timezone
ENV TZ Asia/Tokyo

COPY prompt.sh /home/ubuntu/prompt.sh
RUN sudo chmod 755 /home/ubuntu/prompt.sh
RUN echo 'source ~/prompt.sh' >> /home/ubuntu/.bashrc
RUN echo 'source ~/prompt.sh' >> /home/ubuntu/.bash_profile
RUN echo 'sudo service mysql start' >> /home/ubuntu/.bash_profile

# コンテナ起動時に実行する
ADD  start.sh  /

USER ubuntu
WORKDIR /home/ubuntu/environment
COPY docs/ docs/
RUN sudo chmod +x docs/app.sh

CMD  ["/start.sh"]