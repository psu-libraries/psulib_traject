[![Maintainability](https://api.codeclimate.com/v1/badges/f877d0681e38deb0f3c8/maintainability)](https://codeclimate.com/github/psu-libraries/psulib_traject/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f877d0681e38deb0f3c8/test_coverage)](https://codeclimate.com/github/psu-libraries/psulib_traject/test_coverage)

# psulib_traject

## Dependencies

### Java
To run JRuby you will need a JRE (the JVM runtime environment) version 7 or higher.
```
$ java --version
  java 9
  Java(TM) SE Runtime Environment (build 9+181)
  Java HotSpot(TM) 64-Bit Server VM (build 9+181, mixed mode)
```

### Ruby
Follow these instructions to [install JRuby](https://github.com/psu-libraries/psulib_traject/wiki/Install-JRuby) if you do not already have it.
```
$ ruby --version
  jruby 9.2.11.1
```

## Development Setup

1.  [Make sure you have ssh keys established on your machine](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#generating-a-new-ssh-key)
1.  [Make sure you have docker installed and running](https://docs.docker.com/install/)
1.  Clone the application and install.
    ``` 
    $ git clone git@github.com:psu-libraries/psulib_traject.git
    $ cd psulib_traject
    $ bundle install
    ```
   
## Build an Index

1. Solr config files need to be copied from [psulib_blacklight](https://github.com/psu-libraries/psulib_blacklight/tree/master/solr/conf):
    
    ```
    $ bundle exec rake solr:conf
    ```
   
1. Start Solr

    If Docker Solr isn't running (check `docker ps`) run

    ```
    $ bundle exec rake solr:up
    ```
    
1. Convert marc records and import into Solr

   ```
   $ bundle exec traject -c lib/traject/psulib_config.rb solr/sample_data/sample_psucat.mrc 
   ```
   
   You can download [other sample files from Box](https://psu.app.box.com/folder/53004724072).
   
## Traject in debug mode

For testing purposes you can run traject with the `--debug-mode` flag to
display the output to the console (and not push the data to Solr).

```
$ bundle exec traject --debug-mode -c lib/traject/psulib_config.rb solr/sample_data/sample_psucat.mrc
```

## HathiTrust ETAS data

To generate a synthesized HathiTrust overlap report locally, you can run 

```
RUBY_ENVIRONMENT=dev bundle exec rake hathitrust:process_hathi_etas`.
```

You will need the overlap file provided by HathiTrust (`overlap_[date]_psu.tsv`) and [hathi_field_list.txt](https://www.hathitrust.org/filebrowser/download/269539) in your `ignorethis_hathi/` directory.

Also make sure the below settings in your `indexer_settings_dev.yml` file are set with the correct info:


```
hathi_load_period: 20200501
overlap_file: overlap_20200518_psu.tsv
```

The generated file is used during the import process to index `ht_id` by checking 
on an existing match to OCLC number and also for "Access Online". For more info, see
[Synthesizing-overlap-data-from-HathiTrust](https://github.com/psu-libraries/psulib_blacklight/wiki/Synthesizing-overlap-data-from-HathiTrust)
