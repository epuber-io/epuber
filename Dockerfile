FROM ruby:2.3.3

ENV LC_ALL=C.UTF-8
RUN apt update -y && apt install zip nodejs -y
RUN wget -nv -O- https://raw.githubusercontent.com/kovidgoyal/calibre/master/setup/linux-installer.py | \
    python -c "import sys; main=lambda:sys.stderr.write('Download failed\n'); exec(sys.stdin.read()); main()"
RUN gem install bundler
