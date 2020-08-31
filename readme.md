# An example of a SolrCloud Docker container for Sitecore v10

These files can create a SolrCloud container that can be used with a Sitecore 10 instance under Docker.
The files have been adjusted from the Solr container files in [the Sitecore Docker examples repo](https://github.com/sitecore/docker-examples).

The default "solr" service Sitecore provide can be replaced using these files.

See [this blog post for further details](https://jermdavis.wordpress.com/2020/08/31/solrcloud-with-sitecore-10/) and explanations of how this works.

## Running

* Clone the repo
* Open PowerShell in the cloned folder
* Run `docker-compose up`
* Open a web browser to `http://localhost:8984/solr/`