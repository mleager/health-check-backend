data "aws_caller_identity" "current" {}

locals {
  account_id        = data.aws_caller_identity.current.account_id
  oidc_provider_arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

# Terraform Apply on Main Brach
data "aws_iam_policy_document" "assume_github_oidc_apply" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:mleager/${var.name.project}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_oidc_role_apply" {
  name               = "oidc-${var.name.project}-${var.env}-apply"
  assume_role_policy = data.aws_iam_policy_document.assume_github_oidc_apply.json
  description        = "Allows Github Actions from ${var.name.project} to deploy frontend assets to S3 + CloudFront"
}

# Terraform Plan and Destroy on any Branch
data "aws_iam_policy_document" "assume_github_oidc_plan" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:mleager/${var.name.project}:*"]
    }
  }
}

resource "aws_iam_role" "github_oidc_role_plan" {
  name               = "oidc-${var.name.project}-${var.env}-plan"
  assume_role_policy = data.aws_iam_policy_document.assume_github_oidc_plan.json
  description        = "Allows Github Actions from ${var.name.project} to deploy frontend assets to S3 + CloudFront"
}

data "aws_iam_policy_document" "oidc_permissions" {
  statement {
    sid    = "AllowECRAccess"
    effect = "Allow"
    actions = [
      "ecr:*"
      # "ecr:GetAuthorizationToken",
      # "ecr:BatchCheckLayerAvailability",
      # "ecr:GetDownloadUrlForLayer",
      # "ecr:DescribeImages",
      # "ecr:DescribeRepositories"
    ]
    resources = ["arn:aws:ecr:${var.region}:${local.account_id}:repository/${var.name.ecr_repo}"]
  }

  statement {
    sid    = "AllowECSAccess"
    effect = "Allow"
    actions = [
      "ecs:*"
      # "ecs:DescribeServices",
      # "ecs:UpdateService",
      # "ecs:CreateCluster",
      # "ecs:RegisterTaskDefinition",
      # "ecs:DescribeTaskDefinition",
      # "ecs:ListClusters",
      # "ecs:ListServices",
      # "ecs:ListTaskDefinitions"
    ]
    resources = ["arn:aws:cloudfront::${local.account_id}:distribution/*"]
  }

  statement {
    sid    = "AllowALBAccess"
    effect = "Allow"
    actions = [
      "elasticloadbalancing:*"
      # "elasticloadbalancing:CreateLoadBalancer",
      # "elasticloadbalancing:CreateTargetGroup",
      # "elasticloadbalancing:ModifyTargetGroup",
      # "elasticloadbalancing:DeleteLoadBalancer",
      # "elasticloadbalancing:RegisterTargets",
      # "elasticloadbalancing:DescribeLoadBalancers",
      # "elasticloadbalancing:DescribeListeners",
      # "elasticloadbalancing:AddTags",
    ]
    resources = ["arn:aws:elasticloadbalancing:${var.region}:${local.account_id}:loadbalancer/*"]
  }

  statement {
    sid    = "AllowACMCertPermissions"
    effect = "Allow"
    actions = [
      "acm:*"
      # "acm:RequestCertificate",
      # "acm:DescribeCertificate",
      # "acm:GetCertificate",
      # "acm:ListCertificates"

      # "acm:RequestCertificate",
      # "acm:RevokeCertificate",
      # "acm:DeleteCertificate",
      # "acm:DescribeCertificate",
      # "acm:GetCertificate",
      # "acm:ListCertificates",
      # "acm:UpdateCertificate",
      # "acm:UpdateCertificateOptions",
      # "acm:DescribeCertificateOptions",
      # "acm:AddTagsToCertificate",
      # "acm:ListTagsForCertificate",
      # "acm:RemoveTagsFromCertificate"
    ]
    resources = ["arn:aws:acm:${var.region}:${local.account_id}:certificate/*"]
  }

  statement {
    sid    = "AllowRoute53Permissions"
    effect = "Allow"
    actions = [
      "route53:*"
      # "route53:GetHostedZone",
      # "route53:ListHostedZones",
      # "route53:ChangeResourceRecordSets",
      # "route53:ListResourceRecordSets",
      # "route53:ListHostedZonesByName",
      # "route53:ListResourceRecordSetsByHostedZone"
    ]
    resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.primary.zone_id}"]
  }
}

resource "aws_iam_policy" "github_oidc_role_policy" {
  name   = "github-oidc-permissions-policy-${var.name.project}"
  policy = data.aws_iam_policy_document.oidc_permissions.json
}

resource "aws_iam_role_policy_attachment" "attach_github_oidc_role_policy_apply" {
  role       = aws_iam_role.github_oidc_role_apply.id
  policy_arn = aws_iam_policy.github_oidc_role_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_github_oidc_role_policy_plan" {
  role       = aws_iam_role.github_oidc_role_plan.id
  policy_arn = aws_iam_policy.github_oidc_role_policy.arn
}

