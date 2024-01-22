FROM jruby:9.4.2.0
WORKDIR /app
ARG UID=1000

ENV BUNDLE_PATH=/app/vendor/bundle

RUN apt-get update && apt-get install --no-install-recommends -y \
    gcc \
    netbase \
    &&  \
    rm -rf /var/lib/apt/lists*

RUN useradd -u $UID app -d /app
RUN mkdir /app/tmp
RUN chown -R app /app
USER app

COPY --chown=app Gemfile Gemfile.lock /app/
RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
RUN bundle install

COPY --chown=app . /app


