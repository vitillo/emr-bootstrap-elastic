#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'emr/common'
require 'rexml/document'

def run(cmd)
  raise "Command failed: #{cmd}" unless system(cmd)
end

def sudo(cmd)
  run("sudo #{cmd}")
end

@is_master = Emr::JsonInfoFile.new('instance')['isMaster'].to_s == 'true'
@cluster_name = Emr::JsonInfoFile.new('job-flow')['jobFlowId'].to_s
sudo("cp /mnt/var/lib/instance-controller/extraInstanceData.json" +
     " /mnt/var/lib/info/extraInstanceData.json")
@region = Emr::JsonInfoFile.new('extraInstanceData')['region'].to_s
@target_dir = "/mnt/elasticsearch/"
# this is where additional logs are sent in case terminal output needs to be caught
@log_dir = "/mnt/elasticsearch/"
@elasticsearch_version = "1.5.2"
@cloud_aws_version = "2.5.0"
@elasticsearch_port_master = 9800
@elasticsearch_port_slaves = 9802

def install_elasticsearch(target_dir, log_dir, elasticsearch_version)
  tarball = "elasticsearch-#{elasticsearch_version}.tar.gz"
  run "wget https://download.elasticsearch.org/elasticsearch/elasticsearch/#{tarball} --no-check-certificate"
  # extract to the target directory
  run("mkdir " + target_dir)
  run("tar xvf " + tarball + " -C " + target_dir)
  File.open("elasticsearch.yml", "w") do |config|
    if @is_master==true
       config.puts("http.port: #{@elasticsearch_port_master}")
    else
       config.puts("http.port: #{@elasticsearch_port_slaves}")
    end
    config.puts("node.master: #{@is_master}")
    config.puts("node.data: true")
    config.puts("cluster.name: #{@cluster_name}")
    config.puts("discovery.type: ec2")
    config.puts("cloud.aws.region: #{@region}")
    config.puts("discovery.ec2.tag.aws:elasticmapreduce:job-flow-id: #{@cluster_name}")
  end

  install_dir = "#{target_dir}elasticsearch-#{elasticsearch_version}/"
  # installing elasticsearch aws plugin
  run("#{install_dir}bin/plugin -install elasticsearch/elasticsearch-cloud-aws/#{@cloud_aws_version}")
  # replace yaml with new config file
  run("mv elasticsearch.yml #{install_dir}config/elasticsearch.yml")
  puts("Starting elasticsearch in the background. Logs found in \'#{log_dir}elasticsearch.log\'")
  sudo("#{install_dir}bin/elasticsearch &> #{log_dir}/elasticsearch.log &")
end

def clean_up
  run "rm elasticsearch-#{@elasticsearch_version}.tar.gz"
end

install_elasticsearch(@target_dir, @log_dir, @elasticsearch_version)
clean_up
