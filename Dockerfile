FROM jruby:9.2.11.1-jdk14
WORKDIR /app

RUN apt-get update && apt-get install -y gcc

COPY Gemfile Gemfile.lock /app
RUN bundle install 

COPY . /app





