# psulib_traject
This project transforms MARC records into Solr documents using the [Traject](https://github.com/traject-project/traject) tools developed by [Bill Dueber](https://github.com/billdueber/) and [Jonathan Rochkind](https://github.com/jrochkind).

Development Setup:
```
mkdir psulib_traject    (parallel to psulib_blacklight folder)
cd psulib_traject

rbenv install jruby-9.1.16.0
rbenv local jruby-9.1.16.0

gem install traject
gem install traject-marc4j_reader

```

To build your indexes:
```
solr_wrapper -d .solr_wrapper.yml clean
bundle exec solr_wrapper

traject -c psulib_config.rb /full/path/to/marcfile.mrc

curl http://YOUR_BASE_SOLR_URL:8983/solr/blacklight-core/update?commit=true
```

For testing purposes you can run `traject` with the `--debug-mode` flag to
display the output to the console (and not push the data to Solr).

```
traject --debug-mode -c psulib_config.rb /full/path/to/marcfile.mrc
```
