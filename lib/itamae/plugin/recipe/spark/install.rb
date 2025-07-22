version = ENV['SPARK_VERSION'] || Itamae::Plugin::Recipe::Spark::SPARK_VERSION
hadoop_version = ENV['HADOOP_VERSION'] || Itamae::Plugin::Recipe::Hadoop::HADOOP_VERSION
hadoop_type = if Gem::Version.create(hadoop_version) >= Gem::Version.create('3.3.3')
                '3'
              elsif Gem::Version.create(hadoop_version) >= Gem::Version.create('3.2')
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

spark_redshift_version = ENV['SPARK_REDSHIFT_VERSION'] || Itamae::Plugin::Recipe::Spark::SPARK_REDSHIFT_VERSION
spark_avro_version = ENV['SPARK_AVRO_VERSION'] || Itamae::Plugin::Recipe::Spark::SPARK_AVRO_VERSION
minimal_json_version = Itamae::Plugin::Recipe::Spark::MINIMAL_JSON_VERSION
redshift_jdbc_version = ENV['REDSHIFT_JDBC_VERSION'] || Itamae::Plugin::Recipe::Spark::REDSHIFT_JDBC_VERSION
fastdoubleparser_version = Itamae::Plugin::Recipe::Spark::FASTDOUBLEPARSER_VERSION
jets3t_version = Itamae::Plugin::Recipe::Spark::JETS3T_VERSION
aws_secretsmanager_caching_java_version = Itamae::Plugin::Recipe::Spark::AWS_SECRETSMANAGER_CACHING_JAVA_VERSION
aws_secretsmanager_jdbc_version = Itamae::Plugin::Recipe::Spark::AWS_SECRETSMANAGER_JDBC_VERSION
execute "download spark-redshift-#{spark_redshift_version} and dependencies" do
  cwd '/tmp'
  command <<-EOF
    wget -q https://repo1.maven.org/maven2/io/github/spark-redshift-community/spark-redshift_#{spark_redshift_version.split('-', 2).first}/#{spark_redshift_version.split('-', 2).last}/spark-redshift_#{spark_redshift_version}.jar -O spark-redshift_#{spark_redshift_version}.jar
    wget -q https://repo1.maven.org/maven2/org/apache/spark/spark-avro_#{spark_avro_version.split('-').first}/#{spark_avro_version.split('-').last}/spark-avro_#{spark_avro_version}.jar -O spark-avro_#{spark_avro_version}.jar
    wget -q https://repo1.maven.org/maven2/com/amazon/redshift/redshift-jdbc42/#{redshift_jdbc_version}/redshift-jdbc42-#{redshift_jdbc_version}.jar -O RedshiftJDBC42-#{redshift_jdbc_version}.jar
    #{if spark_redshift_version.split('-', 2).last == '5.0.3'
        <<-EOS
          wget -q https://repo1.maven.org/maven2/com/eclipsesource/minimal-json/minimal-json/#{minimal_json_version}/minimal-json-#{minimal_json_version}.jar -O minimal-json-#{minimal_json_version}.jar
          wget -q https://repo1.maven.org/maven2/ch/randelshofer/fastdoubleparser/#{fastdoubleparser_version}/fastdoubleparser-#{fastdoubleparser_version}.jar -O fastdoubleparser-#{fastdoubleparser_version}.jar
          wget -q https://repo1.maven.org/maven2/net/java/dev/jets3t/jets3t/#{jets3t_version}/jets3t-#{jets3t_version}.jar -O jets3t-#{jets3t_version}.jar
        EOS
      elsif spark_redshift_version.split('-', 2).last == '6.2.0-spark_3.4'
        <<-EOS
          wget -q https://repo1.maven.org/maven2/com/amazonaws/secretsmanager/aws-secretsmanager-jdbc/#{aws_secretsmanager_jdbc_version}/aws-secretsmanager-jdbc-#{aws_secretsmanager_jdbc_version}.jar -O aws-secretsmanager-jdbc-#{aws_secretsmanager_jdbc_version}.jar
        EOS
      elsif spark_redshift_version.split('-', 2).last == '6.4.3-spark_3.5'
        <<-EOS
          wget -q https://repo1.maven.org/maven2/com/amazonaws/secretsmanager/aws-secretsmanager-caching-java/#{aws_secretsmanager_caching_java_version}/aws-secretsmanager-caching-java-#{aws_secretsmanager_caching_java_version}.jar -O aws-secretsmanager-caching-java-#{aws_secretsmanager_caching_java_version}.jar
          wget -q https://repo1.maven.org/maven2/com/amazonaws/secretsmanager/aws-secretsmanager-jdbc/#{aws_secretsmanager_jdbc_version}/aws-secretsmanager-jdbc-#{aws_secretsmanager_jdbc_version}.jar -O aws-secretsmanager-jdbc-#{aws_secretsmanager_jdbc_version}.jar
        EOS
      end}
  EOF
  
  not_if "sha256sum -c #{File.join(File.dirname(__FILE__), "spark-redshift_#{spark_redshift_version}_sha256.txt")}"
end

execute 'download aws-java-sdk' do
  cwd '/tmp'
  command <<-EOF
    wget -q https://sdk-for-java.amazonwebservices.com/latest/aws-java-sdk.zip
  EOF
  not_if 'test -e /tmp/aws-java-sdk.zip'
end


aws_sdk_v2_version = ENV['AWS_SDK_V2_VERSION'] || Itamae::Plugin::Recipe::Spark::AWS_SDK_V2_VERSION
aws_sdk_v2_jars = %w[
  apache-client
  arns
  auth
  aws-core
  aws-query-protocol
  aws-xml-protocol
  checksums
  checksums-spi
  endpoints-spi
  http-auth
  http-auth-aws
  http-auth-spi
  http-client-spi
  identity-spi
  json-utils
  metrics-spi
  profiles
  protocol-core
  regions
  retries
  retries-spi
  s3
  s3-transfer-manager
  sdk-core
  third-party-jackson-core
  utils
]
reactive_streams_version = Itamae::Plugin::Recipe::Spark::REACTIVE_STREAMS_VERSION
if spark_redshift_version.split('-', 2).last == '6.4.3-spark_3.5'
  directory '/tmp/aws_java_sdk_v2' do
    action :create
  end

  aws_sdk_v2_jars.each do |jar|
    execute "download aws java sdk v2 #{jar} jar" do
      cwd '/tmp/aws_java_sdk_v2'
      command <<-EOF
        wget -q https://repo1.maven.org/maven2/software/amazon/awssdk/#{jar}/#{aws_sdk_v2_version}/#{jar}-#{aws_sdk_v2_version}.jar
      EOF
      not_if "test -e /tmp/aws_java_sdk_v2/#{jar}-#{aws_sdk_v2_version}.jar"
    end
  end

  execute "download reactive_streams jar" do
    cwd '/tmp/aws_java_sdk_v2'
    command <<-EOF
      wget -q https://repo1.maven.org/maven2/org/reactivestreams/reactive-streams/#{reactive_streams_version}/reactive-streams-#{reactive_streams_version}.jar
    EOF
    not_if "test -e /tmp/aws_java_sdk_v2/reactive-streams-#{reactive_streams_version}.jar"
  end
end


execute 'unzip aws-java-sdk' do
  cwd '/tmp'
  command <<-EOF
    unzip -o aws-java-sdk.zip aws-java-sdk-*/lib/aws-java-sdk-*.jar
    rm -rf aws-java-sdk-*/lib/aws-java-sdk-*-javadoc.jar
    rm -rf aws-java-sdk-*/lib/aws-java-sdk-*-sources.jar
  EOF
  not_if 'test -e /tmp/aws-java-sdk-*/lib/aws-java-sdk-*.jar'
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

execute 'install aws java sdk jar' do
  cwd '/tmp'
  command <<-EOF
    cp -f aws-java-sdk-*/lib/aws-java-sdk-*.jar \
        /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/
  EOF
  not_if "test -e /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/aws-java-sdk-*.jar"
end

if spark_redshift_version.split('-', 2).last == '6.4.3-spark_3.5'
  aws_sdk_v2_jars.each do |jar|
    execute "install aws java sdk v2 #{jar} jar" do
      cwd '/tmp/aws_java_sdk_v2'
      command <<-EOF
        cp -f #{jar}-#{aws_sdk_v2_version}.jar \
            /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/
      EOF
      not_if "test -e /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/#{jar}-#{aws_sdk_v2_version}.jar"
    end
  end

  execute "install reactive_streams jar" do
    cwd '/tmp/aws_java_sdk_v2'
    command <<-EOF
      cp -f reactive-streams-#{reactive_streams_version}.jar \
          /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/
    EOF
    not_if "test -e /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/reactive-streams-#{reactive_streams_version}.jar"
  end
end

execute 'install hadoop aws jar' do
  cwd '/opt/hadoop/current'
  command <<-EOF
    cp -f share/hadoop/tools/lib/hadoop-aws-#{hadoop_version}.jar \
        /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/
  EOF
  not_if "test -e /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/hadoop-aws-*.jar"
end

if spark_redshift_version.split('-', 2).last == '6.4.3-spark_3.5'
  source = '/opt/hadoop/current/share/hadoop/client'
  destination = "/opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars"
  jar_name = "hadoop-client-api-#{hadoop_version}.jar"
  
  execute "remove old hadoop client api jars" do
    cwd "/opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars"
    command <<-EOF
      for file in hadoop-client-api-*.jar; do
        if [[ -e $file ]]; then
          file_version=${file#hadoop-client-api-}
          file_version=${file_version%.jar}
          if [[ "$(printf '%s\n%s' "#{hadoop_version}" "${file_version}" | sort -V | head -n1)" != "#{hadoop_version}" ]]; then
            rm -f $file
          fi
        fi
      done
    EOF
    only_if "ls /opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}/jars/hadoop-client-api-*.jar"
  end
  
  execute "install hadoop client api jar" do
    cwd source
    command <<-EOF
      cp -f #{jar_name} #{destination}
    EOF
    not_if "test -e #{destination}/#{jar_name}"
  end
end

execute 'install spark-redshift jars' do
  cwd "/opt/spark/spark-#{version}-bin-hadoop#{hadoop_type}"
  command <<-EOF
    ls -d $(find jars) | grep 'spark-redshift_[0-9.-]*.jar' | xargs rm -f
    cp -f /tmp/spark-redshift_#{spark_redshift_version}.jar jars/
    
    ls -d $(find jars) | grep 'spark-avro_[0-9.-]*.jar' | xargs rm -f
    cp -f /tmp/spark-avro_#{spark_avro_version}.jar jars/
    
    ls -d $(find jars) | grep 'RedshiftJDBC42-[0-9.]*.jar' | xargs rm -f
    cp -f /tmp/RedshiftJDBC42-#{redshift_jdbc_version}.jar jars/
    
    #{if spark_redshift_version.split('-', 2).last == '5.0.3'
        <<-EOS
          ls -d $(find jars) | grep 'minimal-json-[0-9.]*.jar' | xargs rm -f
          cp -f /tmp/minimal-json-#{minimal_json_version}.jar jars/
      
          ls -d $(find jars) | grep 'fastdoubleparser-[0-9.]*.jar' | xargs rm -f
          cp -f /tmp/fastdoubleparser-#{fastdoubleparser_version}.jar jars/
      
          ls -d $(find jars) | grep 'jets3t-[0-9.]*.jar' | xargs rm -f
          cp -f /tmp/jets3t-#{jets3t_version}.jar jars/
        EOS
      elsif spark_redshift_version.split('-', 2).last == '6.2.0-spark_3.4'
        <<-EOS
          ls -d $(find jars) | grep 'aws-secretsmanager-jdbc-[0-9.]*.jar' | xargs rm -f
          cp -f /tmp/aws-secretsmanager-jdbc-#{aws_secretsmanager_jdbc_version}.jar jars/
        EOS
      elsif spark_redshift_version.split('-', 2).last == '6.4.3-spark_3.5'
        <<-EOS
          ls -d $(find jars) | grep 'aws-secretsmanager-caching-java-[0-9.]*.jar' | xargs rm -f
          cp -f /tmp/aws-secretsmanager-caching-java-#{aws_secretsmanager_caching_java_version}.jar jars/

          ls -d $(find jars) | grep 'aws-secretsmanager-jdbc-[0-9.]*.jar' | xargs rm -f
          cp -f /tmp/aws-secretsmanager-jdbc-#{aws_secretsmanager_jdbc_version}.jar jars/
        EOS
      end}
  EOF
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
