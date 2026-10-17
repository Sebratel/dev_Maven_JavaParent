#!/usr/bin/env bash
# Cria um projeto consumidor descartavel e confirma que o sebratel-java-parent barra codigo fora da regra
# e aprova codigo correto. Roda depois de "./mvnw install" (usa a versao instalada no ~/.m2).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$("$ROOT/mvnw" -q -f "$ROOT/sebratel-java-parent/pom.xml" help:evaluate -Dexpression=project.version -DforceStdout)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/src/main/java/br/com/sebratel/demo" "$WORK/src/test/java/br/com/sebratel/demo"
cp -r "$ROOT/.mvn" "$ROOT/mvnw" "$WORK/"

cat > "$WORK/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0"><modelVersion>4.0.0</modelVersion>
<parent><groupId>br.com.sebratel</groupId><artifactId>sebratel-java-parent</artifactId><version>${VERSION}</version><relativePath/></parent>
<artifactId>demo</artifactId><version>0.0.1</version>
<dependencies>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter</artifactId></dependency>
<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
</dependencies></project>
EOF
cat > "$WORK/src/test/java/br/com/sebratel/demo/DemoTest.java" <<EOF
package br.com.sebratel.demo;
import org.junit.jupiter.api.Test;
class DemoTest { @Test void t() { new Demo().one(); } }
EOF

# 1) Violacao (import com * e duas classes no arquivo) tem que quebrar o build.
cat > "$WORK/src/main/java/br/com/sebratel/demo/Demo.java" <<EOF
package br.com.sebratel.demo;
import java.util.*;
public class Demo { public int one() { return 1; } }
class Second {}
EOF
if (cd "$WORK" && ./mvnw -B -q verify >/dev/null 2>&1); then
  echo "FALHA: codigo fora da regra passou no build"; exit 1
fi
echo "OK: violacao barrada"

# 2) Codigo correto tem que passar.
cat > "$WORK/src/main/java/br/com/sebratel/demo/Demo.java" <<EOF
package br.com.sebratel.demo;
public class Demo { public int one() { return 1; } }
EOF
(cd "$WORK" && ./mvnw -B -q verify)
echo "OK: codigo correto aprovado"
