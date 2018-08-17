# psulib_traject

This project transforms MARC records into Solr documents using the [Traject](https://github.com/traject-project/traject) tools developed by [Bill Dueber](https://github.com/billdueber/) and [Jonathan Rochkind](https://github.com/jrochkind).

# Dependencies

# Development setup
1.  Make sure you have ssh keys established on your machine and make sure your public key is stored on git.psu.edu: https://docs.gitlab.com/ee/gitlab-basics/create-your-ssh-keys.html
1.  Clone the application (parallel to psulib_blacklight folder) and install:
    ``` 
    git clone git@git.psu.edu:i-tech/psulib_traject.git
    cd psulib_traject
    bundle install
    ```
    
# Build an index
1. Start up solr. You need to run the clean command if running a full index.
   ```
   $ cd /path/to/psul_blacklight   
   $ solr_wrapper -d .solr_wrapper.yml clean
   $ bundle exec solr_wrapper
   ```

1. Index records
   You can download the full marc records from https://psu.app.box.com/file/288054273524.
   ```
   $ cd /path/to/psulib_traject
   $ traject -c psulib_config.rb /full/path/to/marcfile.mrc
   ```

# Traject in debug mode
For testing purposes you can run traject with the `--debug-mode` flag to
display the output to the console (and not push the data to Solr).
```
$ traject --debug-mode -c psulib_config.rb /full/path/to/marcfile.mrc
```
