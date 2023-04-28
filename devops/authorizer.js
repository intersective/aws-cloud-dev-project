const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();
const secretsManager = new AWS.SecretsManager();

let cognitoDetails;

exports.handler = async (event) => {
    if (!cognitoDetails) {
        cognitoDetails = { clientId: process.env.COGNITO_CLIENTID, userPoolDomain: process.env.COGNITO_USERPOOLDOMAIN}
        //cognitoDetails = await getCognitoDetailsFromSecretsManager();
    }

    const request = event.Records[0].cf.request;
    const headers = request.headers;
    const domainName = headers.host[0].value;
    const callbackPath = '/static/oauth2/idpresponse'; // The callback path for the Cognito Hosted UI

    // Allow requests to the callback URL without authentication
    if (request.uri === callbackPath) {
        return request;
    }

    // Check for the Cognito tokens in cookies
    const cookies = headers.cookie && headers.cookie[0] ? headers.cookie[0].value : '';
    const tokens = getCognitoTokensFromCookies(cookies);


    if (!tokens.id_token) {
        // Redirect to the Cognito Hosted UI for authentication
        const response = {
            status: '302',
            statusDescription: 'Found',
            headers: {
                location: [
                    {
                        key: 'Location',
                        value: getCognitoHostedUIURL(domainName, congitoDetails),
                    },
                ],
            },
        };
        return response;
    }


    try {
        // Validate the ID token
        const user = await validateCognitoIdToken(tokens.id_token, cognitoDetails);
        if (user) {
            return request;
        }
    } catch (error) {
        console.log('Error validating ID token:', error);
    }


    // If the ID token is invalid or expired, redirect to the Cognito Hosted UI for authentication
    const response = {
        status: '302',
        statusDescription: 'Found',
        headers: {
            location: [
                {
                    key: 'Location',
                    value: getCognitoHostedUIURL(domainName, cognitoDetails),
                },
            ],
        },
    };
    return response;
};


async function getCognitoDetailsFromSecretsManager() {

    const data = await secretsManager.getSecretValue({ SecretId: SECRET_NAME }).promise();
    if (data && data.SecretString) {
        return JSON.parse(data.SecretString);
    }
    throw new Error('Failed to retrieve Cognito details from Secrets Manager');
}


function getCognitoTokensFromCookies(cookies) {
    const tokens = {
        id_token: null,
        access_token: null,
        refresh_token: null,
    };


    if (cookies) {
        const cookieArray = cookies.split(';');
        for (const cookie of cookieArray) {
            const [name, value] = cookie.trim().split('=');
            if (name === 'cognito_id_token') {
                tokens.id_token = value;
            } else if (name === 'cognito_access_token') {
                tokens.access_token = value;
            } else if (name === 'cognito_refresh_token') {
                tokens.refresh_token = value;
            }
        }
    }
    return tokens;
}


function getCognitoHostedUIURL(domainName, cognitoDetails) {
    const clientId = cognitoDetails.clientId;
    const userPoolDomain = cognitoDetails.userPoolDomain;
    const callbackUrl = `https://${domainName}/oauth2/idpresponse`;


    return `https://${userPoolDomain}/login?response_type=token&client_id=${clientId}&redirect_uri=${encodeURIComponent(callbackUrl)}`;
}




async function validateCognitoIdToken(idToken, cognitoDetails) {
    // const userPoolId = cognitoDetails.userPoolId;
    const params = {
        AccessToken: idToken,
    };
  
    const result = await cognito.getUser(params).promise();
    if (result && result.UserAttributes) {
        // You can also extract additional user information from the result.UserAttributes array if needed
        return result.Username;
    }

    return null;
}
