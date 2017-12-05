//
//  VASTXMLUtil.h
//  VAST
//
//  Created by Jay Tucker on 10/15/13.
//  Copyright (c) 2013 Nexage. All rights reserved.
//
//  VASTXMLUtil validates a VAST document for correct XML syntax and conformance to the VAST 2.0.1.xsd schema.

#import <Foundation/Foundation.h>

@interface XADVASTXMLUtil : NSObject
+ (BOOL) validateXMLDocSyntax: (NSData*)document;                         // check for valid XML syntax using xmlReadMemory
+ (BOOL) validateXMLDocAgainstSchema: (NSData*) document schema:(NSData*)schemaData;  // check for valid VAST 2.0 syntax using xmlSchemaValidateDoc & vast_2.0.1.xsd schema
+ (NSArray*) performXMLXPathQuery: (NSData*)document query:(NSString*)query;    // parse the document for the xpath in 'query' using xmlXPathEvalExpression

@end
