#import <substrate.h>
#import <Foundation/Foundation.h>

@interface FBIntegrationFixProtocol : NSURLProtocol
@end

@implementation FBIntegrationFixProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:@"FBIntegrationFixHandled" inRequest:request]) return NO;
    NSString *host = request.URL.host;
    NSString *path = request.URL.path;
    if ([host isEqualToString:@"graph.facebook.com"]) {
        if ([path isEqualToString:@"//me/privacy_options"] || [path isEqualToString:@"/me/links"]) return YES;
    }
    if ([host isEqualToString:@"api.facebook.com"] && [path isEqualToString:@"/method/auth.login"]) return YES;
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        NSURL *url = self.request.URL;
        NSString *host = url.host;
        NSString *path = url.path;
        NSMutableURLRequest *newReq = [self.request mutableCopy];
        if ([host isEqualToString:@"graph.facebook.com"]) {
            if ([path isEqualToString:@"//me/privacy_options"]) {
                NSString *newURLStr = @"https://graph.facebook.com/me?fields=privacy_options";
                NSString *query = url.query;
                if (query) newURLStr = [newURLStr stringByAppendingFormat:@"&%@", query];
                newReq.URL = [NSURL URLWithString:newURLStr];
            }
            else if ([path isEqualToString:@"/me/links"]) {
                NSString *newURLStr = @"https://graph.facebook.com/me/feed";
                NSString *query = url.query;
                if (query) newURLStr = [newURLStr stringByAppendingFormat:@"?%@", query];
                newReq.URL = [NSURL URLWithString:newURLStr];
            }
        }
        else if ([host isEqualToString:@"api.facebook.com"] && [path isEqualToString:@"/method/auth.login"]) {
            NSData *bodyData = newReq.HTTPBody;
            if (bodyData) {
                NSString *body = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
                if ([body rangeOfString:@"access_token=213546525407071%7C362ee4c5fe721df3c7d216115b575410"].location != NSNotFound) {
                    NSString *newBody = [body stringByReplacingOccurrencesOfString:@"access_token=213546525407071%7C362ee4c5fe721df3c7d216115b575410" withString:@"access_token=237759909591655%7C0f140aabedfb65ac27a739ed1a2263b1"];
                    newReq.HTTPBody = [newBody dataUsingEncoding:NSUTF8StringEncoding];
                }
            }
        }
        NSURLResponse *response = nil;
        NSError *error = nil;
        [NSURLProtocol setProperty:@YES forKey:@"FBIntegrationFixHandled" inRequest:newReq];
        NSData *data = [NSURLConnection sendSynchronousRequest:newReq returningResponse:&response error:&error];
        if (error) {
            [self.client URLProtocol:self didFailWithError:error];
            return;
        }
        if ([path isEqualToString:@"//me/privacy_options"]) {
            NSError *error = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (json && !error) {
                NSDictionary *privacyOptions = json[@"privacy_options"];
                if (privacyOptions) {
                    NSData *newData = [NSJSONSerialization dataWithJSONObject:privacyOptions options:0 error:&error];
                    if (newData && !error) data = newData;
                }
            }
        }
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [self.client URLProtocol:self didLoadData:data];
        [self.client URLProtocolDidFinishLoading:self];
    }];
}

- (void)stopLoading {
}

@end

%ctor {
    [NSURLProtocol registerClass:[FBIntegrationFixProtocol class]];
}