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

cp sample.env .env
vi .env    (Change the SOLR_URL to point to your instance of SOLR)
```

To build your indexes:
```
solr_wrapper -d .solr_wrapper.yml clean
bundle exec solr_wrapper

source .env (.env defines SOLR_URL and is only necessary to run once during your session)

traject -c psulib_config.rb /full/path/to/marcfile.mrc

curl http://YOUR_BASE_SOLR_URL:8983/solr/blacklight-core/update?commit=true
```

For testing purposes you can run `traject` with the `--debug-mode` flag to
display the output to the console (and not push the data to Solr).

```
traject --debug-mode -c config.rb /full/path/to/marcfile.mrc
```


(.env defines SOLR_URL)

Notice that in this case we run Traject against our daily *update* MARC files,
not against our full MARC files. The daily update files only include records
that changed in the last day or two. (TODO: how long does it take to run it
against the full files?)
