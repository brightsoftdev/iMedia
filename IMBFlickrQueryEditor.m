/*
 iMedia Browser Framework <http://karelia.com/imedia/>
 
 Copyright (c) 2005-2010 by Karelia Software et al.
 
 iMedia Browser is based on code originally developed by Jason Terhorst,
 further developed for Sandvox by Greg Hulands, Dan Wood, and Terrence Talbot.
 The new architecture for version 2.0 was developed by Peter Baumgartner.
 Contributions have also been made by Matt Gough, Martin Wennerberg and others
 as indicated in source files.
 
 The iMedia Browser Framework is licensed under the following terms:
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in all or substantial portions of the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following
 conditions:
 
	Redistributions of source code must retain the original terms stated here,
	including this list of conditions, the disclaimer noted below, and the
	following copyright notice: Copyright (c) 2005-2010 by Karelia Software et al.
 
	Redistributions in binary form must include, in an end-user-visible manner,
	e.g., About window, Acknowledgments window, or similar, either a) the original
	terms stated here, including this list of conditions, the disclaimer noted
	below, and the aforementioned copyright notice, or b) the aforementioned
	copyright notice and a link to karelia.com/imedia.
 
	Neither the name of Karelia Software, nor Sandvox, nor the names of
	contributors to iMedia Browser may be used to endorse or promote products
	derived from the Software without prior and express written permission from
	Karelia Software or individual contributors, as appropriate.
 
 Disclaimer: THE SOFTWARE IS PROVIDED BY THE COPYRIGHT OWNER AND CONTRIBUTORS
 "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH, THE
 SOFTWARE OR THE USE OF, OR OTHER DEALINGS IN, THE SOFTWARE.
*/


// Author: Christoph Priebe


//----------------------------------------------------------------------------------------------------------------------

//	iMedia
#import "IMBCommon.h"
#import "IMBFlickrQueryEditor.h"
#import "IMBFlickrNode.h"
#import "IMBFlickrParser.h"



//----------------------------------------------------------------------------------------------------------------------

@implementation IMBFlickrQueryEditor

NSString* const IMBFlickrQueryEditor_QueryChanged = @"IMBFlickrQueryEditor_QueryChanged";


+ (IMBFlickrQueryEditor*) flickrQueryEditorForParser: (IMBFlickrParser*) parser {
	IMBFlickrQueryEditor* editor = [[[IMBFlickrQueryEditor alloc] init] autorelease];
	editor.parser = parser;
	return editor;
}


- (id) init  {
    self = [super initWithNibName:@"IMBFlickrQueryEditor" bundle:IMBBundle ()];
    if (self != nil) {
    }
    return self;
}


- (void) dealloc {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(apply:) object:self];

	_parser = nil;
	[super dealloc];
}


- (void) awakeFromNib {
	[super awakeFromNib];
	
	NSImage *noImage = [[[NSImage alloc] initByReferencingFile:[IMBBundle() pathForResource:@"any" ofType:@"pdf"]] autorelease];
	NSImage *ccImage = [[[NSImage alloc] initByReferencingFile:[IMBBundle() pathForResource:@"CC" ofType:@"pdf"]] autorelease];
	NSImage *reImage = [[[NSImage alloc] initByReferencingFile:[IMBBundle() pathForResource:@"remix" ofType:@"pdf"]] autorelease];
	NSImage *coImage = [[[NSImage alloc] initByReferencingFile:[IMBBundle() pathForResource:@"commercial" ofType:@"pdf"]] autorelease];

	[noImage setScalesWhenResized:YES];	[noImage setSize:NSMakeSize(16.0,16.0)];
	[ccImage setScalesWhenResized:YES];	[ccImage setSize:NSMakeSize(16.0,16.0)];
	[reImage setScalesWhenResized:YES];	[reImage setSize:NSMakeSize(16.0,16.0)];
	[coImage setScalesWhenResized:YES];	[coImage setSize:NSMakeSize(16.0,16.0)];
	
	[[_licensePopup itemAtIndex:[_licensePopup indexOfItemWithTag:0]] setImage:noImage];
	[[_licensePopup itemAtIndex:[_licensePopup indexOfItemWithTag:1]] setImage:ccImage];
	[[_licensePopup itemAtIndex:[_licensePopup indexOfItemWithTag:2]] setImage:reImage];
	[[_licensePopup itemAtIndex:[_licensePopup indexOfItemWithTag:3]] setImage:coImage];
	
	NSAssert (_queriesController != nil, @"Can't find '_queriesController'.");
	NSAssert (_queryTitle != nil, @"Can't find '_queryTitle'.");
	
	[_queriesController addObserver:self forKeyPath:[@"selection." stringByAppendingString:IMBFlickrNodeProperty_License] options:0 context:IMBFlickrQueryEditor_QueryChanged];
	[_queriesController addObserver:self forKeyPath:[@"selection." stringByAppendingString:IMBFlickrNodeProperty_Method] options:0 context:IMBFlickrQueryEditor_QueryChanged];
	[_queriesController addObserver:self forKeyPath:[@"selection." stringByAppendingString:IMBFlickrNodeProperty_Query] options:0 context:IMBFlickrQueryEditor_QueryChanged];
	[_queriesController addObserver:self forKeyPath:[@"selection." stringByAppendingString:IMBFlickrNodeProperty_Title] options:0 context:IMBFlickrQueryEditor_QueryChanged];
	[_queriesController addObserver:self forKeyPath:[@"selection." stringByAppendingString:IMBFlickrNodeProperty_SortOrder] options:0 context:IMBFlickrQueryEditor_QueryChanged];
}


#pragma mark 
#pragma mark Notifications & Observing

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context {
	if (context == IMBFlickrQueryEditor_QueryChanged) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(apply:) object:self];
		[self performSelector:@selector(apply:) withObject:self afterDelay:2.0f inModes:[NSArray arrayWithObject:(NSString*)kCFRunLoopCommonModes]];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark
#pragma mark Actions

- (IBAction) add: (id) sender {
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict setObject:@"New Search" forKey:IMBFlickrNodeProperty_Title];
	[dict setObject:[NSNumber numberWithInt:IMBFlickrNodeLicense_CreativeCommons] forKey:IMBFlickrNodeProperty_License];
	[dict setObject:[NSNumber numberWithInt:IMBFlickrNodeMethod_TextSearch] forKey:IMBFlickrNodeProperty_Method];
	[dict setObject:@"Steve Jobs" forKey:IMBFlickrNodeProperty_Query];	
	[dict setObject:[NSNumber numberWithInt:IMBFlickrNodeSortOrder_InterestingnessDesc] forKey:IMBFlickrNodeProperty_SortOrder];
	[_queriesController addObject:dict];
}


- (IBAction) apply: (id) sender {
	[self.parser saveCustomQueries];
	[self.parser reloadCustomQueries];
}


#pragma mark
#pragma mark Properties

@synthesize parser = _parser;

@end
