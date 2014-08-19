# Riak CS Service Broker for Cloud Foundry 

### Build Status

[![Build Status](https://travis-ci.org/cloudfoundry-incubator/cf-riak-cs-broker.png?branch=master)](https://travis-ci.org/cloudfoundry-incubator/cf-riak-cs-broker) (master)


### Description

This is a [Riak CS](http://basho.com/riak-cloud-storage/) service broker for the Cloud Foundry [v2 services API](http://docs.cloudfoundry.org/services/api.html).

This service broker allows users to provision instances of an S3-compatible storage service.
Provisioning the service creates a Riak CS bucket.
Binding an application creates unique credentials for that application to access the bucket.

Based on [the Riak service broker by @hectcastro](https://github.com/hectcastro/cf-riak-service-broker).

### Prerequisites 

This service broker must be configured to access a Riak CS cluster.
You can use Bosh to deploy such a cluster alongside Cloud Foundry, or it can be deployed locally by [bosh-lite](https://github.com/cloudfoundry/bosh-lite) for development purposes.
A Bosh release for Riak and Riak CS can be found [here](https://github.com/cloudfoundry-incubator/cf-riak-cs-release).

### Testing

To run all specs: `rake`

### Usage 

Configure the `settings.yml` file for your environment.

Start the Riak CS Service Broker:

```
bundle exec rackup
```

Add the broker to Cloud Foundry as described by [the service broker documentation](http://docs.cloudfoundry.org/services/managing-service-brokers.html).
