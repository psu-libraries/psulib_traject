[![Maintainability](https://api.codeclimate.com/v1/badges/f877d0681e38deb0f3c8/maintainability)](https://codeclimate.com/github/psu-libraries/psulib_traject/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f877d0681e38deb0f3c8/test_coverage)](https://codeclimate.com/github/psu-libraries/psulib_traject/test_coverage)

# psulib_traject

## Dependencies

### Java
To run JRuby you will need java version 21 or higher.

    $ java --version
      openjdk version "21.0.8" 2025-07-15
      OpenJDK Runtime Environment Homebrew (build 21.0.8)
      OpenJDK 64-Bit Server VM Homebrew (build 21.0.8, mixed mode, sharing)

### Ruby
Follow these instructions to [install JRuby](https://github.com/psu-libraries/psulib_traject/wiki/Install-JRuby) if you
do not already have it.

    $ ruby --version
      jruby 10.0.2.0

## Development Setup

[Make sure you have ssh keys established on your machine](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#generating-a-new-ssh-key)

[Make sure you have docker installed and running](https://docs.docker.com/install/)

Clone the application and install:

    $ git clone git@github.com:psu-libraries/psulib_traject.git
    $ cd psulib_traject
    $ bundle install

## Configuration

For local development, you can change the settings by adding configuration files. These will be ignored by git.

### Solr

Create 2 files: `config/settings.local.yml` and `config/settings/test.local.yml` and add the following lines to each:
    
    solr:
      url: http://localhost:8983/solr/
      port: 8983

Change the URL and port numbers if you want to use a different port.
You will also need to set your environment variables with the Solr username and password.

### Traject

When using jruby, traject will use multiple threads, but we want to tailor that to our system. In
`config/settings.local.yml` add:

    processing_thread_pool: 5
   
## Build an Index

Start Solr via the Docker container
    
    $ bundle exec rake docker:up

This will download and configure Solr, if it's not already present, or if it is, start up the container again.
If you need to reconfigure Solr:

    $ bundle exec rake docker:clean
    $ bundle exec rake docker:conf
    
Convert marc records and import into Solr

    $ bundle exec traject -c config/traject.rb solr/sample_data/sample_psucat.mrc 
      
## Traject in debug mode

For testing purposes you can run traject with the `--debug-mode` flag to
display the output to the console (and not push the data to Solr).

    $ bundle exec traject --debug-mode -c config/traject.rb solr/sample_data/sample_psucat.mrc