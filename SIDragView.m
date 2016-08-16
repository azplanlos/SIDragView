//
//  SIDragView.m
//  exchangeExport
//
//  Created by Andreas Zöllner on 12.08.16.
//  Copyright (c) 2016 Studio Istanbul. All rights reserved.
//

#import "SIDragView.h"

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
        [bezierPath moveToPoint: NSMakePoint(NSMinX(frame) + 2, NSMaxY(frame) - y)];
        [bezierPath lineToPoint: NSMakePoint(NSMaxX(frame) - 10, NSMaxY(frame) - y)];
        [color2 setStroke];
        [bezierPath setLineWidth: 1];
        CGFloat bezierPattern[] = {2, 2, 2, 2};
        [bezierPath setLineDash: bezierPattern count: 4 phase: 0];
        [bezierPath stroke];
    }

    [NSGraphicsContext restoreGraphicsState];
    
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

-(void)arrangeToGrid {
    int viewNum = 0;
    for (SIDragViewChild* subview in [gridView.subviews sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"positionIndex" ascending:YES]]]) {
        [subview setFrameOrigin:[self pointForChild:subview andPos:viewNum]];
        subview.positionIndex = viewNum;
        viewNum++;
    };
}

-(NSPoint)pointForChild:(SIDragViewChild*)child andPos:(NSInteger)indexpos {
    NSSize gridSize = [self gridSize];
    NSPoint myPoint = NSMakePoint(indexpos * (gridSize.width) + ((gridSize.width - child.bounds.size.width)/2), self.bounds.size.height - (10 + child.bounds.size.height + (gridSize.height - child.bounds.size.height) / 2));
    return myPoint;
}

-(NSInteger)positionIndexForPoint:(NSPoint)point {
    NSSize gridSize = [self gridSize];
    NSInteger posNum = (NSInteger)point.x / (NSInteger)gridSize.width;
    if (point.x + (gridSize.width/2) > (posNum+1) * gridSize.width) posNum++;
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
        [self animateMoveChild:[self childAtPosition:newIndex] toPos:oldIndex];
    }
}

-(SIDragViewChild*)childAtPosition:(NSInteger)position {
    SIDragViewChild* retChild = nil;
    for (SIDragViewChild* child in [gridView.subviews arrayByAddingObjectsFromArray:dragView.subviews]) {
        if (child.positionIndex == position) retChild = child;
    }
    return retChild;
}
         
-(void)animateMoveChild:(SIDragViewChild*)child toPos:(NSInteger)newIndex {
    [[NSAnimationContext currentContext] setDuration:0.3];
    [[child animator] setFrameOrigin:[self pointForChild:child andPos:newIndex]];
    child.positionIndex = newIndex;
}

-(void)startDragForView:(SIDragViewChild *)childView {
    if (childView.superview != dragView && !isDragging) {
        isDragging = YES;
        [childView removeFromSuperview];
        [dragView addSubview:childView];
    }
}

-(void)stopDragForView:(SIDragViewChild *)childView {
    if (childView.superview != gridView) {
        isDragging = NO;
        [childView removeFromSuperview];
        [gridView addSubview:childView];
    }
}


@synthesize isDragging;
@end
