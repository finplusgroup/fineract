# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#
FROM azul/zulu-openjdk-debian:11 AS builder

RUN apt-get update -qq && apt-get install -y wget

COPY . fineract
WORKDIR /fineract

RUN ./gradlew --no-daemon -q -x rat -x compileTestJava -x test -x spotlessJavaCheck -x spotlessJava bootJar

WORKDIR /fineract/target
RUN jar -xf /fineract/fineract-provider/build/libs/fineract-provider.jar

# We download separately a JDBC driver (which not allowed to be included in Apache binary distribution)
WORKDIR /fineract/target/BOOT-INF/libs
RUN wget -q https://downloads.mariadb.com/Connectors/java/connector-java-2.7.3/mariadb-java-client-2.7.3.jar
RUN wget -q https://jdbc.postgresql.org/download/postgresql-42.5.1.jar

# =========================================

FROM azul/zulu-openjdk-alpine:11 AS fineract

COPY --from=builder /fineract/target/BOOT-INF/lib /app/lib
COPY --from=builder /fineract/target/META-INF /app/META-INF
COPY --from=builder /fineract/target/BOOT-INF/classes /app

WORKDIR /

COPY entrypoint.sh /entrypoint.sh

RUN chmod 775 /entrypoint.sh

EXPOSE 8443

ENTRYPOINT ["/entrypoint.sh"]