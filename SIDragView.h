//
//  SIDragView.h
//  exchangeExport
//
//  Created by Andreas Zöllner on 12.08.16.
//  Copyright (c) 2016 Studio Istanbul. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SIDragViewChild.h"

@interface SIDragView : NSView

-(NSSize)gridSize;
-(NSSize)minViewSize;
-(NSInteger)numberOfColumns;
-(NSInteger)numberOfRows;

-(void)addChildView:(SIDragViewChild*)childView;
-(void)removeChildView:(SIDragViewChild*)childView;
-(void)arrangeToGrid;

-(NSArray*)sortedChilds;
-(NSArray*)sortedUserObjects;

-(void)startDragForView:(SIDragViewChild*)childView;
-(void)stopDragForView:(SIDragViewChild*)childView;

-(NSPoint)pointForChild:(SIDragViewChild*)child andPos:(NSInteger)indexpos;
-(NSInteger)positionIndexForPoint:(NSPoint)point;

-(void)updateDragPos:(NSPoint)dragPoint;

-(id)childWithUserObject:(id)userObject;

-(void)removeAllChilds;

@property (readonly) BOOL isDragging;
@end
