FROM ruby:3.4-slim-bookworm

# build-essential: eventmachine and http_parser.rb compile from source.
# git: some plugins shell out to git for page metadata.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential git \
 && rm -rf /var/lib/apt/lists/*

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    JEKYLL_ENV=development

WORKDIR /srv/jekyll

EXPOSE 4000 35729

# --force-polling: inotify does not fire across macOS bind mounts, so without
# it saving a file never triggers a rebuild.
CMD ["bundle","exec","jekyll","serve","--host","0.0.0.0","--livereload","--force-polling"]
