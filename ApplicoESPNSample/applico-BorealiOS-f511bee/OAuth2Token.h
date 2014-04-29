//
//  OAuth2Token.h

#import <Foundation/Foundation.h>
#import "WebServiceAuthProtocol.h"

typedef enum {
	OAuth2TokenStatusUnknown = 0, /**< Unknown OAuth2Token Status */
	OAuth2TokenStatusNoToken, /**< To Token has been issued */
	OAuth2TokenStatusExipred, /**< Current Token has exipired */
	OAuth2TokenStatusValid /**< Current Token is valid */
} OAuth2TokenStatus;



/**
 * @brief This class is used for storage of OAuth2 Token Information.
 * It is NSCoding compliant to allow for the saving of the token data to the keychain
 */
@interface OAuth2Token : NSObject <NSCoding,WebServiceAuthProtocol>

@property (nonatomic,strong) NSString *serviceIdentifier; /**< The identifier unique to this token service */

@property (nonatomic,strong) NSString *clientID; /**< OAuth2 client id/key */
@property (nonatomic,strong) NSString *clientSecret; /**< OAuth2 client secret */
@property (nonatomic,strong) NSString *authorizationURL; /**< OAuth2 Authorization URL. Used for display to the user in a webview to allow a 3rd party authorization server to authorize the request */
@property (nonatomic,strong) NSString *tokenURL; /**< OAuth2 Token URL. Used for obtaining the OAuth2 Token */
@property (nonatomic,strong) NSString *requestedScope; /**< OAuth2 User Requested Scope */

@property (nonatomic,strong) NSString *accessToken; /**< The access token */
@property (nonatomic,strong) NSString *tokenType; /**< The token type */
@property (nonatomic,strong) NSString *refreshToken; /**< the refresh token */
@property (nonatomic,strong) NSDate *expirationTime; /**< Time that the OAuth2 token will expire */
@property (nonatomic,strong) NSString *recievedScope; /**< The scope that the OAuth2 token server is actually providing */

@property (nonatomic,assign) BOOL saveToken; /**< Marks whether the token should be saved to the keychain. Setting to NO will erase current token information from the keychain */

@property (nonatomic,readonly) OAuth2TokenStatus tokenStatus; /**< Read only property to ascertain the status of the token */
-(void)updateWithDictionary:(NSDictionary*)dataDict saveStatus:(BOOL)saveToken;

/**
 * @brief inits with the specified service identifier
 * @param service the name of the service to which this token belongs
 * @return returns self
 */
-(id)initWithServiceName:(NSString*)service;


/**
 * @brief sets the webservice manager up for oauth2 connections with the specified connection information
 * @param client_id the client id of the connecting application
 * @param client_secret the client secret of the connecting application
 * @param authorization_url used for authorization grant flow
 * @param token_url used for obtaining the token
 * @param scope the scope of the authorization request
 */
-(void)setOAuth2ClientID:(NSString*)client_id
									secret:(NSString*)client_secret
				authorizationURL:(NSString*)authorization_url
								tokenURL:(NSString*)token_url
									 scope:(NSString*)scope;

/**
 * @brief performs an oauth2 authentication with the owner/resource flow
 * this method will start the request
 * username and password are not saved in this class
 * @param username the user to authenticate as
 * @param password the user's password
 * @param saveToken whether to save the token to the keychain
 * @param callback the callback upon completion of the webrequest
 *  the data parameter of the callback will be an already decoded JSON Dictionary
 */
-(WebServiceRequest*)oAuth2WithOwnerResourceFlow:(NSString*)username
																				password:(NSString*)password
																	 saveTokenInfo:(BOOL)saveToken
																				callback:(WebServiceCallbackBlock)callback;

- (NSError *)handleErrorCheck:(id)data;

@end
