[![Maintainability](https://api.codeclimate.com/v1/badges/f877d0681e38deb0f3c8/maintainability)](https://codeclimate.com/github/psu-libraries/psulib_traject/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f877d0681e38deb0f3c8/test_coverage)](https://codeclimate.com/github/psu-libraries/psulib_traject/test_coverage)

# psulib_traject

## Dependencies

### Java
To run JRuby you will need a JRE (the JVM runtime environment) version 7 or higher.

    $ java --version
      java 9
      Java(TM) SE Runtime Environment (build 9+181)
      Java HotSpot(TM) 64-Bit Server VM (build 9+181, mixed mode)

### Ruby
Follow these instructions to [install JRuby](https://github.com/psu-libraries/psulib_traject/wiki/Install-JRuby) if you
do not already have it.

    $ ruby --version
      jruby 9.3.9.0

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

    hathi_overlap_path: spec/fixtures/hathitrust/overlap.tsv
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

## HathiTrust ETAS data

HathiTrust access level can be recorded in `ht_access_ss`. It will expect to have an overlap report tsv from HathiTrust
at `ConfigSettings.hathi_overlap_path`. This file should be the latest overlap report from HathiTrust.

Because the monthly overlap file lives in a restricted area that can only be accessed by signing in to Box at UMich, we
will need to manually set the overlap.tsv prior to indexing operations when there is a new overlap. This can be done by
`scp`ing the file up to the location specified in `ConfigSettings.hathi_overlap_path`.
