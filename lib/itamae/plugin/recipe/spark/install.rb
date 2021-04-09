version = ENV['SPARK_VERSION'] || Itamae::Plugin::Recipe::Spark::SPARK_VERSION
hadoop_version = ENV['HADOOP_VERSION'] || Itamae::Plugin::Recipe::Hadoop::HADOOP_VERSION
hadoop_type = if Gem::Version.create(hadoop_version) >= Gem::Version.create('3.2')
                '3.2'
              elsif Gem::Version.create(hadoop_version) >= Gem::Version.create('2.7')
                '2.7'
              else
                raise "Hadoop version #{hadoop_version} is not supported."
              end

execute "download spark-#{version}" do
  cwd '/tmp'
  command <<-EOF
    rm -f spark-#{version}-bin-hadoop#{hadoop_type}.tgz
    wget https://archive.apache.org/dist/spark/spark-#{version}/spark-#{version}-bin-hadoop#{hadoop_type}.tgz
  EOF
  not_if "test -e /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/INSTALLED || echo #{::File.read(::File.join(::File.dirname(__FILE__), "spark-#{version}_hadoop_#{hadoop_type}_sha256.txt")).strip} | sha256sum -c"
end

directory '/opt/spark' do
  user 'root'
  owner 'root'
  group 'root'
  mode '755'
end

execute "install spark-#{version}" do
  cwd '/tmp'
  command <<-EOF
    rm -Rf spark-#{version}-bin-hadoop#{hadoop_type}/
    tar zxf spark-#{version}-bin-hadoop#{hadoop_type}.tgz
    sudo rm -Rf /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}
    sudo mv spark-#{version}-bin-hadoop#{hadoop_type} /opt/spark/
    sudo touch /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/INSTALLED
  EOF
  not_if "test -e /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/INSTALLED"
end

execute 'install hadoop aws jars' do
  cwd '/opt/hadoop/current'
  command <<-EOF
    cp -f share/hadoop/tools/lib/aws-java-sdk-*.jar \
        /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/
    cp -f share/hadoop/tools/lib/hadoop-aws-#{hadoop_version}.jar \
        /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/
  EOF
  not_if "test `ls -1 /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/ | egrep '(hadoop-)?aws-.*' | wc -l` = 4"
end

template "/opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/conf/spark-defaults.conf"

if ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY']
  template "/opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/conf/hdfs-site.xml" do
    variables aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
              aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  end
end

link '/opt/spark/current' do
  to "/opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}"
  user 'root'
  force true
end

