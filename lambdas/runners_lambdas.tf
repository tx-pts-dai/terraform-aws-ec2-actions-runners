module "lambdas" {
  version = "5.10.4"
  source  = "philips-labs/github-runner/aws//modules/download-lambda"
  lambdas = [
    {
      name = "webhook"
      tag  = "v5.10.4"
    },
    {
      name = "runners"
      tag  = "v5.10.4"
    },
    {
      name = "runner-binaries-syncer"
      tag  = "v5.10.4"
    }
  ]
}
