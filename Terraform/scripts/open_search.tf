resource "aws_opensearch_domain" "opensearch_domain" {
  domain_name           = "opensearch-domain"
  elasticsearch_version = "7.10"

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp2"
  }

  cluster_config {
    instance_type = "t3.small.elasticsearch"
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "*"
        },
        Action = [
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpGet"
        ],
        Resource = "arn:aws:es:*:*:domain/opensearch-domain/*"
      }
    ]
  })
}

resource "aws_iam_policy" "opensearch_policy" {
  name        = "opensearch_policy"
  path        = "/"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "es:ESHttpDelete",
          "es:ESHttpHead",
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpPatch"
        ],
        Resource = "${aws_opensearch_domain.opensearch_domain.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "opensearch_policy_attachment" {
  policy_arn = aws_iam_policy.opensearch_policy.arn
  role       = aws_iam_role.page_extractor.name
}

data "aws_iam_policy_document" "opensearch_policy_document" {
  statement {
    actions = [
      "es:ESHttpPost",
      "es:ESHttpPut"
    ]
    resources = [
      "${aws_opensearch_domain.opensearch_domain.arn}/*"
    ]
  }
}

resource "aws_lambda_permission" "allow_opensearch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromOpenSearchDomain"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.page_extractor.arn
  principal     = "es.amazonaws.com"
  source_arn    = "${aws_opensearch_domain.opensearch_domain.arn}"
}

resource "aws_opensearch_domain_policy" "opensearch_domain_policy" {
  domain_name = aws_opensearch_domain.opensearch_domain.domain_name
  access_policies = data.aws_iam_policy_document.opensearch_policy_document.json
}
