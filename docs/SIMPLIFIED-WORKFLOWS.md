# Simplified GitHub Actions Workflows

## Overview

The previous complex centralized workflow system has been replaced with simple, standard GitHub Actions workflows following proven patterns from the community.

## Approach

Based on [Andrew Craven's NuGet workflow article](https://medium.com/@acraven_dev/a-nuget-package-workflow-using-github-actions-7da8c6557863), we've implemented:

### 1. Simple CI Workflow (`ci.yml`)

**Triggers:**
- Push to `main` and `development` branches
- Pull requests to `main` and `development` branches

**Actions:**
- Checkout code
- Setup .NET
- Restore dependencies
- Build (Release configuration)
- Run tests

### 2. Release Workflow (`release.yml`)

**Triggers:**
- Tags matching `v[0-9]+.[0-9]+.[0-9]+` pattern (e.g., `v1.0.0`)

**Actions:**
- Verify commit exists in main branch
- Extract version from tag
- Build and test with version
- Pack NuGet packages
- Publish to GitHub Packages using `GITHUB_TOKEN`

### 3. Pre-release Workflow (`prerelease.yml`)

**Triggers:**
- Push to `development` branch
- Tags matching `v[0-9]+.[0-9]+.[0-9]+-preview[0-9][0-9][0-9]` pattern

**Actions:**
- Build and pack (no tests for speed)
- Automatic versioning: `0.3.0-preview.{build_number}`
- Authenticate to GitHub Packages using GITHUB_TOKEN
- Publish pre-release packages with `--skip-duplicate`

## Key Benefits

1. **Simplicity**: Standard GitHub Actions patterns, no complex reusable workflows
2. **Reliability**: Uses built-in `GITHUB_TOKEN`, no secret collision issues
3. **Speed**: Workflows run directly without cross-repository dependencies
4. **Maintainability**: Easy to understand and modify
5. **Performance**: No overhead from centralized workflow calls

## Project Structure

Each project now has its own workflows:

```
project/
├── .github/
│   └── workflows/
│       ├── ci.yml           # Build and test on push/PR
│       ├── release.yml      # Tag-based releases
│       └── prerelease.yml   # Development builds
└── src/
    └── Project/Project.csproj  # With NuGet metadata
```

## Usage

### Development Workflow
1. Push to `development` branch → Triggers CI and pre-release build
2. Create PR to `main` → Triggers CI tests
3. Merge PR → Triggers CI build

### Release Workflow
1. Tag commit with `v1.0.0` → Triggers release build and publish
2. Package published to GitHub Packages automatically

### Pre-release Workflow
1. Push to `development` → Creates `0.3.0-preview.{build_number}` package
2. Tag with `v1.0.0-preview001` → Creates tagged pre-release

### Authentication
- Uses proper GitHub Packages authentication as documented
- Adds package source with GITHUB_TOKEN credentials
- Uses `--skip-duplicate` to avoid conflicts

## Migration Complete

- ✅ Dotnet project: Simple workflows implemented
- ✅ Yaul project: Simple workflows implemented  
- ✅ Package metadata: Configured for GitHub Packages
- ✅ Authentication: Using built-in GITHUB_TOKEN
- ✅ No secret collisions or cross-org issues

## Next Steps

1. Test workflows by pushing to development branches
2. Create release tags when ready to publish
3. Monitor package publishing in GitHub Packages
4. Remove old centralized workflow infrastructure when confirmed working

The new approach eliminates complexity while maintaining all required functionality for automated NuGet package publishing.