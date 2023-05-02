module "lambdas" {
  version = "v3.2.0"
  source  = "philips-labs/github-runner/aws//modules/download-lambda"
  lambdas = [
    {
      name = "webhook"
      tag  = "v3.2.0"
    },
    {
      name = "runners"
      tag  = "v3.2.0"
    },
    {
      name = "runner-binaries-syncer"
      tag  = "v3.2.0"
    }
  ]
}
