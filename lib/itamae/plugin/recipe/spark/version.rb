module Itamae
  module Plugin
    module Recipe
      module Spark
        VERSION = "0.1.6"

        SPARK_VERSION = [
          SPARK_VERSION_MAJOR = '3',
          SPARK_VERSION_MINOR = '0',
          SPARK_VERSION_REVISION = '1'
        ].join('.')

        SPARK_REDSHIFT_VERSION = '2.12-5.0.3'
        SPARK_AVRO_VERSION = '2.12-3.0.1'
        MINIMAL_JSON_VERSION = '0.9.4'
        REDSHIFT_JDBC_VERSION = '1.2.37.1061'
        JETS3T_VERSION = '0.9.4'
      end
    end
  end
end
