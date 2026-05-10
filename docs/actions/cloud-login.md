# Cloud Login Action

**Path:** `actions/cloud-login/action.yml`

Unified authentication for AWS, Azure, and GCP. Uses OIDC (recommended — no
long-lived credentials) and optionally logs into the cloud's container registry.

## Usage

=== "AWS (OIDC)"

    ```yaml
    - uses: code-haven/code-haven/actions/cloud-login@main
      with:
        provider: aws
        aws_role_arn: ${{ secrets.AWS_ROLE_ARN }}
        aws_region: eu-west-1
    ```

=== "Azure (OIDC)"

    ```yaml
    - uses: code-haven/code-haven/actions/cloud-login@main
      with:
        provider: azure
        azure_client_id: ${{ secrets.AZURE_CLIENT_ID }}
        azure_tenant_id: ${{ secrets.AZURE_TENANT_ID }}
        azure_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    ```

=== "GCP (Workload Identity)"

    ```yaml
    - uses: code-haven/code-haven/actions/cloud-login@main
      with:
        provider: gcp
        gcp_workload_identity_provider: ${{ secrets.GCP_WIF_PROVIDER }}
        gcp_service_account: ${{ secrets.GCP_SA_EMAIL }}
    ```

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `provider` | Yes | Cloud provider: `aws`, `azure`, or `gcp` |
| `aws_role_arn` | AWS | IAM role ARN for OIDC federation |
| `aws_region` | AWS | AWS region (default: `us-east-1`) |
| `aws_ecr_login` | No | Also authenticate to ECR for Docker push |
| `azure_client_id` | Azure | Service principal / managed identity client ID |
| `azure_tenant_id` | Azure | Azure AD tenant ID |
| `azure_subscription_id` | Azure | Azure subscription ID |
| `azure_acr_name` | No | Azure Container Registry name for Docker login |
| `gcp_workload_identity_provider` | GCP | Full resource name of the WIF provider |
| `gcp_service_account` | GCP | GCP service account email used via impersonation |

## Setting up OIDC

OIDC (OpenID Connect) lets GitHub Actions authenticate to cloud providers without
storing long-lived credentials. Each provider has a one-time setup:

=== "AWS"

    1. Create an OIDC identity provider in IAM:
       - Provider URL: `https://token.actions.githubusercontent.com`
       - Audience: `sts.amazonaws.com`
    2. Create an IAM role with a trust policy that restricts to your repo
    3. Store the role ARN as `AWS_ROLE_ARN` secret

=== "Azure"

    1. Register an app in Azure AD
    2. Add a federated credential for your GitHub repo
    3. Assign the app the required roles (e.g., `Contributor`)
    4. Store `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` as secrets

=== "GCP"

    1. Create a Workload Identity Pool + Provider in your GCP project
    2. Grant the provider access to a GCP service account
    3. Store the provider resource name as `GCP_WIF_PROVIDER`
    4. Store the service account email as `GCP_SA_EMAIL`

## Container registry login

To push Docker images to a cloud registry, add the registry login flag:

```yaml
# AWS ECR
- uses: code-haven/code-haven/actions/cloud-login@main
  with:
    provider: aws
    aws_role_arn: ${{ secrets.AWS_ROLE_ARN }}
    aws_region: us-east-1
    aws_ecr_login: 'true'

# Azure ACR
- uses: code-haven/code-haven/actions/cloud-login@main
  with:
    provider: azure
    azure_client_id: ${{ secrets.AZURE_CLIENT_ID }}
    azure_tenant_id: ${{ secrets.AZURE_TENANT_ID }}
    azure_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    azure_acr_name: 'myregistry'
```

For GCP Artifact Registry, authentication is handled automatically after
`gcloud auth` completes — no additional flag needed.
