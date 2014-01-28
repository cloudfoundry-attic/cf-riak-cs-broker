# Riak CS Service Broker for Cloud Foundry 

This is a Riak CS service broker for the Cloud Foundry [v2 services](http://docs.cloudfoundry.com/docs/running/architecture/services/api.html) API.

The Riak CS service broker allows users to provision instances of an S3-compatible storage service.  Each provisioned instance is a bucket in Riak CS. Binding an application to a bucket generates write credentials and makes the bucket URI and credentials available to the application.