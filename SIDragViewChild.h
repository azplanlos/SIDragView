//
//  SIDragViewChild.h
//  exchangeExport
//
//  Created by Andreas Zöllner on 12.08.16.
//  Copyright (c) 2016 Studio Istanbul. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SIDragView;

@interface SIDragViewChild : NSView {
    BOOL dragging;
}

@property (strong) id userObject;
@property (strong) SIDragView* parentView;
@property (assign, nonatomic) NSInteger positionIndex;
@property (assign) NSInteger currentPos;

@end
