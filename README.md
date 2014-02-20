# Riak CS Service Broker for Cloud Foundry 

### Build Status

[![Build Status](https://travis-ci.org/cloudfoundry/cf-riak-cs-broker.png?branch=master)](https://travis-ci.org/cloudfoundry/cf-riak-cs-broker) (master)


### Description

This is a [Riak CS](http://basho.com/riak-cloud-storage/) service broker for the Cloud Foundry [v2 services API](http://docs.cloudfoundry.com/docs/running/architecture/services/api.html).

This service broker allows users to provision instances of an S3-compatible storage service.
Provisioning the service creates a Riak CS bucket.
Binding an application creates unique credentials for that application to access the bucket.

Based on [the Riak service broker by @hectcastro](https://github.com/hectcastro/cf-riak-service-broker).

### Prerequisites 

This service broker must be configured to access a Riak CS cluster.
You can use Bosh to deploy such a cluster alongside Cloud Foundry, or it can be deployed locally by [bosh-lite](https://github.com/cloudfoundry/bosh-lite) for development purposes.
A Bosh release for Riak and Riak CS can be found [here](https://github.com/cloudfoundry/cf-riak-cs-release).

### Testing

To run all non-integration specs: `rake spec`

To run integration tests that actually talk to the Riak CS cluster specified by the environment variables: `rake spec:integration`

### Usage 

We use the [dotenv gem](https://github.com/bkeepers/dotenv), which allows you to set those values either by setting environment variables, or by specifying them in a `.env` file.
The [.env.example](.env.example) file provides a template for your broker configuration.
Copy it, rename it to `.env`, and make changes accordingly.

Start the Riak CS Service Broker:

```
bundle exec rackup
```

Add the broker to Cloud Foundry as described by [the service broker documentation](http://docs.cloudfoundry.com/docs/running/architecture/services/managing-service-brokers.html).
