module "lambdas" {
  version = "v3.6.1"
  source  = "philips-labs/github-runner/aws//modules/download-lambda"
  lambdas = [
    {
      name = "webhook"
      tag  = "v3.6.1"
    },
    {
      name = "runners"
      tag  = "v3.6.1"
    },
    {
      name = "runner-binaries-syncer"
      tag  = "v3.6.1"
    }
  ]
}
