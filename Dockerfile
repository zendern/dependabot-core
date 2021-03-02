FROM ubuntu:18.04

### SYSTEM DEPENDENCIES

ENV DEBIAN_FRONTEND="noninteractive" \
  LC_ALL="en_US.UTF-8" \
  LANG="en_US.UTF-8"

# Everything from `make` onwards in apt-get install is only installed to ensure
# Python support works with all packages (which may require specific libraries
# at install time).

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    build-essential \
    dirmngr \
    git \
    bzr \
    mercurial \
    gnupg2 \
    curl \
    wget \
    file \
    zlib1g-dev \
    liblzma-dev \
    tzdata \
    zip \
    unzip \
    locales \
    openssh-client \
    make \
    libpq-dev \
    libssl-dev \
    libbz2-dev \
    libffi-dev \
    libreadline-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    llvm \
    libncurses5-dev \
    libncursesw5-dev \
    libmysqlclient-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libgeos-dev \
    python3-enchant \
  && locale-gen en_US.UTF-8


### RUBY

# Install Ruby 2.6.6, update RubyGems, and install Bundler
ENV BUNDLE_SILENCE_ROOT_WARNING=1
RUN apt-get install -y software-properties-common \
  && apt-add-repository ppa:brightbox/ruby-ng \
  && apt-get update \
  && apt-get install -y ruby2.6 ruby2.6-dev \
  && gem update --system 3.0.3 \
  && gem install bundler -v 1.17.3 --no-document


### PYTHON

# Install Python 2.7 and 3.9 with pyenv. Using pyenv lets us support multiple Pythons
ENV PYENV_ROOT=/usr/local/.pyenv \
  PATH="/usr/local/.pyenv/bin:$PATH"
RUN git clone https://github.com/pyenv/pyenv.git /usr/local/.pyenv \
  && cd /usr/local/.pyenv && git checkout v1.2.22 && cd - \
  && pyenv install 3.9.1 \
  && pyenv install 2.7.18 \
  && pyenv global 3.9.1


### JAVASCRIPT

# Install Node 14.0 and npm (updated after elm)
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  && apt-get install -y nodejs


### ELM

# Install Elm 0.18 and Elm 0.19
ENV PATH="$PATH:/node_modules/.bin"
RUN npm install elm@0.18.0 \
  && wget "https://github.com/elm/compiler/releases/download/0.19.0/binaries-for-linux.tar.gz" \
  && tar xzf binaries-for-linux.tar.gz \
  && mv elm /usr/local/bin/elm19 \
  && rm -f binaries-for-linux.tar.gz \
  && rm -rf ~/.npm

# NOTE: This is a hack to get around the fact that elm 18 fails to install with
# npm 7, we should look into deprecating elm 18
RUN npm install -g npm@v7.5.4


### PHP

# Install PHP 7.4 and Composer
ENV COMPOSER_ALLOW_SUPERUSER=1
COPY --from=composer:1.10.9 /usr/bin/composer /usr/local/bin/composer1
COPY --from=composer:2.0.8 /usr/bin/composer /usr/local/bin/composer
RUN add-apt-repository ppa:ondrej/php \
  && apt-get update \
  && apt-get install -y \
    php7.4 \
    php7.4-apcu \
    php7.4-bcmath \
    php7.4-cli \
    php7.4-common \
    php7.4-curl \
    php7.4-gd \
    php7.4-geoip \
    php7.4-gettext \
    php7.4-gmp \
    php7.4-imagick \
    php7.4-imap \
    php7.4-intl \
    php7.4-json \
    php7.4-ldap \
    php7.4-mbstring \
    php7.4-memcached \
    php7.4-mongodb \
    php7.4-mysql \
    php7.4-redis \
    php7.4-soap \
    php7.4-sqlite3 \
    php7.4-tidy \
    php7.4-xml \
    php7.4-zip \
    php7.4-zmq


### GO

# Install Go and dep
ARG GOLANG_VERSION=1.15.7
ARG GOLANG_CHECKSUM=0d142143794721bb63ce6c8a6180c4062bcf8ef4715e7d6d6609f3a8282629b3
RUN curl -o go.tar.gz https://dl.google.com/go/go${GOLANG_VERSION}.linux-amd64.tar.gz \
  && echo "$GOLANG_CHECKSUM go.tar.gz" | sha256sum -c - \
  && tar -xzf go.tar.gz -C /opt \
  && mkdir /opt/go/gopath \
  && wget -O /opt/go/bin/dep https://github.com/golang/dep/releases/download/v0.5.4/dep-linux-amd64 \
  && chmod +x /opt/go/bin/dep \
  && rm go.tar.gz
ENV PATH=/opt/go/bin:$PATH GOPATH=/opt/go/gopath


### ELIXIR

# Install Erlang, Elixir and Hex
ENV PATH="$PATH:/usr/local/elixir/bin"
# https://github.com/elixir-lang/elixir/releases
ARG ELIXIR_VERSION=v1.10.4
ARG ELIXIR_CHECKSUM=9727ae96d187d8b64e471ff0bb5694fcd1009cdcfd8b91a6b78b7542bb71fca59869d8440bb66a2523a6fec025f1d23394e7578674b942274c52b44e19ba2d43
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb \
  && dpkg -i erlang-solutions_1.0_all.deb \
  && apt-get update \
  && apt-get install -y esl-erlang \
  && wget https://github.com/elixir-lang/elixir/releases/download/${ELIXIR_VERSION}/Precompiled.zip \
  && echo "$ELIXIR_CHECKSUM  Precompiled.zip" | sha512sum -c - \
  && unzip -d /usr/local/elixir -x Precompiled.zip \
  && rm -f Precompiled.zip erlang-solutions_1.0_all.deb \
  && mix local.hex --force


### RUST

# Install Rust 1.47.0
ENV RUSTUP_HOME=/opt/rust \
  PATH="${PATH}:/opt/rust/bin"
RUN export CARGO_HOME=/opt/rust ; curl https://sh.rustup.rs -sSf | sh -s -- -y
RUN export CARGO_HOME=/opt/rust ; rustup toolchain install 1.47.0 && rustup default 1.47.0


### NEW NATIVE HELPERS

COPY composer/helpers /opt/composer/helpers
COPY dep/helpers /opt/dep/helpers
COPY bundler/helpers /opt/bundler/helpers
COPY go_modules/helpers /opt/go_modules/helpers
COPY hex/helpers /opt/hex/helpers
COPY npm_and_yarn/helpers /opt/npm_and_yarn/helpers
COPY python/helpers /opt/python/helpers
COPY terraform/helpers /opt/terraform/helpers

ENV DEPENDABOT_NATIVE_HELPERS_PATH="/opt" \
  PATH="$PATH:/opt/terraform/bin:/opt/python/bin:/opt/go_modules/bin:/opt/dep/bin" \
  MIX_HOME="/opt/hex/mix"

RUN bash /opt/terraform/helpers/build /opt/terraform && \
  bash /opt/python/helpers/build /opt/python && \
  bash /opt/dep/helpers/build /opt/dep && \
  bash /opt/bundler/helpers/v1/build /opt/bundler/v1 && \
  bash /opt/go_modules/helpers/build /opt/go_modules && \
  bash /opt/npm_and_yarn/helpers/build /opt/npm_and_yarn && \
  bash /opt/hex/helpers/build /opt/hex && \
  bash /opt/composer/helpers/v2/build /opt/composer/v2 && \
  bash /opt/composer/helpers/v1/build /opt/composer/v1
