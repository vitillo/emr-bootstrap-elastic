ElasticSearch on EMR
====================

## Launch a cluster
aws emr create-cluster --name ElasticCluster --ami-version 3.3 --instance-type c3.4xlarge --instance-count 1 --service-role EMR_DefaultRole --ec2-attributes KeyName=mozilla_vitillo,InstanceProfile=telemetry-spark-emr --bootstrap-actions Path=s3://telemetry-elastic-emr/elasticsearch_install.rb Path=s3://telemetry-elastic-emr/kibana_install.rb
