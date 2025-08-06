# syntax=docker/dockerfile:1

FROM ruby:3.4.1
# # При сборке образа на macOS используй это:
# FROM --platform=linux/amd64 ruby:3.4.1


RUN apt-get update -qq

# создать группу "app" с id 1001 и пользователя "app" в этой группе с id 1000
RUN groupadd -g 1001 app && useradd -r -u 1000 -g app -m -d /home/app app

# Extend shell by custom moiprofi bash-config
RUN echo                                               >> /home/app/.bashrc && \
    echo "if [ -f /app/res/bash/.bash_config ]; then " >> /home/app/.bashrc && \
    echo ". /app/res/bash/.bash_config               " >> /home/app/.bashrc && \
    echo "fi                                         " >> /home/app/.bashrc && \
    echo                                               >> /home/app/.bashrc

# Don't install docs for gems by default
RUN echo "gem: --no-document" > /home/app/.gemrc
# Same, global
RUN echo "gem: --no-document" > /etc/gemrc

RUN echo -e "Europe/Moscow" >/etc/timezone && cat /usr/share/zoneinfo/Europe/Moscow >/etc/localtime

# UTF-8 locale
RUN apt-get install -y --no-install-recommends locales && \
    dpkg-reconfigure locales             && \
    locale-gen C.UTF-8                   && \
    /usr/sbin/update-locale LANG=C.UTF-8

ENV LC_ALL=C.UTF-8

# # Обновляем пакеты и устанавливаем зависимости для Google Chrome
# RUN apt-get update && apt-get install -y \
#     wget \
#     gnupg \
#     apt-transport-https \
#     ca-certificates \
#     && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg \
#     && echo "deb [signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
#     && apt-get update && apt-get install -y \
#     google-chrome-stable \
#     && rm -rf /var/lib/apt/lists/*

# Устанавливаем японские и прочие редкие шрифты
RUN apt-get update && apt-get install -y \
    fonts-ipafont-gothic \
    fonts-ipafont-mincho \
    fonts-noto-cjk

# Устанавливаем Node.js, необходимый для работы Puppeteer, который используется гемом Grover
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    && npm install -g n \
    && n stable \
    && apt-get purge -y npm

# Создаем каталог для гемов в домашней директории пользователя app
RUN mkdir -p /home/app/gems

# Настраиваем Bundler использовать этот каталог
ENV BUNDLE_PATH=/home/app/gems

# Изменяем права доступа к каталогу для гемов
RUN chown -R app:app /home/app

WORKDIR /app

USER app

# Устанавливаем Puppeteer и Chrome
# RUN npx puppeteer browsers install chrome
npm install puppeteer-core

# Configure the main process to run when running the image
CMD ["/bin/bash /app/start.sh"]
