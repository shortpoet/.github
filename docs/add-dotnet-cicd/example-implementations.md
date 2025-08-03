# Example Implementations for .NET CI/CD

## Example 1: Yaul SDK Package Publishing

### In `shortpoet-dots/yaul` repository

Create `.github/workflows/publish.yml`:
```yaml
name: Publish Yaul Packages

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to publish'
        required: true
        type: string

jobs:
  publish:
    uses: shortpoet/.github/.github/workflows/dotnet-ci.yml@main
    with:
      project-path: './src/Yaul/Yaul.sln'
      dotnet-version: '9.0.x'
      configuration: 'Release'
      publish-packages: true
      package-source: 'github'
      run-tests: true
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Example 2: CLI Tool Publishing

### In `shortpoet-dots/dotnet` repository

Create `.github/workflows/cli-publish.yml`:
```yaml
name: Publish CLI Tool

on:
  release:
    types: [published]

jobs:
  publish-cli:
    uses: shortpoet/.github/.github/workflows/dotnet-ci.yml@main
    with:
      project-path: './src/Shortpoet.Dots/Shortpoet.Dots.CLI/Shortpoet.Dots.CLI.csproj'
      dotnet-version: '9.0.x'
      configuration: 'Release'
      publish-packages: true
      package-source: 'github'
      run-tests: true
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  publish-to-nuget:
    needs: publish-cli
    if: github.event.release.prerelease == false
    uses: shortpoet/.github/.github/workflows/dotnet-ci.yml@main
    with:
      project-path: './src/Shortpoet.Dots/Shortpoet.Dots.CLI/Shortpoet.Dots.CLI.csproj'
      dotnet-version: '9.0.x'
      configuration: 'Release'
      publish-packages: true
      package-source: 'nuget'
      run-tests: false  # Already tested
    secrets:
      NUGET_API_KEY: ${{ secrets.NUGET_API_KEY }}
```

## Example 3: PR Validation Workflow

### For any .NET repository

Create `.github/workflows/pr-validation.yml`:
```yaml
name: PR Validation

on:
  pull_request:
    branches: [main, develop]
    paths:
      - '**.cs'
      - '**.csproj'
      - '**.sln'

jobs:
  validate:
    uses: shortpoet/.github/.github/workflows/dotnet-matrix.yml@main
    with:
      projects: '["./src/Yaul/Yaul.sln"]'
      dotnet-versions: '["8.0.x", "9.0.x"]'
      os-matrix: '["ubuntu-latest", "windows-latest"]'

  code-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: shortpoet/.github/.github/actions/dotnet-setup@main
        with:
          dotnet-version: '9.0.x'
      
      - name: Run Code Analysis
        run: |
          dotnet tool restore
          dotnet format --verify-no-changes
          dotnet build -warnaserror
```

## Example 4: Nightly Build

### Scheduled workflow for integration testing

Create `.github/workflows/nightly.yml`:
```yaml
name: Nightly Build

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
  workflow_dispatch:

jobs:
  nightly-matrix:
    strategy:
      matrix:
        project:
          - path: './yaul/src/Yaul/Yaul.sln'
            name: 'Yaul SDK'
          - path: './dotnet/src/Shortpoet.Dots/Shortpoet.Dots.sln'
            name: 'CLI Tools'
        dotnet: ['8.0.x', '9.0.x', '10.0.x-preview']
        os: ['ubuntu-latest', 'windows-latest', 'macos-latest']
    
    uses: shortpoet/.github/.github/workflows/dotnet-ci.yml@main
    with:
      project-path: ${{ matrix.project.path }}
      dotnet-version: ${{ matrix.dotnet }}
      configuration: 'Debug'
      run-tests: true
      publish-packages: false
    
    name: ${{ matrix.project.name }} - .NET ${{ matrix.dotnet }} - ${{ matrix.os }}
```

## Example 5: Deploy CLI Tool as GitHub Release

Create `.github/workflows/release-cli.yml`:
```yaml
name: Release CLI Tool

on:
  push:
    tags:
      - 'cli-v*'

jobs:
  build-and-release:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: shortpoet/.github/.github/actions/dotnet-setup@main
        with:
          dotnet-version: '9.0.x'
      
      - uses: shortpoet/.github/.github/actions/dotnet-build@main
        with:
          project-path: './src/Shortpoet.Dots/Shortpoet.Dots.CLI/Shortpoet.Dots.CLI.csproj'
          configuration: 'Release'
          create-package: true
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: ./artifacts/*.nupkg
          body: |
            ## Installation
            ```bash
            dotnet tool install -g zly --version ${{ github.ref_name }}
            ```
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Example 6: Multi-Package Repository

### For repositories with multiple packages

Create `.github/workflows/multi-package.yml`:
```yaml
name: Build Multiple Packages

on:
  push:
    branches: [main]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      packages: ${{ steps.detect.outputs.packages }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Detect Changed Packages
        id: detect
        run: |
          PACKAGES=()
          
          # Check each package directory
          for dir in src/*/; do
            if git diff --name-only HEAD~1 HEAD | grep -q "^$dir"; then
              PACKAGES+=("$dir*.csproj")
            fi
          done
          
          echo "packages=$(printf '%s\n' "${PACKAGES[@]}" | jq -R . | jq -s .)" >> $GITHUB_OUTPUT
  
  build-changed:
    needs: detect-changes
    if: needs.detect-changes.outputs.packages != '[]'
    strategy:
      matrix:
        package: ${{ fromJson(needs.detect-changes.outputs.packages) }}
    
    uses: shortpoet/.github/.github/workflows/dotnet-ci.yml@main
    with:
      project-path: ${{ matrix.package }}
      publish-packages: true
      package-source: 'github'
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Local Testing Commands

### Test workflows locally with act

```bash
# Install act
scoop install act  # Windows
brew install act   # macOS

# Test workflow
act -W .github/workflows/dotnet-ci.yml \
    --secret GITHUB_TOKEN=$GITHUB_TOKEN \
    -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Test with matrix
act -W .github/workflows/dotnet-matrix.yml \
    --matrix project:./src/Yaul/Yaul.sln \
    --matrix dotnet:9.0.x
```

### Debug workflow issues

```yaml
# Add debug step to any workflow
- name: Debug Context
  uses: shortpoet/.github/.github/actions/dump-context@main
  
- name: Debug Environment
  run: |
    echo "Runner: ${{ runner.os }}"
    echo "Ref: ${{ github.ref }}"
    echo "SHA: ${{ github.sha }}"
    dotnet --list-sdks
    dotnet --list-runtimes
```