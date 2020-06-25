import AWSLambda from "aws-lambda";

export default async (event: AWSLambda.APIGatewayEvent): Promise<AWSLambda.APIGatewayProxyResult> => ({
  headers: {
    "content-type": "application/json",
  },
  body: JSON.stringify({
    headers: event.headers,
    body: event.body,
    queryString: event.queryStringParameters,
    httpMethod: event.httpMethod,
    path: event.path,
  }),
  statusCode: 200,
});
