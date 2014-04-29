//
//  OAuth2Token.m

#import "OAuth2Token.h"
#import "OAuth2Defines.h"
#import "WebServiceManager.h"

/**
 * @brief Private extension to the OAuthToken class. These variables do not need to be part of the public interface.
 */
@interface OAuth2Token()
@property (nonatomic,strong) WebServiceRequest *oAuth2Request; /**< Request currently underway for either auth or reauth */

@end

@implementation OAuth2Token

-(id)init {
	self = [super init];
	if (self) {
		_saveToken = NO;
	}
	return self;
}

-(id)initWithServiceName:(NSString*)service {
	self = [self init];
	if (self) {
		_serviceIdentifier = service;
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
	self = [self init];
	if (self) {
		_serviceIdentifier = [aDecoder decodeObjectForKey:OAUTH2_SERVICE_KEY];
		
		_clientID = [aDecoder decodeObjectForKey:OAUTH2_CLIENT_ID_KEY];
		_clientSecret = [aDecoder decodeObjectForKey:OAUTH2_CLIENT_SECRET_KEY];
		_authorizationURL = [aDecoder decodeObjectForKey:OAUTH2_AUTH_URL_KEY];
		_tokenURL = [aDecoder decodeObjectForKey:OAUTH2_TOKEN_URL_KEY];
		_requestedScope = [aDecoder decodeObjectForKey:OAUTH2_REQUESTED_SCOPE_KEY];
		
		_accessToken = [aDecoder decodeObjectForKey:OAUTH2_ACCESS_TOKEN_KEY];
		_tokenType = [aDecoder decodeObjectForKey:OAUTH2_TOKEN_TYPE_KEY];
		_refreshToken = [aDecoder decodeObjectForKey:OAUTH2_REFRESH_TOKEN_KEY];
		_expirationTime = [aDecoder decodeObjectForKey:OAUTH2_EXPIRES_IN_KEY];
		_recievedScope = [aDecoder decodeObjectForKey:OAUTH2_SCOPE_KEY];
		
		_saveToken = YES;//since we're decoding, this must be yes
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_serviceIdentifier forKey:OAUTH2_SERVICE_KEY];
	
	[aCoder encodeObject:_clientID forKey:OAUTH2_CLIENT_ID_KEY];
	[aCoder encodeObject:_clientSecret forKey:OAUTH2_CLIENT_SECRET_KEY];
	[aCoder encodeObject:_authorizationURL forKey:OAUTH2_AUTH_URL_KEY];
	[aCoder encodeObject:_tokenURL forKey:OAUTH2_TOKEN_URL_KEY];
	[aCoder encodeObject:_requestedScope forKey:OAUTH2_REQUESTED_SCOPE_KEY];
	
	[aCoder encodeObject:_accessToken forKey:OAUTH2_ACCESS_TOKEN_KEY];
	[aCoder encodeObject:_tokenType forKey:OAUTH2_TOKEN_TYPE_KEY];
	[aCoder encodeObject:_refreshToken forKey:OAUTH2_REFRESH_TOKEN_KEY];
	[aCoder encodeObject:_expirationTime forKey:OAUTH2_EXPIRES_IN_KEY];
	[aCoder encodeObject:_recievedScope forKey:OAUTH2_SCOPE_KEY];
}

-(OAuth2TokenStatus)tokenStatus {
	OAuth2TokenStatus ret = OAuth2TokenStatusUnknown;
	if (self.accessToken == nil || self.tokenType == nil) {
		ret = OAuth2TokenStatusNoToken;
	} else if ([self.expirationTime compare:[NSDate date]] == NSOrderedAscending) {
		ret = OAuth2TokenStatusExipred;
	} else {
		ret = OAuth2TokenStatusValid;
	}
	return ret;
}

/**
 * Updates token info and saves it to the keychain, if saving is turned on.
 */
-(void)updateWithDictionary:(NSDictionary*)dataDict saveStatus:(BOOL)saveToken {
	_saveToken = saveToken;
	_accessToken = [dataDict objectForKey:OAUTH2_ACCESS_TOKEN_KEY];
	_tokenType = [dataDict objectForKey:OAUTH2_TOKEN_TYPE_KEY];
	_refreshToken = [dataDict objectForKey:OAUTH2_REFRESH_TOKEN_KEY];
	_recievedScope = [dataDict objectForKey:OAUTH2_SCOPE_KEY];
	_expirationTime = [NSDate dateWithTimeIntervalSinceNow:[[dataDict objectForKey:OAUTH2_EXPIRES_IN_KEY] doubleValue]];
	if (_saveToken) {
		[[WebServiceManager sharedManager] keychainSave:self];
	} else {
        [[WebServiceManager sharedManager] keychainDeleteForService:self.serviceIdentifier authClass:[self class]];
    }
}

-(void)setSaveToken:(BOOL)saveToken {
	if (_saveToken != saveToken) {
		//only update if it has changed
		_saveToken = saveToken;
		if (_saveToken == NO) {
			//delete the current token information
			[[WebServiceManager sharedManager] keychainDeleteForService:self.serviceIdentifier authClass:[self class]];
		} else {
			//save off the information
			[[WebServiceManager sharedManager] keychainSave:self];
		}
	}
}


-(void)setOAuth2ClientID:(NSString *)client_id secret:(NSString *)client_secret authorizationURL:(NSString *)authorization_url tokenURL:(NSString *)token_url scope:(NSString *)scope {
	self.clientID = client_id;
	self.clientSecret = client_secret;
	self.authorizationURL = authorization_url;
	self.tokenURL = token_url;
	self.requestedScope = scope;
}

- (NSError *)handleErrorCheck:(id)data
{
    return nil;
}

-(WebServiceRequest*)oAuth2WithOwnerResourceFlow:(NSString*)username
																				password:(NSString*)password
																	 saveTokenInfo:(BOOL)saveToken
																				callback:(WebServiceCallbackBlock)callback{
	if (self.oAuth2Request) {
		return self.oAuth2Request;
	}
	if (self.tokenURL == nil) {
		callback(nil,nil,[NSError errorWithDomain:OAUTH2_ERROR_DOMAIN code:OAuth2ErrorInvalidTokenURI userInfo:OAUTH2_INVALID_TOKEN_DICT(self.tokenURL)]);
	}
	
	//first do the optional items, clientid and secret
	NSMutableString *destinationURL = [NSMutableString stringWithFormat:@"%@?",self.tokenURL];
	if (self.clientID && self.clientSecret) {
		[destinationURL appendFormat:@"%@=%@&%@=%@&",OAUTH2_CLIENT_ID_KEY,self.clientID,OAUTH2_CLIENT_SECRET_KEY,self.clientSecret];
	}
	//scope
	if (self.recievedScope) {
		[destinationURL appendFormat:@"%@=%@&",OAUTH2_SCOPE_KEY,self.recievedScope];
	}
	//response type should always be token, but we'll make sure to specify it
	[destinationURL appendFormat:@"%@=%@&",OAUTH2_RESPONSE_TYPE_KEY,OAUTH2_RESPONSE_TYPE_TOKEN_KEY];
	
	//now the required elements
	NSString *un = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)username, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8));
	NSString *pw = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)password, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8));
	
	[destinationURL appendFormat:@"%@=%@&%@=%@&%@=%@",OAUTH2_GRANT_TYPE_KEY,OAUTH2_GRANT_TYPE_PASSWORD_VALUE,OAUTH2_USERNAME_KEY,un,OAUTH2_PASSWORD_KEY,pw];
	
	//now attempt to make the call
	self.oAuth2Request = [[WebServiceRequest alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:destinationURL]] completion:^(id data,NSURLResponse *response,NSError *error) {
		if (error) {
			callback(nil,nil,error);
		} else if (response) {
			if ([response.MIMEType compare:MIME_TYPE_JSON] == NSOrderedSame) {
				//got a good response, let's parse it
				NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
				NSError *finalError = [self handleErrorCheck:dict];
				if (finalError) {
					callback(dict,response,finalError);
				} else {
					[self updateWithDictionary:dict saveStatus:saveToken];
					callback(dict,response,nil);
				}
			} else {
				//got a response that we don't know how to handle yet
				//throw an error
				callback(nil,nil,[NSError errorWithDomain:OAUTH2_ERROR_DOMAIN code:OAuth2ErrorUnsupportedMIMEType userInfo:OAUTH2_UNSUPPORED_MIME_TOKEN_DICT(response.MIMEType)]);
			}
		}
		self.oAuth2Request = nil;
	}];
	[[WebServiceManager sharedManager] startAsync:self.oAuth2Request];
	return self.oAuth2Request;
}

#pragma mark - Auth Protocol Methods

-(BOOL)signRequestIfNecesary:(NSMutableURLRequest *)urlRequest {
	if (self.tokenStatus == OAuth2TokenStatusValid) {
		NSString *oauthAuthorizationHeader = [NSString stringWithFormat:@"%@ %@", self.tokenType, self.accessToken];
		[urlRequest setValue:oauthAuthorizationHeader forHTTPHeaderField:@"Authorization"];
	} else if (self.tokenStatus == OAuth2TokenStatusExipred) {
		//can't sign because the token as expired. tell the caller that.
		return YES;
	}
	return NO;
}

-(WebServiceRequest*)updateAccessToken:(WebServiceCallbackBlock)callback async:(BOOL)performAsync{
	if (self.refreshToken == nil) {
		//no refresh token, throw error
		callback(nil,nil,[NSError errorWithDomain:OAUTH2_ERROR_DOMAIN code:OAuth2ErrorUnableToRefreshAccessToken userInfo:nil]);
	}
	NSMutableString *destinationURL = [NSMutableString stringWithFormat:@"%@?",self.tokenURL];
	if (self.clientID && self.clientSecret) {
		[destinationURL appendFormat:@"%@=%@&%@=%@&",OAUTH2_CLIENT_ID_KEY,self.clientID,OAUTH2_CLIENT_SECRET_KEY,self.clientSecret];
	}
	//scope
	if (self.recievedScope) {
		[destinationURL appendFormat:@"%@=%@&",OAUTH2_SCOPE_KEY,self.recievedScope];
	}
	//response type should always be token, but we'll make sure to specify it
	[destinationURL appendFormat:@"%@=%@&",OAUTH2_RESPONSE_TYPE_KEY,OAUTH2_RESPONSE_TYPE_TOKEN_KEY];
	
	//now the required elements
	[destinationURL appendFormat:@"%@=%@&%@=%@",OAUTH2_GRANT_TYPE_KEY,OAUTH2_GRANT_TYPE_REFRESH_TOKEN_VALUE,OAUTH2_REFRESH_TOKEN_KEY,self.refreshToken];
	self.oAuth2Request = [[WebServiceRequest alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:destinationURL]] completion:^(id data,NSURLResponse *response,NSError *error) {
		if (error) {
			callback(nil,nil,error);
		} else if	(response) {
			if ([response.MIMEType compare:MIME_TYPE_JSON] == NSOrderedSame) {
				//got a good response, let's parse it
				NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
				[self updateWithDictionary:dict saveStatus:self.saveToken];
				callback(dict,response,nil);
			} else {
				//got a response that we don't know how to handle yet
				//throw an error
				callback(nil,nil,[NSError errorWithDomain:OAUTH2_ERROR_DOMAIN code:OAuth2ErrorUnsupportedMIMEType userInfo:OAUTH2_UNSUPPORED_MIME_TOKEN_DICT(response.MIMEType)]);
			}
		}
		self.oAuth2Request = nil;
	}];
	
	if (performAsync) {
		[[WebServiceManager sharedManager] startAsync:self.oAuth2Request authorizeForService:nil];
	} else {
		[[WebServiceManager sharedManager] startSync:self.oAuth2Request authorizeForService:nil];
	}
	return self.oAuth2Request;
}



-(BOOL)isAuthenticated {
	return self.tokenStatus == OAuth2TokenStatusValid;
}

-(NSError*)reauthError {
	return [NSError errorWithDomain:OAUTH2_ERROR_DOMAIN code:OAuth2ErrorUnableToRefreshAccessToken userInfo:nil];
}


+(NSString*)authTypeIdentifier {
	return OAUTH2_KEYCHAIN_IDENTIFIER;
}

@end
