#!/usr/bin/ruby

require 'rubygems'
require 'json'
require 'emr/common'

def run(cmd)
  raise "Command failed: #{cmd}" unless system(cmd)
end

def sudo(cmd)
  run("sudo #{cmd}")
end

@is_master = Emr::JsonInfoFile.new('instance')['isMaster'].to_s == 'true'
@kibana_version = "4.0.2"
@target_dir = "/home/hadoop/kibana/"
@es_port_num = 9800

def install_kibana(target_dir, kibana_version)
  tarball = "kibana-#{kibana_version}-linux-x64.tar.gz"
  run("wget https://download.elastic.co/kibana/kibana/#{tarball} --no-check-certificate")
  # extract to the target directory
  run("mkdir " + target_dir)
  run("tar xvf " + tarball + " -C " + target_dir)
  install_dir = "#{target_dir}kibana-#{kibana_version}-linux-x64/"

  # replace config.js with new config file
  kibana_config()
  run("mv -f kibana.yml #{install_dir}config/kibana.yml")
  run("#{install_dir}bin/kibana &")
end

# returns the kibana config file
def kibana_config
  File.open("kibana.yml", "w") do |config|
    config.puts(<<-eos
port: 5601
host: "0.0.0.0"
elasticsearch_url: "http://localhost:#{@es_port_num}"
elasticsearch_preserve_host: true
kibana_index: ".kibana"
default_app_id: "discover"
request_timeout: 300000
shard_timeout: 0
verify_ssl: true
bundled_plugin_ids:
 - plugins/dashboard/index
 - plugins/discover/index
 - plugins/doc/index
 - plugins/kibana/index
 - plugins/markdown_vis/index
 - plugins/metric_vis/index
 - plugins/settings/index
 - plugins/table_vis/index
 - plugins/vis_types/index
 - plugins/visualize/index
    eos
    )
  end
end

def clean_up
  run("rm kibana-#{@kibana_version}-linux-x64.tar.gz")
end

if @is_master
  install_kibana(@target_dir, @kibana_version)
  clean_up()
end
