FROM ubuntu:18.04

RUN apt-get update && apt-get install -y curl wget git

RUN curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest \
    | grep browser_download_url \
    | grep "extended_.*_Linux-64bit.tar.gz" \
    | cut -d "\"" -f 4 \
    | wget -qi -

RUN tar -xzvf $(find . -name "hugo_extended_*")

RUN mv ./hugo /usr/local/bin/hugo