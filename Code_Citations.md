# Code Citations

## License: Apache_2_0
https://github.com/jackstockley89/golangwebpage/tree/ba1386ba85bbd15e8a422a86c815d17a2d78eb9b/.github/workflows/terraform-plan.yml

```
}, Action: \`${{ github.event_name }}\`, Workflow: \`${{ github.workflow }}\`*`;
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.
```


## License: Apache_2_0
https://github.com/BitdefenderMDR/build-harness/tree/921151f3ee0e2b63b950d9c62537a32e4918c697/templates/terraform/.github/workflows/terraform.yml

```
github.actor }}, Action: \`${{ github.event_name }}\`, Workflow: \`${{ github.workflow }}\`*`;
      github.rest.issues.createComment({
        issue_number: context.issue.number,
```


## License: MPL_2_0
https://github.com/hashicorp/setup-terraform/tree/e192cfcbae6c6ed207c277ed7624131996c9bf13/README.md

```
\`${{ github.workflow }}\`*`;
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: output
      })
```

- name: Comment PR success
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v7
  with:
    script: |
      const output = `#### Terraform Validation ✅
      ...
      *Pusher: @${{ github.actor }}, Action: \`${{ github.event_name }}\`, Workflow: \`${{ github.workflow }}\`*`;
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: output
      })

