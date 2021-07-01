FROM jruby:9.2.11.1-jdk14
WORKDIR /app
ARG UID=3000

ENV BUNDLE_PATH=/app/vendor/bundle

RUN apt-get update && apt-get install --no-install-recommends -y gcc &&  \
        rm -rf /var/lib/apt/lists*

RUN useradd -u $UID app -d /app
RUN mkdir /app/tmp
RUN chown -R app /app
USER app

RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
COPY --chown=app Gemfile Gemfile.lock /app/
RUN bundle install

COPY . /app


