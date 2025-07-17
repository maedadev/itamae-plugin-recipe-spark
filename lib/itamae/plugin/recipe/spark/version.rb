module Itamae
  module Plugin
    module Recipe
      module Spark
        VERSION = "0.1.12"

        SPARK_VERSION = [
          SPARK_VERSION_MAJOR = '3',
          SPARK_VERSION_MINOR = '5',
          SPARK_VERSION_REVISION = '5'
        ].join('.')

        SPARK_REDSHIFT_VERSION = '2.12-6.4.3-spark_3.5'
        SPARK_AVRO_VERSION = '2.12-3.5.5'
        MINIMAL_JSON_VERSION = '0.9.4'
        REDSHIFT_JDBC_VERSION = '2.1.0.29'
        FASTDOUBLEPARSER_VERSION = '0.8.0'
        JETS3T_VERSION = '0.9.4'
        AWS_SECRETSMANAGER_CACHING_JAVA_VERSION = '1.0.2'
        AWS_SECRETSMANAGER_JDBC_VERSION = '1.0.12'
      end
    end
  end
end
