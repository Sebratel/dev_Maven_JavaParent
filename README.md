# dev_Maven_JavaParent

> **Repositório público**, sucessor do `dev_Maven_Parent` (privado). Os artefatos mudaram de nome
> (`sebratel-parent` → `sebratel-java-parent`, `sebratel-build-rules` → `sebratel-java-build-rules`) porque o nome de um pacote
> do GitHub Packages é único na organização e não pode ser republicado por outro repositório. Ele é público para que o CI de
> qualquer repositório da organização leia o parent com o `GITHUB_TOKEN`, sem segredo extra.

Artefatos Maven que carregam as **regras básicas de todo projeto Java/Spring Boot da Sebratel**.
Um projeto novo herda do `sebratel-java-parent` e ganha as regras sem copiar configuração.

| Artefato | Tipo | Para quê |
|---|---|---|
| `br.com.sebratel:sebratel-java-parent` | `pom` | Parent dos projetos: versões, plugins e regras de build |
| `br.com.sebratel:sebratel-java-build-rules` | `jar` | Arquivos de regra (Checkstyle) usados pelo parent como dependência de plugin |
| `templates/` | arquivos | Regras de **repositório** que Maven não aplica: `.gitignore`, `.editorconfig`, `.env.example`, `CODEOWNERS`, PR template, workflow de CI |

## Como usar num projeto novo

```xml
<parent>
    <groupId>br.com.sebratel</groupId>
    <artifactId>sebratel-java-parent</artifactId>
    <version>1.0.0</version>
    <relativePath/>
</parent>
```

O artefato vem do GitHub Packages (`https://maven.pkg.github.com/Sebratel/dev_Maven_JavaParent`). Declare o
repositório no `pom.xml` do projeto e um `<server><id>github</id>` no `~/.m2/settings.xml` com um token com
`read:packages`:

```xml
<repositories>
    <repository>
        <id>github</id>
        <url>https://maven.pkg.github.com/Sebratel/dev_Maven_JavaParent</url>
    </repository>
</repositories>
<!-- Para o Maven achar o próprio parent, o mesmo bloco precisa existir em <pluginRepositories>. -->
```

Depois copie `templates/` para a raiz do projeto (mantendo os caminhos) e ajuste `CODEOWNERS` e `.env.example`.

## O que o parent impõe

| Regra | Onde | Como ajustar |
|---|---|---|
| Spring Boot **3.5.16** e **Java 21** | parent | Subir a versão aqui, não em cada projeto |
| Build falha com JDK < 21 ou Maven < 3.9 | `maven-enforcer` | — (use `./mvnw`) |
| Lombok como annotation processor explícito (funciona em JDK 21–24+) | `maven-compiler-plugin` | `lombok.version` |
| Versões de dependência com CVE (netty, postgresql, tomcat, log4j2, jackson, logback) fixadas | `<properties>` | Revisar a cada subida do Spring Boot |
| **Checkstyle** na fase `verify`: uma classe por arquivo, sem `import *`, import não usado, nomenclatura, `equals`/`hashCode`, sem `catch Throwable`, sem tab | `sebratel-java-build-rules` | `-Dcheckstyle.skip=true` só em último caso (código legado) |
| **JaCoCo**: relatório em `test` e cobertura mínima de linhas em `verify` (dto/model/entity/repository/`*Application` fora da conta) | parent | `<jacoco.minimum>` no projeto (padrão **0.50**) |
| `-Psecurity`: OWASP dependency-check, quebra com CVSS ≥ 7 | profile | `dependency.check.failOnCvss` |
| Springdoc e logstash-logback-encoder com versão gerenciada | `dependencyManagement` | — |

As regras de Checkstyle ficam em `sebratel-java-build-rules/src/main/resources/sebratel/checkstyle.xml`. É de propósito
uma lista curta: só entra o que vira bug ou quebra um padrão oficial do `claude-skills` (`padroes-backend`),
nunca preferência de formatação.

## Regras de repositório (templates e GitHub)

- `main` nunca recebe push direto: só PR, com **1 aprovação** e o check **`ci-ok`** verde.
  (Regra por convenção: a proteção de branch do GitHub não está ativa porque o plano da organização não a oferece em repositório privado; ativar assim que o plano permitir.)
- `templates/.github/workflows/ci.yml`: `./mvnw -B verify` em PR e push, permissões mínimas (`contents: read`), JDK Temurin 21, check agregado `ci-ok` para a proteção de branch.
- Commits no padrão Conventional Commits; branches `feature/`, `fix/`, `hotfix/`, `chore/`.
- `.env` nunca vai para o Git; só `.env.example` documentado.
- Todo projeto mantém `CHANGELOG.md` (Keep a Changelog).

## Desenvolvimento e publicação

```bash
./mvnw -B install              # builda e instala rules + parent no ~/.m2
./scripts/test-consumer.sh     # prova que um projeto com violação FALHA e um correto PASSA
```

- O CI deste repositório roda os dois comandos acima.
- **Publicar:** criar uma Release com a tag `vX.Y.Z`. O workflow `publish.yml` ajusta a versão pelos dois artefatos
  (incluindo `sebratel-java-build-rules.version`) e faz `deploy` no GitHub Packages.
- Versionamento semântico: **MAJOR** quando uma regra nova pode quebrar o build de projetos existentes
  (ex.: nova regra de Checkstyle, subir o mínimo de cobertura); **MINOR** para plugin/propriedade nova sem
  quebra; **PATCH** para atualização de dependência.

## Armadilha conhecida

Dentro do parent, a versão do `sebratel-java-build-rules` é a propriedade literal `sebratel-java-build-rules.version`.
**Não** troque por `${project.version}`: o Maven avalia essa expressão no projeto filho e a dependência do
plugin deixa de resolver.

## Pendências (próximas versões)

- `logback-spring.xml` padrão (JSON em UTC, `requestId`, `service`) e `RequestLoggingFilter` num starter `sebratel-observability`.
- Envelope de resposta/erro (`ApiResponse`, `ApiError`) compartilhado.
- Alinhar o `dev_SpringBoot_APIGateway` e os demais projetos Spring a este parent.
