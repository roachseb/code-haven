# Java (Maven / Gradle)

**Workflow:** [`_build-java.yml`](https://github.com/code-haven/code-haven/blob/main/.github/workflows/_build-java.yml)  
**Triggered by:** `pom.xml` or `build.gradle` / `build.gradle.kts`

## Jobs

### Maven Build
Runs `mvn install` (configurable) with artifact upload for JARs, WARs, test reports, and site output.

### Java Format Check
Validates code formatting using either **revelc** or **spotify** formatter plugins. Soft-fail (`continue-on-error: true`).

### Javadoc (Maven)
Generates Javadoc after a successful Maven build. Published to GitHub Pages.

### Gradle Build
Runs `gradle build` (configurable) with artifact upload for build outputs and test results.

### Gradle Javadoc
Generates Javadoc via Gradle. Published to GitHub Pages.

## Configuration

```yaml
with:
  java_version: '21'           # JDK version
  java_distribution: 'temurin' # temurin, corretto, zulu, etc.
  maven_cli_opts: '--batch-mode --errors --fail-at-end --show-version'
  maven_build_cmd: 'verify'    # Maven goal
  java_formatter: 'spotify'    # revelc, spotify, or disabled
  gradle_build_cmd: 'build'    # Gradle task
```

## Artifacts Produced

| Name | Contents | Retention |
|------|----------|-----------|
| `maven-target` | JARs, WARs, test reports, site | 1 day |
| `javadoc` | Javadoc HTML | 7 days |
| `gradle-build` | Build libs, reports, test results | 1 day |
| `gradle-javadoc` | Javadoc HTML | 7 days |
