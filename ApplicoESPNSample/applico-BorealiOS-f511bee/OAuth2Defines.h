//
//  OAuth2Defines.h

typedef enum {
	OAuth2ErrorInvalidTokenURI = 4000000,
	OAuth2ErrorUnsupportedMIMEType,
	OAuth2ErrorUnableToRefreshAccessToken
} OAuth2ErrorCode;

//the OAuth2 Standard specifies that the server support all operations via GET
//the server may support doing them via POST
//setting this to 1 will force all OAuth2 requests to be made via POST
#define PERFORM_OAUTH2_VIA_POST 0
#define OAUTH2_KEYCHAIN_IDENTIFIER @"oAuth2TokenInfo" /**< This identifier is used for saving token information to the keychain */
#define OAUTH2_SERVICE_KEY @"service"
#define OAUTH2_AUTH_URL_KEY @"auth_url"
#define OAUTH2_TOKEN_URL_KEY @"token_url"
#define OAUTH2_REQUESTED_SCOPE_KEY @"requested_scope"

#define OAUTH2_ERROR_DOMAIN @"com.applico.oauth2"
#define OAUTH2_INVALID_TOKEN_DICT(_SUPPLIED_URI_) [NSDictionary dictionaryWithObject:_SUPPLIED_URI_ forKey:@"SuppliedURI"]
#define OAUTH2_UNSUPPORED_MIME_TOKEN_DICT(_MIME_TYPE_) [NSDictionary dictionaryWithObject:_MIME_TYPE_ forKey:@"MIMEType"]

#define OAUTH2_CLIENT_ID_KEY @"client_id"
#define OAUTH2_CLIENT_SECRET_KEY @"client_secret"
#define OAUTH2_USERNAME_KEY @"username"
#define OAUTH2_PASSWORD_KEY @"password"
#define OAUTH2_GRANT_TYPE_KEY @"grant_type"
#define OAUTH2_GRANT_TYPE_PASSWORD_VALUE @"password"
#define OAUTH2_GRANT_TYPE_REFRESH_TOKEN_VALUE @"refresh_token"
#define OAUTH2_RESPONSE_TYPE_KEY @"response_type"
#define OAUTH2_RESPONSE_TYPE_TOKEN_KEY @"token"
#define OAUTH2_ACCESS_TOKEN_KEY @"access_token"
#define OAUTH2_TOKEN_TYPE_KEY @"token_type"
#define OAUTH2_REFRESH_TOKEN_KEY @"refresh_token"
#define OAUTH2_EXPIRES_IN_KEY @"expires_in"
#define OAUTH2_SCOPE_KEY @"scope"
