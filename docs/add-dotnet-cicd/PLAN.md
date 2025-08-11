# Implementation Plan: Add .NET CI/CD to Central .github Repository

> **📁 Repository Context**: Central .github repository for CI/CD templates  
> **🎯 Objective**: Add .NET package building and publishing while preserving existing JS deployment features  
> **✅ Prerequisites**: GitHub Packages token, cross-org workflow considerations

## 🔄 **Comprehensive Implementation Plan: .NET CI/CD Integration**

### **Current State Analysis**

**Repository Structure:**

- **Location**: Personal GitHub account (`C:/Users/CarlosSoriano/shortpoet/source/repos/.github`)
- **Existing Features**: JavaScript deployment workflows, Terraform infrastructure
- **Target Projects**:
  - Yaul SDK packages (shortpoet-dots org)
  - Shortpoet.Dots CLI packages (shortpoet-dots org)

**Cross-Organization Challenges:**

1. **Workflow Reuse**: GitHub Actions workflows in `.github` repo won't automatically apply to `shortpoet-dots` org
2. **Secrets Management**: Different secret contexts between personal and org repos
3. **Package Publishing**: Need to handle GitHub Packages authentication across organizations

### **🎯 Implementation Strategy**

#### **Phase 1: Reusable Workflow Architecture**

**Current Structure (Limited):**

```yaml
# Only works within same account/org
name: "Deploy"
on:
  workflow_call:
    inputs:
      # JS-specific inputs
```

**Target Structure (Enhanced):**

```yaml
# Works across organizations via workflow_call
name: "Build and Publish .NET"
on:
  workflow_call:
    inputs:
      project_path:
        description: 'Path to .NET project or solution'
        required: true
        type: string
      package_source:
        description: 'Package source (github/nuget/azure)'
        required: false
        type: string
        default: 'github'
      dotnet_version:
        description: '.NET SDK version'
        required: false
        type: string
        default: '9.0.x'
    secrets:
      GITHUB_TOKEN:
        required: true
      NUGET_API_KEY:
        required: false
```

#### **Phase 2: Composite Actions for Reusability**

**Create Reusable Actions:**

```
.github/
├── actions/
│   ├── dotnet-setup/
│   │   └── action.yml
│   ├── dotnet-build/
│   │   └── action.yml
│   ├── dotnet-test/
│   │   └── action.yml
│   └── dotnet-publish/
│       └── action.yml
```

### **📋 Detailed Implementation Plan**

#### **Step 1: Create .NET Setup Action**

Create `.github/actions/dotnet-setup/action.yml`:

```yaml
name: 'Setup .NET'
description: 'Setup .NET SDK with caching'
inputs:
  dotnet-version:
    description: '.NET SDK version'
    required: false
    default: '9.0.x'
  include-prerelease:
    description: 'Include prerelease versions'
    required: false
    default: 'false'

runs:
  using: 'composite'
  steps:
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ inputs.dotnet-version }}
        include-prerelease: ${{ inputs.include-prerelease }}
    
    - name: Cache NuGet packages
      uses: actions/cache@v4
      with:
        path: ~/.nuget/packages
        key: ${{ runner.os }}-nuget-${{ hashFiles('**/packages.lock.json', '**/*.csproj') }}
        restore-keys: |
          ${{ runner.os }}-nuget-
```

#### **Step 2: Create .NET Build Action**

Create `.github/actions/dotnet-build/action.yml`:

```yaml
name: 'Build .NET Project'
description: 'Build .NET project with optional package creation'
inputs:
  project-path:
    description: 'Path to project or solution'
    required: true
  configuration:
    description: 'Build configuration'
    required: false
    default: 'Release'
  create-package:
    description: 'Create NuGet package'
    required: false
    default: 'false'
  version-suffix:
    description: 'Version suffix for packages'
    required: false

runs:
  using: 'composite'
  steps:
    - name: Restore dependencies
      shell: bash
      run: dotnet restore ${{ inputs.project-path }}
    
    - name: Build
      shell: bash
      run: |
        BUILD_ARGS="--configuration ${{ inputs.configuration }} --no-restore"
        if [[ "${{ inputs.version-suffix }}" != "" ]]; then
          BUILD_ARGS="$BUILD_ARGS --version-suffix ${{ inputs.version-suffix }}"
        fi
        dotnet build ${{ inputs.project-path }} $BUILD_ARGS
    
    - name: Create package
      if: inputs.create-package == 'true'
      shell: bash
      run: |
        PACK_ARGS="--configuration ${{ inputs.configuration }} --no-build --output ./artifacts"
        if [[ "${{ inputs.version-suffix }}" != "" ]]; then
          PACK_ARGS="$PACK_ARGS --version-suffix ${{ inputs.version-suffix }}"
        fi
        dotnet pack ${{ inputs.project-path }} $PACK_ARGS
```

#### **Step 3: Create .NET Test Action**

Create `.github/actions/dotnet-test/action.yml`:

```yaml
name: 'Test .NET Project'
description: 'Run .NET tests with optional coverage'
inputs:
  project-path:
    description: 'Path to test project or solution'
    required: true
  configuration:
    description: 'Build configuration'
    required: false
    default: 'Debug'
  collect-coverage:
    description: 'Collect code coverage'
    required: false
    default: 'true'
  coverage-format:
    description: 'Coverage output format'
    required: false
    default: 'cobertura'

runs:
  using: 'composite'
  steps:
    - name: Run tests
      shell: bash
      run: |
        TEST_ARGS="--configuration ${{ inputs.configuration }} --no-build --verbosity normal"
        if [[ "${{ inputs.collect-coverage }}" == "true" ]]; then
          TEST_ARGS="$TEST_ARGS --collect:\"XPlat Code Coverage\" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=${{ inputs.coverage-format }}"
        fi
        dotnet test ${{ inputs.project-path }} $TEST_ARGS
    
    - name: Upload coverage
      if: inputs.collect-coverage == 'true'
      uses: actions/upload-artifact@v4
      with:
        name: coverage-report
        path: '**/coverage.cobertura.xml'
```

#### **Step 4: Create .NET Publish Action**

Create `.github/actions/dotnet-publish/action.yml`:

```yaml
name: 'Publish .NET Package'
description: 'Publish .NET packages to various sources'
inputs:
  package-path:
    description: 'Path to package(s)'
    required: false
    default: './artifacts/*.nupkg'
  source:
    description: 'Package source (github/nuget/azure)'
    required: true
  github-token:
    description: 'GitHub token for packages'
    required: false
  nuget-api-key:
    description: 'NuGet API key'
    required: false
  azure-feed-url:
    description: 'Azure DevOps feed URL'
    required: false

runs:
  using: 'composite'
  steps:
    - name: Publish to GitHub Packages
      if: inputs.source == 'github'
      shell: bash
      run: |
        dotnet nuget add source --username USERNAME --password ${{ inputs.github-token }} \
          --store-password-in-clear-text --name github \
          "https://nuget.pkg.github.com/${{ github.repository_owner }}/index.json"
        
        for package in ${{ inputs.package-path }}; do
          dotnet nuget push "$package" --api-key ${{ inputs.github-token }} --source github --skip-duplicate
        done
    
    - name: Publish to NuGet.org
      if: inputs.source == 'nuget'
      shell: bash
      run: |
        for package in ${{ inputs.package-path }}; do
          dotnet nuget push "$package" --api-key ${{ inputs.nuget-api-key }} \
            --source https://api.nuget.org/v3/index.json --skip-duplicate
        done
    
    - name: Publish to Azure DevOps
      if: inputs.source == 'azure'
      shell: bash
      run: |
        for package in ${{ inputs.package-path }}; do
          dotnet nuget push "$package" --api-key AzureDevOps \
            --source ${{ inputs.azure-feed-url }} --skip-duplicate
        done
```

#### **Step 5: Create Reusable Workflow for .NET**

Create `.github/workflows/dotnet-ci.yml`:

```yaml
name: '.NET CI/CD'

on:
  workflow_call:
    inputs:
      project-path:
        description: 'Path to .NET project or solution'
        required: true
        type: string
      dotnet-version:
        description: '.NET SDK version'
        required: false
        type: string
        default: '9.0.x'
      configuration:
        description: 'Build configuration'
        required: false
        type: string
        default: 'Release'
      publish-packages:
        description: 'Publish packages'
        required: false
        type: boolean
        default: false
      package-source:
        description: 'Package source (github/nuget/azure)'
        required: false
        type: string
        default: 'github'
      run-tests:
        description: 'Run tests'
        required: false
        type: boolean
        default: true
    secrets:
      GITHUB_TOKEN:
        required: false
      NUGET_API_KEY:
        required: false
      AZURE_DEVOPS_PAT:
        required: false

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET
        uses: ./.github/actions/dotnet-setup
        with:
          dotnet-version: ${{ inputs.dotnet-version }}
      
      - name: Build
        uses: ./.github/actions/dotnet-build
        with:
          project-path: ${{ inputs.project-path }}
          configuration: ${{ inputs.configuration }}
          create-package: ${{ inputs.publish-packages }}
      
      - name: Test
        if: inputs.run-tests
        uses: ./.github/actions/dotnet-test
        with:
          project-path: ${{ inputs.project-path }}
          configuration: ${{ inputs.configuration }}
      
      - name: Publish Packages
        if: inputs.publish-packages
        uses: ./.github/actions/dotnet-publish
        with:
          source: ${{ inputs.package-source }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
          nuget-api-key: ${{ secrets.NUGET_API_KEY }}
```

#### **Step 6: Create Matrix Build Workflow**

Create `.github/workflows/dotnet-matrix.yml`:

```yaml
name: '.NET Matrix Build'

on:
  workflow_call:
    inputs:
      projects:
        description: 'JSON array of project paths'
        required: true
        type: string
      dotnet-versions:
        description: 'JSON array of .NET versions'
        required: false
        type: string
        default: '["8.0.x", "9.0.x"]'
      os-matrix:
        description: 'JSON array of OS runners'
        required: false
        type: string
        default: '["ubuntu-latest", "windows-latest", "macos-latest"]'

jobs:
  build:
    strategy:
      matrix:
        project: ${{ fromJson(inputs.projects) }}
        dotnet: ${{ fromJson(inputs.dotnet-versions) }}
        os: ${{ fromJson(inputs.os-matrix) }}
    
    runs-on: ${{ matrix.os }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup .NET ${{ matrix.dotnet }}
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: ${{ matrix.dotnet }}
      
      - name: Build ${{ matrix.project }}
        run: |
          dotnet restore ${{ matrix.project }}
          dotnet build ${{ matrix.project }} --configuration Release --no-restore
      
      - name: Test ${{ matrix.project }}
        run: dotnet test ${{ matrix.project }} --configuration Release --no-build
```

### **🎯 Cross-Organization Usage**

#### **In shortpoet-dots Organization Repos**

Create `.github/workflows/ci.yml` in Yaul or CLI repos:

```yaml
name: CI/CD

on:
  push:
    branches: [main, develop]
    tags: ['v*']
  pull_request:
    branches: [main]

jobs:
  build-and-publish:
    uses: shortpoet/.github/.github/workflows/dotnet-ci.yml@main
    with:
      project-path: './src/Yaul/Yaul.sln'
      dotnet-version: '9.0.x'
      publish-packages: ${{ startsWith(github.ref, 'refs/tags/v') }}
      package-source: 'github'
    secrets:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### **🎯 Key Benefits of This Implementation**

1. **✅ Preservation**: Existing JS workflows remain untouched
2. **✅ Reusability**: Composite actions can be used across organizations
3. **✅ Flexibility**: Support for multiple package sources and .NET versions
4. **✅ Maintainability**: Central location for CI/CD logic updates

### **🚨 Critical Preservation Points**

1. **Existing Workflows**: All current JS deployment workflows remain functional
2. **Directory Structure**: New .NET actions in separate directories
3. **Secrets Management**: Each org manages its own secrets

### **📋 Implementation Checklist**

**Prerequisites**:

- [ ] Create GitHub PAT with `write:packages` scope
- [ ] Configure secrets in shortpoet-dots org repos
- [ ] Verify cross-org workflow permissions

**Main Implementation**:

- [ ] Create composite actions directory structure
- [ ] Implement dotnet-setup action
- [ ] Implement dotnet-build action
- [ ] Implement dotnet-test action
- [ ] Implement dotnet-publish action
- [ ] Create reusable workflow for .NET CI/CD
- [ ] Create matrix build workflow
- [ ] Test with Yaul packages
- [ ] Test with CLI packages
- [ ] Document usage in README

**Post-Implementation**:

- [ ] Update shortpoet-dots repos to use new workflows
- [ ] Configure branch protection rules
- [ ] Set up automated version tagging

### **📁 Best Practices for .github Repository**

**Structure Recommendations:**

```
.github/
├── .github/
│   ├── workflows/        # Reusable workflows
│   │   ├── dotnet-ci.yml
│   │   ├── dotnet-matrix.yml
│   │   └── deploy-*.yml  # Existing JS workflows
│   └── actions/          # Composite actions
│       ├── dotnet-*/     # .NET specific actions
│       └── aws-creds/    # Existing actions
├── workflow-templates/   # Starter workflows for repos
│   ├── dotnet-ci.yml
│   └── dotnet-ci.properties.json
├── scripts/             # Shared scripts
│   ├── dotnet/
│   └── js/
└── docs/
    ├── dotnet-setup.md
    └── js-deployment.md
```

**Workflow Templates for Organization Use:**

Create `workflow-templates/dotnet-ci.yml`:

```yaml
name: .NET CI/CD

on:
  push:
    branches: [ $default-branch ]
  pull_request:
    branches: [ $default-branch ]

jobs:
  build:
    uses: ${{ github.repository_owner }}/.github/.github/workflows/dotnet-ci.yml@main
    with:
      project-path: './src/${{ github.event.repository.name }}.sln'
      publish-packages: false
```

Create `workflow-templates/dotnet-ci.properties.json`:

```json
{
  "name": ".NET CI/CD Workflow",
  "description": "Build, test, and publish .NET packages",
  "iconName": "dotnet",
  "categories": ["C#", "F#", "VB", ".NET"],
  "filePatterns": ["*.csproj", "*.fsproj", "*.vbproj", "*.sln"]
}
```

This implementation provides a robust, reusable .NET CI/CD infrastructure while preserving your existing JavaScript deployment capabilities.
