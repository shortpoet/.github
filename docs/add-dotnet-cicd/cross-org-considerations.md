# Cross-Organization Workflow Considerations

## GitHub Actions Limitations Across Organizations

### 1. Workflow Reuse Restrictions

**Personal Account → Organization:**
- Workflows in personal `.github` repo are NOT automatically available to organization repos
- Must use explicit `uses:` syntax with full path
- Requires public repository or appropriate permissions

**Solution:**
```yaml
# In shortpoet-dots org repo
uses: shortpoet/.github/.github/workflows/dotnet-ci.yml@main
# NOT: uses: ./.github/workflows/dotnet-ci.yml
```

### 2. Secrets Management

**Different Secret Contexts:**
- Personal repo secrets != Organization secrets
- Each context requires separate configuration

**Best Practice:**
```yaml
# Pass secrets explicitly
secrets:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  CUSTOM_PAT: ${{ secrets.CUSTOM_PAT }}
```

### 3. Package Publishing Authentication

**GitHub Packages Across Orgs:**
```yaml
# Personal account packages
https://nuget.pkg.github.com/shortpoet/index.json

# Organization packages
https://nuget.pkg.github.com/shortpoet-dots/index.json
```

**Authentication Strategy:**
1. Use PAT with `write:packages` scope
2. Configure as organization secret
3. Pass to reusable workflow

## Recommended Architecture

### Option 1: Duplicate Core Actions (Simple)
- Copy essential workflows to each org
- Maintain separately
- Best for: Small number of repos

### Option 2: Public Reusable Workflows (Recommended)
- Make `.github` repo public
- Use `workflow_call` events
- Reference from org repos
- Best for: Multiple repos, central maintenance

### Option 3: GitHub Apps (Advanced)
- Create GitHub App for CI/CD
- Install across organizations
- Use app authentication
- Best for: Enterprise scale

## Implementation Path

1. **Phase 1**: Implement in `.github` repo as public
2. **Phase 2**: Test with single shortpoet-dots repo
3. **Phase 3**: Roll out to all repos
4. **Phase 4**: Consider GitHub App if scaling needed

## Security Considerations

### Public Repository Implications
- No secrets in workflow files
- Use secret inputs for sensitive data
- Implement CODEOWNERS file
- Enable branch protection

### Access Control
```yaml
# Limit workflow triggers
on:
  workflow_call:
    # Only callable, not directly triggered
```

### Token Permissions
```yaml
permissions:
  contents: read
  packages: write
  # Minimal required permissions
```