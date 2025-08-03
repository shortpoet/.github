# Migration Strategy: Adding .NET to Existing .github Repository

## Preservation Strategy

### Current JavaScript Workflows to Preserve

1. **deploy-dev_push-uat_merge-prod_release.yml**
   - Terraform deployment workflow
   - JavaScript build artifacts
   - AWS credentials handling

2. **tf-plan.yml & tf-apply.yml**
   - Infrastructure as Code workflows
   - Must remain untouched

3. **changed-files.yml**
   - File change detection
   - Can be enhanced for .NET file patterns

### Non-Breaking Addition Pattern

```yaml
# Existing workflow remains unchanged
name: "Deploy"
on:
  workflow_call:
    inputs:
      # Existing inputs preserved
      
# New .NET workflow in separate file
name: ".NET Build"
on:
  workflow_call:
    inputs:
      # .NET specific inputs
```

## Phased Migration Approach

### Phase 1: Add Without Modification (Week 1)
- Create new `/actions/dotnet-*/` directories
- Add new workflow files with `.NET` prefix
- No changes to existing files

### Phase 2: Test in Isolation (Week 2)
- Create test repository for validation
- Verify cross-org functionality
- Document any issues

### Phase 3: Integration (Week 3)
- Update shortpoet-dots repos one at a time
- Start with less critical packages
- Monitor for issues

### Phase 4: Enhancement (Week 4+)
- Add matrix builds
- Integrate with existing changed-files detection
- Consider unified dashboard

## File Organization Strategy

### Parallel Structure
```
.github/
├── actions/
│   ├── aws-creds/        # Existing - DO NOT MODIFY
│   ├── changed-files/    # Existing - DO NOT MODIFY
│   ├── dump-context/     # Existing - DO NOT MODIFY
│   ├── dotnet-setup/     # NEW
│   ├── dotnet-build/     # NEW
│   ├── dotnet-test/      # NEW
│   └── dotnet-publish/   # NEW
└── workflows/
    ├── deploy-*.yml      # Existing - DO NOT MODIFY
    ├── tf-*.yml          # Existing - DO NOT MODIFY
    ├── dotnet-ci.yml     # NEW
    └── dotnet-matrix.yml # NEW
```

## Testing Strategy

### 1. Local Testing
```bash
# Use act for local testing
act -W .github/workflows/dotnet-ci.yml
```

### 2. Fork Testing
- Fork .github repo
- Test workflows in fork
- Verify cross-org calls

### 3. Gradual Rollout
```yaml
# Start with optional workflow
on:
  workflow_dispatch:  # Manual trigger only
  workflow_call:      # Add automation later
```

## Rollback Plan

### Quick Rollback
1. Delete new `/actions/dotnet-*/` directories
2. Delete new `dotnet-*.yml` workflows
3. No impact on existing workflows

### Version Control
```bash
# Tag before changes
git tag pre-dotnet-integration

# Easy rollback
git revert --no-commit HEAD~5..HEAD
```

## Risk Mitigation

### Namespace Isolation
- Prefix all .NET items with `dotnet-`
- Use separate secrets namespace
- Distinct artifact paths

### Secret Management
```yaml
# Existing secrets unchanged
AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}

# New .NET secrets with prefix
DOTNET_GITHUB_TOKEN: ${{ secrets.DOTNET_GITHUB_TOKEN }}
DOTNET_NUGET_KEY: ${{ secrets.DOTNET_NUGET_KEY }}
```

### Monitoring
- Set up workflow status badges
- Create Slack notifications for failures
- Weekly review of workflow metrics

## Success Criteria

### Phase 1 Success
- [ ] No existing workflows modified
- [ ] All existing workflows still pass
- [ ] New .NET actions created

### Phase 2 Success
- [ ] Cross-org workflow calls work
- [ ] Package publishing successful
- [ ] No permission issues

### Phase 3 Success
- [ ] Yaul packages building
- [ ] CLI packages building
- [ ] Automated on push/PR

### Phase 4 Success
- [ ] Matrix builds operational
- [ ] Coverage reports integrated
- [ ] Performance acceptable