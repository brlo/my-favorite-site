# syntax=docker/dockerfile:1
FROM ruby:3.1.2
RUN apt-get update -qq

# Extend shell by custom moiprofi bash-config
RUN echo                                               >> /root/.bashrc && \
    echo "if [ -f /app/res/bash/.bash_config ]; then " >> /root/.bashrc && \
    echo ". /app/res/bash/.bash_config               " >> /root/.bashrc && \
    echo "fi                                         " >> /root/.bashrc && \
    echo                                               >> /root/.bashrc

# Don't install docs for gems by default
RUN echo "gem: --no-document" > /root/.gemrc
# Same, global
RUN echo "gem: --no-document" > /etc/gemrc

RUN echo -e "Europe/Moscow" >/etc/timezone && cat /usr/share/zoneinfo/Europe/Moscow >/etc/localtime

# UTF-8 locale
RUN apt-get install -y --no-install-recommends locales && \
    dpkg-reconfigure locales             && \
    locale-gen C.UTF-8                   && \
    /usr/sbin/update-locale LANG=C.UTF-8

ENV LC_ALL C.UTF-8

# nodejs
# RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
# RUN apt-get install -y nodejs

# minificators (CSS, JS)
RUN apt install -y uglifyjs cleancss

WORKDIR /app

# Configure the main process to run when running the image
CMD ["/bin/bash /app/start.sh"]
