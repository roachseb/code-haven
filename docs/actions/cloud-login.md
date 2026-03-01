# Cloud Login Action

**Path:** `actions/cloud-login/action.yml`

Unified authentication for AWS, Azure, and GCP. Supports OIDC (recommended)
and static credentials. Optionally logs into the cloud's container registry.

## Usage

=== "AWS"

    ```yaml
    - uses: code-haven/code-haven/actions/cloud-login@main
      with:
        provider: aws
        aws_role_arn: ${{ secrets.AWS_ROLE_ARN }}
        aws_region: eu-west-1
    ```

=== "Azure"

    ```yaml
    - uses: code-haven/code-haven/actions/cloud-login@main
      with:
        provider: azure
        azure_client_id: ${{ secrets.AZURE_CLIENT_ID }}
        azure_tenant_id: ${{ secrets.AZURE_TENANT_ID }}
        azure_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
    ```

=== "GCP"

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
| `provider` | Yes | `aws`, `azure`, or `gcp` |
| `aws_role_arn` | AWS | IAM role ARN for OIDC |
| `aws_region` | AWS | AWS region (default: `us-east-1`) |
| `aws_ecr_login` | No | Also login to ECR |
| `azure_client_id` | Azure | Service principal client ID |
| `azure_tenant_id` | Azure | Azure AD tenant ID |
| `azure_subscription_id` | Azure | Azure subscription ID |
| `azure_acr_name` | No | ACR name for Docker login |
| `gcp_workload_identity_provider` | GCP | Workload identity provider |
| `gcp_service_account` | GCP | Service account email |
