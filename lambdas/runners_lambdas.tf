module "lambdas" {
  version = "v2.2.0"
  source  = "philips-labs/github-runner/aws//modules/download-lambda"
  lambdas = [
    {
      name = "webhook"
      tag  = "v2.2.0"
    },
    {
      name = "runners"
      tag  = "v2.2.0"
    },
    {
      name = "runner-binaries-syncer"
      tag  = "v2.2.0"
    }
  ]
}
