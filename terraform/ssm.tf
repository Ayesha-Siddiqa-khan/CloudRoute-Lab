resource "aws_ssm_parameter" "github_actions_kubeconfig_public_b64" {
  name        = local.terrapilot_ssm_kubeconfig_public_b64_path
  description = "Current public Kubernetes kubeconfig base64 for GitHub Actions. EC2 bootstrap overwrites this placeholder after kubeadm is ready."
  type        = "SecureString"
  tier        = "Advanced"
  value       = base64encode("placeholder: control plane has not published kubeconfig yet\n")

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name                   = "${local.resource_prefix}-github-actions-kubeconfig"
    Project                = var.project_name
    TerraPilotProject      = var.project_name
    TerraPilotResourceType = "ssm-parameter"
    Environment            = var.environment
    ManagedBy              = "TerraPilot"
    CostSensitive          = "true"
  }
}
