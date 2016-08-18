//
//  SIDragView.m
//  exchangeExport
//
//  Created by Andreas Zöllner on 12.08.16.
//  Copyright (c) 2016 Studio Istanbul. All rights reserved.
//

#import "SIDragView.h"
#import "NSArray+ArrayForKeypath.h"

@interface SIDragView () {
    NSView* dragView;
    NSView* gridView;
}

@end

@implementation SIDragView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        dragView = [[NSView alloc] initWithFrame:frame];
        gridView = [[NSView alloc] initWithFrame:frame];
        [self addSubview:gridView];
        [self addSubview:dragView];
        isDragging = NO;
    }
    return self;
}

-(void)dealloc {
    for (SIDragViewChild* child in [gridView.subviews arrayByAddingObjectsFromArray:dragView.subviews]) {
        [self removeChildView:child];
    }
    [dragView removeFromSuperview];
    [gridView removeFromSuperview];
    dragView = nil;
    gridView = nil;
}

- (void)drawRect:(NSRect)dirtyRect
{
    //// Color Declarations
    NSColor* color = [NSColor colorWithCalibratedRed: 0.833 green: 0.833 blue: 0.833 alpha: 1];
    NSColor* color2 = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// Shadow Declarations
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [[NSColor blackColor] colorWithAlphaComponent: 0.72]];
    [shadow setShadowOffset: NSMakeSize(-2.1, -3.1)];
    [shadow setShadowBlurRadius: 6];
    NSShadow* shadow2 = [[NSShadow alloc] init];
    [shadow2 setShadowColor: color2];
    [shadow2 setShadowOffset: NSMakeSize(2.1, 2.1)];
    [shadow2 setShadowBlurRadius: 2];
    
    //// Frames
    NSRect frame = self.bounds;
    
    /*
    //// Rounded Rectangle Drawing
    NSBezierPath* roundedRectanglePath = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(NSMinX(frame) - 0.5, NSMinY(frame) - 0.5, NSWidth(frame) - 7, NSHeight(frame)) xRadius: 8 yRadius: 8];
    [NSGraphicsContext saveGraphicsState];
    [shadow2 set];
    [color setFill];
    [roundedRectanglePath fill];
    
    ////// Rounded Rectangle Inner Shadow
    NSRect roundedRectangleBorderRect = NSInsetRect([roundedRectanglePath bounds], -shadow.shadowBlurRadius, -shadow.shadowBlurRadius);
    roundedRectangleBorderRect = NSOffsetRect(roundedRectangleBorderRect, -shadow.shadowOffset.width, -shadow.shadowOffset.height);
    roundedRectangleBorderRect = NSInsetRect(NSUnionRect(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1, -1);
    
    NSBezierPath* roundedRectangleNegativePath = [NSBezierPath bezierPathWithRect: roundedRectangleBorderRect];
    [roundedRectangleNegativePath appendBezierPath: roundedRectanglePath];
    [roundedRectangleNegativePath setWindingRule: NSEvenOddWindingRule];
    
    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* shadowWithOffset = [shadow copy];
        CGFloat xOffset = shadowWithOffset.shadowOffset.width + round(roundedRectangleBorderRect.size.width);
        CGFloat yOffset = shadowWithOffset.shadowOffset.height;
        shadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [shadowWithOffset set];
        [[NSColor grayColor] setFill];
        [roundedRectanglePath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: -round(roundedRectangleBorderRect.size.width) yBy: 0];
        [[transform transformBezierPath: roundedRectangleNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
    
    [NSGraphicsContext restoreGraphicsState];
    */
    [NSGraphicsContext saveGraphicsState];
    NSSize grid = [self gridSize];
    for (int x = grid.width; x < self.bounds.size.width-7; x += grid.width) {
        //// Bezier Drawing
        NSBezierPath* bezierPath = [NSBezierPath bezierPath];
        [bezierPath moveToPoint: NSMakePoint(NSMinX(frame) + x, NSMaxY(frame) - 2.5)];
        [bezierPath lineToPoint: NSMakePoint(NSMinX(frame) + x, NSMinY(frame))];
        [color2 setStroke];
        [bezierPath setLineWidth: 1];
        CGFloat bezierPattern[] = {2, 2, 2, 2};
        [bezierPath setLineDash: bezierPattern count: 4 phase: 0];
        [bezierPath stroke];
    }
    for (int y = grid.height + 10; y < self.bounds.size.height-1; y += grid.height) {
        //// Bezier Drawing
        NSBezierPath* bezierPath = [NSBezierPath bezierPath];
        [bezierPath moveToPoint: NSMakePoint(NSMinX(frame), NSMaxY(frame) - y)];
        [bezierPath lineToPoint: NSMakePoint([self numberOfColumns] * grid.width, NSMaxY(frame) - y)];
        [color2 setStroke];
        [bezierPath setLineWidth: 1];
        CGFloat bezierPattern[] = {2, 2, 2, 2};
        [bezierPath setLineDash: bezierPattern count: 4 phase: 0];
        [bezierPath stroke];
    }

    [NSGraphicsContext restoreGraphicsState];
    
}

-(NSInteger)numberOfColumns {
    NSSize gridSize = [self gridSize];
    return (NSInteger)self.bounds.size.width / (NSInteger)gridSize.width;
}

-(NSInteger)numberOfRows {
    double num = ((double)gridView.subviews.count + (double)dragView.subviews.count) / (double)self.numberOfColumns;
    int rem = fmod(num, 1);
    if (rem > 0) num++;
    return num;
}

-(NSSize)gridSize {
    if (gridView.subviews.count == 0) return NSMakeSize(100, 100);
    double maxWidth = 0;
    double maxHeight = 0;
    for (NSView* subview in [gridView.subviews arrayByAddingObjectsFromArray:dragView.subviews]) {
        if (subview.frame.size.width > maxWidth) maxWidth = subview.frame.size.width;
        if (subview.frame.size.height > maxHeight) maxHeight = subview.frame.size.height;
    }
    return NSMakeSize(maxWidth + 5, maxHeight + 5);
}

-(NSSize)minViewSize {
    if (gridView.subviews.count == 0) return NSMakeSize(10, 10);
    NSSize gridsize = [self gridSize];
    double width = ([self numberOfColumns] * gridsize.width) + 5;
    double height = ([self numberOfRows] * gridsize.height)+10;
    if (width < self.superview.bounds.size.width-10) width = self.superview.bounds.size.width-10;
    if (height < self.superview.bounds.size.height-10) height = self.superview.bounds.size.height - 10;
    return NSMakeSize(width, height);
}

-(void)arrangeToGrid {
    int viewNum = 0;
    for (SIDragViewChild* subview in [[gridView.subviews arrayByAddingObjectsFromArray:dragView.subviews] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"positionIndex" ascending:YES]]]) {
        [subview setFrameOrigin:[self pointForChild:subview andPos:viewNum]];
        subview.positionIndex = viewNum;
        viewNum++;
    };
}

-(NSPoint)pointForChild:(SIDragViewChild*)child andPos:(NSInteger)indexpos {
    NSSize gridSize = [self gridSize];
    NSInteger numberOfCols = [self numberOfColumns];
    if (numberOfCols != 0) {
        NSInteger row = indexpos / numberOfCols;
        NSInteger col = indexpos - (row * numberOfCols);
        NSPoint myPoint = NSMakePoint(col * (gridSize.width) + ((gridSize.width - child.bounds.size.width)/2), self.bounds.size.height - (10 + (row * gridSize.height) + child.bounds.size.height + (gridSize.height - child.bounds.size.height) / 2));
        return myPoint;
    }
    return NSZeroPoint;
}

-(NSInteger)positionIndexForPoint:(NSPoint)point {
    NSSize gridSize = [self gridSize];
    NSInteger numberOfCols = [self numberOfColumns];
    NSInteger row = (NSInteger)(((NSInteger)self.bounds.size.height - 10 - ((NSInteger)point.y - (self.gridSize.height/2)) - self.gridSize.height) / (NSInteger)gridSize.height);
    //NSInteger difToGrid = (self.bounds.size.height - point.y) - (self.bounds.size.height - 10 - (row+1 * gridSize.height));
    //if (difToGrid > -(gridSize.height/2)) row++;
    NSInteger col = (NSInteger)point.x / (NSInteger)gridSize.width;
    if (point.x + (gridSize.width/2) > (col+1) * gridSize.width) col++;
    NSInteger posNum = row * numberOfCols + col;
    //NSLog(@"position for point %f/%f = %li (row %li, col %li) diff %li", point.x, point.y, posNum, row, col, difToGrid);
    return posNum;
}

-(void)setFrame:(NSRect)frameRect {
    [super setFrame:frameRect];
    [gridView setFrame:NSMakeRect(0, 0, frameRect.size.width - 7, frameRect.size.height-2)];
    [dragView setFrame:NSMakeRect(0, 0, frameRect.size.width - 7, frameRect.size.height-2)];
    [self arrangeToGrid];
}

-(void)addChildView:(SIDragViewChild *)childView {
    childView.parentView = self;
    [gridView addSubview:childView];
    if (childView.positionIndex < 0) childView.positionIndex = gridView.subviews.count - 1;
    [childView addObserver:self forKeyPath:@"currentPos" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self setNeedsDisplay:YES];
}

-(void)removeChildView:(SIDragViewChild *)childView {
    childView.parentView = nil;
    [childView removeFromSuperview];
    [childView removeObserver:self forKeyPath:@"currentPos"];
    [self arrangeToGrid];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[SIDragViewChild class]]) {
        NSInteger oldIndex = [[change valueForKey:NSKeyValueChangeOldKey] integerValue];
        NSInteger newIndex = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
        if (abs(oldIndex-newIndex) <= 1) [self animateMoveChild:[self childAtPosition:newIndex] toPos:oldIndex]; else {
            if (oldIndex-newIndex < 0) {
                // forwards
                [self animateMoveChildsFromIndex:oldIndex+1 toIndex:newIndex forSteps:-1];
            } else {
                // backwards
                [self animateMoveChildsFromIndex:newIndex toIndex:oldIndex-1 forSteps:1];
            }
        }
    }
}

-(SIDragViewChild*)childAtPosition:(NSInteger)position {
    SIDragViewChild* retChild = nil;
    for (SIDragViewChild* child in [gridView.subviews arrayByAddingObjectsFromArray:dragView.subviews]) {
        if (child.positionIndex == position) retChild = child;
    }
    return retChild;
}

-(void)animateMoveChildsFromIndex:(NSInteger)startIndex toIndex:(NSInteger)stopIndex forSteps:(NSInteger)steps {
    NSInteger dir = startIndex - stopIndex;
    if (dir >= 0) dir = 1; else dir = -1;
    NSMutableArray* childs = [NSMutableArray arrayWithCapacity:abs(startIndex-stopIndex)];
    if (dir > 0) {
        for (NSInteger i = startIndex; i <= stopIndex; i += dir) {
            SIDragViewChild* child = [self childAtPosition:i];
            if (child) [childs addObject:[self childAtPosition:i]];
        }
    } else {
        for (NSInteger i = stopIndex; i >= startIndex; i += dir) {
            SIDragViewChild* child = [self childAtPosition:i];
            if (child) [childs addObject:[self childAtPosition:i]];        }
    }
    for (SIDragViewChild* child in childs) {
        [self animateMoveChild:child toPos:child.positionIndex+steps];
    }
}
         
-(void)animateMoveChild:(SIDragViewChild*)child toPos:(NSInteger)newIndex {
    [[NSAnimationContext currentContext] setDuration:0.2];
    [[child animator] setFrameOrigin:[self pointForChild:child andPos:newIndex]];
    child.positionIndex = newIndex;
}

-(void)startDragForView:(SIDragViewChild *)childView {
    if (childView.superview != dragView && !isDragging) {
        isDragging = YES;
        [childView removeFromSuperview];
        [dragView addSubview:childView];
#if defined __DEBUG__
        NSLog(@"start drag #%li", childView.positionIndex);
#endif
    }
}

-(void)stopDragForView:(SIDragViewChild *)childView {
    if (childView.superview != gridView) {
#if defined __DEBUG__
        NSLog(@"stop drag #%li", childView.positionIndex);
#endif
        isDragging = NO;
        [childView removeFromSuperview];
        [gridView addSubview:childView];
    }
}

-(NSArray*)sortedChilds {
    NSArray* objs = [[gridView.subviews arrayByAddingObjectsFromArray:dragView.subviews] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"positionIndex" ascending:YES]]];
    return objs;
}

-(NSArray*)sortedUserObjects {
    NSArray* objs = [self.sortedChilds arrayForValuesWithKey:@"userObject"];
    return objs;
}

@synthesize isDragging;
@end
