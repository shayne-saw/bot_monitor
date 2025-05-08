FROM mcr.microsoft.com/devcontainers/base:ubuntu
# Install the xz-utils package
RUN apt-get update && apt-get install -y \
    xz-utils \
    curl \
    git \
    build-essential \
    libssl-dev \
    libncurses5-dev \
    libwxgtk3.0-gtk3-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libpng-dev \
    libssh-dev \
    unixodbc-dev \
    autoconf \
    fop \
    libxml2-utils \
    xsltproc \
    wget \
    inotify-tools \
    tzdata

USER vscode

# Install asdf version manager
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.15.0 && \
    echo '. ~/.asdf/asdf.sh' >> ~/.bashrc

ENV PATH="/home/vscode/.asdf/bin:${PATH}"    

RUN asdf plugin-add erlang && \
    asdf install erlang 27.0 && \
    asdf global erlang 27.0

RUN asdf plugin-add elixir && \
    asdf install elixir 1.18.1 && \
    asdf global elixir 1.18.1