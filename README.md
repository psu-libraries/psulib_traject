# psulib_traject

This project transforms MARC records into Solr documents using the [Traject](https://github.com/traject-project/traject) tools developed by [Bill Dueber](https://github.com/billdueber/) and [Jonathan Rochkind](https://github.com/jrochkind).

# Dependencies
## Java
To run JRuby you will need a JRE (the JVM runtime environment) version 7 or higher.
```
$ java --version
  java 9
  Java(TM) SE Runtime Environment (build 9+181)
  Java HotSpot(TM) 64-Bit Server VM (build 9+181, mixed mode)
```

## Ruby
Follow these instructions to [install JRuby](https://git.psu.edu/i-tech/psulib_traject/wikis/Install-JRuby) if you do not already have it.
```
$ ruby --version
  jruby 9.2.0.0
```

# Development setup
1.  Make sure you have ssh keys established on your machine and make sure your public key is stored on git.psu.edu: https://docs.gitlab.com/ee/gitlab-basics/create-your-ssh-keys.html
1.  Clone the application (parallel to psulib_blacklight folder) and install.
    ``` 
    $ git clone git@git.psu.edu:i-tech/psulib_traject.git
    $ cd psulib_traject
    $ bundle install
    ```
 
1.  Install [Traject](https://git.psu.edu/i-tech/psulib_traject/wikis/Install-JRuby)
    ```
    $ gem install traject -v 3.0.0.alpha.1
    ```
    
1. Install [Traject::Marc4JReader](https://github.com/traject/traject-marc4j_reader)
   ```
   $ gem install traject-marc4j_reader
   ```
   
# Build an index
1. Start up solr. You need to run the clean command if running a full index.
   ```
   $ bundle exec solr_wrapper -d .solr_wrapper.yml clean
   $ bundle exec solr_wrapper
   ```

1. Index records
   You can download a sample file from https://psu.app.box.com/folder/53004724072.
   ```
   $ bundle exec traject -c psulib_config.rb /full/path/to/sample_psucat.mrc 
   ```

# Traject in debug mode
For testing purposes you can run traject with the `--debug-mode` flag to
display the output to the console (and not push the data to Solr).
```
$ bundle exec traject --debug-mode -c psulib_config.rb /full/path/to/marcfile.mrc
```
