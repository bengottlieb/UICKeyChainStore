//
//  UICKeyChainStore.m
//  UICKeyChainStore
//
//  Created by Kishikawa Katsumi on 11/11/20.
//  Copyright (c) 2011 Kishikawa Katsumi. All rights reserved.
//

#import "UICKeyChainStore.h"

static NSString *defaultService;

@interface UICKeyChainStore () {
    NSMutableDictionary *itemsToUpdate;
}

@end

@implementation UICKeyChainStore

@synthesize service;
@synthesize accessGroup;

+ (void)initialize {
    defaultService = [[NSBundle mainBundle] bundleIdentifier];
}

+ (NSString *)stringForKey:(NSString *)key {
    return [self stringForKey:key service:defaultService accessGroup:nil];
}

+ (NSString *)stringForKey:(NSString *)key service:(NSString *)service {
    return [self stringForKey:key service:service accessGroup:nil];
}

+ (NSString *)stringForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
    NSData *data = [self dataForKey:key service:service accessGroup:accessGroup];
    if (data) {
        return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    return nil;
}

+ (void)setString:(NSString *)value forKey:(NSString *)key {
    [self setString:value forKey:key service:defaultService accessGroup:nil];
}

+ (void)setString:(NSString *)value forKey:(NSString *)key service:(NSString *)service {
    [self setString:value forKey:key service:service accessGroup:nil];
}

+ (void)setString:(NSString *)value forKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    [self setData:data forKey:key service:service accessGroup:accessGroup];
}

+ (NSData *)dataForKey:(NSString *)key {
    return [self dataForKey:key service:defaultService accessGroup:nil];
}

+ (NSData *)dataForKey:(NSString *)key service:(NSString *)service {
    return [self dataForKey:key service:service accessGroup:nil];
}

+ (NSData *)dataForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!key) {
        NSAssert(NO, @"key must not be nil.");
		return nil;
	}
	if (!service) {
        service = defaultService;
	}
    
	NSMutableDictionary* query = [NSMutableDictionary dictionary];
	[query setObject: (__bridge id) (kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
	[query setObject: (id) kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnData)];
	[query setObject: (__bridge id) (kSecMatchLimitOne) forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
	[query setObject: service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [query setObject: key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
    [query setObject: key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
#if !TARGET_IPHONE_SIMULATOR
    if (accessGroup) {
        [query setObject:accessGroup forKey:kSecAttrAccessGroup];
    }
#endif
    
	CFDataRef			data;
	OSStatus			status = SecItemCopyMatching((__bridge CFDictionaryRef) query, (CFTypeRef *) &data);
	if (status != errSecSuccess) {
        return nil;
	}
    
    return (__bridge_transfer NSData *) data;
}

+ (void)setData:(NSData *)data forKey:(NSString *)key {
    [self setData:data forKey:key service:defaultService accessGroup:nil];
}

+ (void)setData:(NSData *)data forKey:(NSString *)key service:(NSString *)service {
    [self setData:data forKey:key service:service accessGroup:nil];
}

+ (void)setData:(NSData *)data forKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!key) {
        NSAssert(NO, @"key must not be nil.");
		return;
	}
	if (!service) {
        service = defaultService;
	}
	
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	[query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
	[query setObject:service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [query setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
    [query setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
#if !TARGET_IPHONE_SIMULATOR
    if (accessGroup) {
        [query setObject:accessGroup forKey:kSecAttrAccessGroup];
    }
#endif
    
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
	if (status == errSecSuccess) {
        if (data) {
            NSMutableDictionary *attributesToUpdate = [NSMutableDictionary dictionary];
            [attributesToUpdate setObject:data forKey:(__bridge id<NSCopying>)(kSecValueData)];
            
            status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
            if (status != errSecSuccess) {
                NSLog(@"%s|SecItemUpdate: error(%ld)", __func__, status);
            }
        } else {
            [self removeItemForKey:key service:service accessGroup:accessGroup];
        }
	} else if (status == errSecItemNotFound) {
		NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
		[attributes setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
        [attributes setObject:service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
        [attributes setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
        [attributes setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
		[attributes setObject:data forKey:(__bridge id<NSCopying>)(kSecValueData)];
#if !TARGET_IPHONE_SIMULATOR
        if (accessGroup) {
            [attributes setObject:accessGroup forKey:kSecAttrAccessGroup];
        }
#endif
		
		status = SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
		if (status != errSecSuccess) {
			NSLog(@"%s|SecItemAdd: error(%ld)", __func__, status);
		}		
	} else {
		NSLog(@"%s|SecItemCopyMatching: error(%ld)", __func__, status);
	}
}

+ (void)removeItemForKey:(NSString *)key {
    [UICKeyChainStore removeItemForKey:key service:defaultService accessGroup:nil];
}

+ (void)removeItemForKey:(NSString *)key service:(NSString *)service {
    [UICKeyChainStore removeItemForKey:key service:service accessGroup:nil];
}

+ (void)removeItemForKey:(NSString *)key service:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!key) {
        NSAssert(NO, @"key must not be nil.");
		return;
	}
	if (!service) {
        service = defaultService;
	}
	
	NSMutableDictionary *itemToDelete = [NSMutableDictionary dictionary];
	[itemToDelete setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
	[itemToDelete setObject:service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [itemToDelete setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
    [itemToDelete setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
#if !TARGET_IPHONE_SIMULATOR
    if (accessGroup) {
        [itemToDelete setObject:accessGroup forKey:kSecAttrAccessGroup];
    }
#endif
	
	OSStatus status = SecItemDelete((__bridge CFDictionaryRef)itemToDelete);
	if (status != errSecSuccess && status != errSecItemNotFound) {
		NSLog(@"%s|SecItemDelete: error(%ld)", __func__, status);
	}
}

+ (NSArray *)itemsForService:(NSString *)service accessGroup:(NSString *)accessGroup {
	if (!service) {
        service = defaultService;
	}
	
	NSMutableDictionary *query = [NSMutableDictionary dictionary];
	[query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
	[query setObject:(id)kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnAttributes)];
	[query setObject:(id)kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnData)];
	[query setObject:(__bridge id)(kSecMatchLimitAll) forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
	[query setObject:service forKey:(__bridge id<NSCopying>)(kSecAttrService)];
#if !TARGET_IPHONE_SIMULATOR
    if (accessGroup) {
        [query setObject:accessGroup forKey:kSecAttrAccessGroup];
    }
#endif
	
	CFArrayRef result = nil;
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
	if (status == errSecSuccess || status == errSecItemNotFound) {
		return [(__bridge NSArray *)result autorelease];
	} else {
		NSLog(@"%s|SecItemCopyMatching: error(%ld)", __func__, status);
		return nil;
	}
}

+ (void)removeAllItems {
    [self removeAllItemsForService:defaultService accessGroup:nil];
}

+ (void)removeAllItemsForService:(NSString *)service {
    [self removeAllItemsForService:service accessGroup:nil];
}

+ (void)removeAllItemsForService:(NSString *)service accessGroup:(NSString *)accessGroup {
    NSArray *items = [UICKeyChainStore itemsForService:service accessGroup:accessGroup];    
    for (NSDictionary *item in items) {
        NSMutableDictionary *itemToDelete = [NSMutableDictionary dictionaryWithDictionary:item];
        [itemToDelete setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
        
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)itemToDelete);
        if (status != errSecSuccess) {
            NSLog(@"%s|SecItemDelete: error(%ld)", __func__, status);
            NSLog(@"%@", itemToDelete);
        }
    }
}

#pragma mark -

+ (UICKeyChainStore *)keyChainStore {
    return [[[self alloc] initWithService:defaultService] autorelease];
}

+ (UICKeyChainStore *)keyChainStoreWithService:(NSString *)service {
    return [[[self alloc] initWithService:service] autorelease];
}

+ (UICKeyChainStore *)keyChainStoreWithService:(NSString *)service accessGroup:(NSString *)accessGroup {
    return [[[self alloc] initWithService:service accessGroup:accessGroup] autorelease];
}

- (id)init {
    return [self initWithService:defaultService accessGroup:nil];
}

- (id)initWithService:(NSString *)s {
    return [self initWithService:s accessGroup:nil];
}

- (id)initWithService:(NSString *)s accessGroup:(NSString *)group {
    self = [super init];
    if (self) {
        if (!s) {
            s = defaultService;
        }
        service = [s copy];
        accessGroup = [group copy];
        if (accessGroup) {
#if !TARGET_IPHONE_SIMULATOR
            [itemsToUpdate setObject:accessGroup forKey:(id)kSecAttrAccessGroup];
#endif
        }
		
        NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:itemsToUpdate];
        [query setObject:(__bridge id)kSecMatchLimitAll forKey:
		 (__bridge id)kSecMatchLimit];
        [query setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
        
		CFDictionaryRef			result;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *) &result);
        if (status == errSecSuccess) {
            itemsToUpdate = [[NSMutableDictionary alloc] initWithDictionary: (__bridge NSDictionary *) result];
		} else {
            itemsToUpdate = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

#pragma mark -

- (NSString *)description {
    NSArray *items = [UICKeyChainStore itemsForService:service accessGroup:accessGroup];
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:[items count]];    
    for (NSDictionary *attributes in items) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        [attrs setObject:[attributes objectForKey:(__bridge id)(kSecAttrService)] forKey:@"Service"];
        [attrs setObject:[attributes objectForKey:(__bridge id)(kSecAttrAccount)] forKey:@"Account"];
        [attrs setObject:[attributes objectForKey:(__bridge id)(kSecAttrAccessGroup)] forKey:@"AccessGroup"];
        NSData *data = [attributes objectForKey:(__bridge id)(kSecValueData)];
        NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        if (string) {
            [attrs setObject:string forKey:@"Value"];
        } else {
            [attrs setObject:data forKey:@"Value"];
        }
        [list addObject:attrs];
    }
    return [list description];
}

#pragma mark -

- (void)setString:(NSString *)string forKey:(NSString *)key {
    [self setData:[string dataUsingEncoding:NSUTF8StringEncoding] forKey:key];
}

- (NSString *)stringForKey:(id)key {
    NSData *data = [self dataForKey:key];
    if (data) {
        return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    }
    return nil;
}

- (void)setData:(NSData *)data forKey:(NSString *)key {
    if (!key) {
        return;
    }
    if (!data) {
        [self removeItemForKey:key];
    } else {
        [itemsToUpdate setObject:data forKey:key];
    }
}

- (NSData *)dataForKey:(NSString *)key {
    NSData *data = [itemsToUpdate objectForKey:key];
    if (!data) {
        data = [[self class] dataForKey:key service:service accessGroup:accessGroup];
    }
    return data;
}

- (void)removeItemForKey:(NSString *)key {
    if ([itemsToUpdate objectForKey:key]) {
        [itemsToUpdate removeObjectForKey:key];
    } else {
        [[self class] removeItemForKey:key service:service accessGroup:accessGroup];
    }
}

#pragma mark -

- (void)removeAllItems {
    [itemsToUpdate removeAllObjects];
    [[self class] removeAllItemsForService:service accessGroup:accessGroup];
}

#pragma mark -

- (void)synchronize {    
    for (NSString *key in itemsToUpdate) {
        [[self class] setData:[itemsToUpdate objectForKey:key] forKey:key service:service accessGroup:accessGroup];
    }
}

@end
