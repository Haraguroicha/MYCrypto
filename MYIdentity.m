//
//  MYIdentity.m
//  MYCrypto
//
//  Created by Jens Alfke on 4/9/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYIdentity.h"
#import "MYCrypto_Private.h"


@implementation MYIdentity


- (id) initWithIdentityRef: (SecIdentityRef)identityRef {
    Assert(identityRef);
    SecCertificateRef certificateRef;
    if (!check(SecIdentityCopyCertificate(identityRef, &certificateRef), @"SecIdentityCopyCertificate")) {
        [self release];
        return nil;
    }
    self = [super initWithCertificateRef: certificateRef];
    if (self) {
        _identityRef = identityRef;
        CFRetain(identityRef);
    }
    CFRelease(certificateRef);
    return self;
}


#if !TARGET_OS_IPHONE
- (id) initWithCertificateRef: (SecCertificateRef)certificateRef {
    self = [super initWithCertificateRef: certificateRef];
    if (self) {
        if (!check(SecIdentityCreateWithCertificate(NULL, certificateRef, &_identityRef),
                   @"SecIdentityCreateWithCertificate")) {
            [self release];
            return nil;
        }
    }
    return self;
}
#endif

- (void) dealloc
{
    if (_identityRef) CFRelease(_identityRef);
    [super dealloc];
}

- (void) finalize
{
    if (_identityRef) CFRelease(_identityRef);
    [super finalize];
}


- (MYPrivateKey*) privateKey {
    SecKeyRef keyRef = NULL;
    if (!check(SecIdentityCopyPrivateKey(_identityRef, &keyRef), @"SecIdentityCopyPrivateKey"))
        return NULL;
    MYPrivateKey *privateKey = [[MYPrivateKey alloc] _initWithKeyRef: keyRef
                                                          publicKey: self.publicKey];
    CFRelease(keyRef);
    return [privateKey autorelease];
}


#if !TARGET_OS_IPHONE

+ (MYIdentity*) preferredIdentityForName: (NSString*)name
{
    Assert(name);
    SecIdentityRef identityRef;
    if (!check(SecIdentityCopyPreference((CFStringRef)name, 0, NULL, &identityRef),
               @"SecIdentityCopyPreference"))
        return nil;
    return identityRef ?[[[self alloc] initWithIdentityRef: identityRef] autorelease] :nil;
}

- (BOOL) makePreferredIdentityForName: (NSString*)name {
    Assert(name);
    return check(SecIdentitySetPreference(_identityRef, (CFStringRef)name, 0),
                 @"SecIdentitySetPreference");
}

#endif !TARGET_OS_IPHONE

@end