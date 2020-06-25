# AWS Lambda w/ Typescript packaged with webpack, deployed w/ Terraform

Really simple deployment of a Lambda function
For more details [lambda-typescript-webpack](https://github.com/pdlug/lambda-typescript-webpack).

[Terraform](https://terraform.io/)
For the simple use case of an HTTP endpoint calling a Lambda function HTTP API.

For a detailed comparison, see [Choosing between HTTP APIs and REST APIs](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-vs-rest.html)

## Getting started

Install dependencies with `yarn`:

```bash
yarn install
```

Build the lambda function and run `terraform apply` to deploy it:

```bash
yarn run deploy
```

The output will contain the URL of the API endpoint that was created.

## Issues

Every run it was attempting to remove `deployment_id` and `default_route_settings.logging_level` to `"OFF"`. The logging level is not valid for HTTP APIs so this would fail on every apply. The comment:

[Amazon API Gateway HTTP APIs #11148](https://github.com/terraform-providers/terraform-provider-aws/issues/11148#issuecomment-619160589)
