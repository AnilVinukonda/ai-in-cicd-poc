# AI in CI/CD Starter\n\nSee workflows in .github/workflows and scripts/ for details.
## CD to AWS EKS (GitHub Actions)

**Set repo Variables (Settings → Variables → Actions):**
- `AWS_REGION` (e.g. `us-east-1`)
- `AWS_ACCOUNT_ID` (e.g. `123456789012`)
- `EKS_CLUSTER_NAME` (your EKS cluster name)
- `ECR_REPO` (existing ECR repo name, e.g. `ai-in-cicd-demo`)

**Set repo Secrets:**
- `AWS_ROLE_TO_ASSUME` (ARN of IAM role with OIDC trust + ECR/EKS policy)

**Create GitHub OIDC IAM Role (one-time):**
1. Create OIDC provider for `token.actions.githubusercontent.com` (most accounts have this via console).
2. Create an IAM role with trust policy from `iam/role-trust.json`. Replace `AWS_ACCOUNT_ID`, `YOUR_ORG/YOUR_REPO`.3. Attach policy from `iam/policy-ecr-eks.json` (or a stricter one).4. (Kubernetes RBAC) Map the role to cluster RBAC if needed (aws-auth ConfigMap) so it can apply manifests.

**Deploy:**
- Push to `main` or trigger the workflow **CD to AWS EKS**. Image is built & pushed to ECR, then manifests are applied to the `demo` namespace.
