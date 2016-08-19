//
//  SIDragViewChild.m
//  exchangeExport
//
//  Created by Andreas Zöllner on 12.08.16.
//  Copyright (c) 2016 Studio Istanbul. All rights reserved.
//

#import "SIDragViewChild.h"
#import "SIDragView.h"

@interface SIDragViewChild () {
    NSTrackingRectTag* trackingRectTag;
    BOOL mouseInside;
}

@property NSPoint lastDragLocation;

@end

@implementation SIDragViewChild

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        dragging = NO;
        trackingRectTag = [self addTrackingRect:frame owner:self userData:NULL assumeInside:NO];
        self.positionIndex = -1;
        mouseInside = NO;
    }
    
    return self;
}

-(void)dealloc {
    self.userObject = nil;
    self.parentView = nil;
}

- (void)drawRect:(NSRect)dirtyRect
{//// Color Declarations
    NSColor* color = [NSColor colorWithCalibratedRed: 0.667 green: 0.667 blue: 0.667 alpha: 1];
    NSColor* color2 = [NSColor colorWithCalibratedRed: 0.833 green: 0.833 blue: 0.833 alpha: 1];
    NSColor* gradientColor = [NSColor colorWithCalibratedRed: 0.882 green: 0.882 blue: 0.882 alpha: 1];
    NSColor* color3 = [NSColor colorWithCalibratedRed: 1 green: 1 blue: 1 alpha: 1];
    
    //// Gradient Declarations
    NSGradient* gradient = [[NSGradient alloc] initWithStartingColor: gradientColor endingColor: color2];
    
    //// Shadow Declarations
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor: [color3 colorWithAlphaComponent: 0.66]];
    [shadow setShadowOffset: NSMakeSize(-3.1, -3.1)];
    [shadow setShadowBlurRadius: 4];
    
    //// Frames
    NSRect frame = self.bounds;
    
    
    //// Rectangle Drawing
    NSBezierPath* rectanglePath = [NSBezierPath bezierPathWithRoundedRect: NSMakeRect(NSMinX(frame) + 1, NSMinY(frame) + 1, NSWidth(frame) - 2, NSHeight(frame) - 2) xRadius: 7 yRadius: 7];
    [gradient drawInBezierPath: rectanglePath angle: -90];
    
    ////// Rectangle Inner Shadow
    NSRect rectangleBorderRect = NSInsetRect([rectanglePath bounds], -shadow.shadowBlurRadius, -shadow.shadowBlurRadius);
    rectangleBorderRect = NSOffsetRect(rectangleBorderRect, -shadow.shadowOffset.width, -shadow.shadowOffset.height);
    rectangleBorderRect = NSInsetRect(NSUnionRect(rectangleBorderRect, [rectanglePath bounds]), -1, -1);
    
    NSBezierPath* rectangleNegativePath = [NSBezierPath bezierPathWithRect: rectangleBorderRect];
    [rectangleNegativePath appendBezierPath: rectanglePath];
    [rectangleNegativePath setWindingRule: NSEvenOddWindingRule];
    
    [NSGraphicsContext saveGraphicsState];
    {
        NSShadow* shadowWithOffset = [shadow copy];
        CGFloat xOffset = shadowWithOffset.shadowOffset.width + round(rectangleBorderRect.size.width);
        CGFloat yOffset = shadowWithOffset.shadowOffset.height;
        shadowWithOffset.shadowOffset = NSMakeSize(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset));
        [shadowWithOffset set];
        [[NSColor grayColor] setFill];
        [rectanglePath addClip];
        NSAffineTransform* transform = [NSAffineTransform transform];
        [transform translateXBy: -round(rectangleBorderRect.size.width) yBy: 0];
        [[transform transformBezierPath: rectangleNegativePath] fill];
    }
    [NSGraphicsContext restoreGraphicsState];
    
    [color setStroke];
    [rectanglePath setLineWidth: 1.5];
    CGFloat rectanglePattern[] = {2, 2, 2, 2};
    [rectanglePath setLineDash: rectanglePattern count: 4 phase: 0];
    [rectanglePath stroke];
    
#if defined __DEBUG__
    [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"#%li/%li", self.positionIndex, currentPos]] drawAtPoint:NSMakePoint(5, 5)];
#endif

}

// -------------------- MOUSE EVENTS ------------------- \\

- (BOOL) acceptsFirstMouse:(NSEvent *)e {
    return YES;
}

-(void)mouseEntered:(NSEvent *)theEvent {
    if (!self.parentView.isDragging) [self.parentView startDragForView:self];
    mouseInside = YES;
}

-(void)mouseExited:(NSEvent *)theEvent {
    if (!dragging) [self.parentView stopDragForView:self];
    mouseInside = NO;
}

- (void)mouseDown:(NSEvent *) e {
    // Convert to superview's coordinate space
    if (!dragging) {
        self.lastDragLocation = [self.superview convertPoint:[e locationInWindow] fromView:nil];
        [self.parentView startDragForView:self];
    }
    dragging = YES;
}

static NSComparisonResult myCustomViewAboveSiblingViewsComparator( NSView * view1, NSView * view2, void * context )
{
    if ((view1 = (__bridge NSView *)(context)))
        return NSOrderedAscending;
    else if ((view2 = (__bridge NSView *)(context)))
        return NSOrderedDescending;
    
    return NSOrderedAscending;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (dragging) {
        // We're working only in the superview's coordinate space, so we always convert.
        NSPoint newDragLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
        NSPoint thisOrigin = [self frame].origin;
        thisOrigin.x += (-self.lastDragLocation.x + newDragLocation.x);
        thisOrigin.y += (-self.lastDragLocation.y + newDragLocation.y);
        if (thisOrigin.x < 0) thisOrigin.x = 0;
        if (thisOrigin.y < 0) thisOrigin.y = 0;
        if (thisOrigin.x + self.bounds.size.width > self.superview.bounds.size.width) thisOrigin.x = self.superview.bounds.size.width - self.bounds.size.width;
        if (thisOrigin.y + self.bounds.size.height > self.superview.bounds.size.height) thisOrigin.y = self.superview.bounds.size.height - self.bounds.size.height;
        [self setFrameOrigin:thisOrigin];
        self.lastDragLocation = newDragLocation;
        
        NSInteger xcurrentPos = [self.parentView positionIndexForPoint:thisOrigin];
        if (xcurrentPos != self.currentPos) self.currentPos = xcurrentPos;
        
        [self.parentView updateDragPos:thisOrigin];
        
#if defined __DEBUG__
        [self setNeedsDisplay:YES];
#endif
    }
}

-(void)setFrameOrigin:(NSPoint)newOrigin {
    [super setFrameOrigin:newOrigin];
    [self removeTrackingRect:trackingRectTag];
    trackingRectTag = [self addTrackingRect:self.bounds owner:self userData:NULL assumeInside:mouseInside]
    ;
}

-(void)mouseUp:(NSEvent *)theEvent {
    // snap to grid
    //[self.parentView stopDragForView:self];
    if (dragging) {
        dragging = NO;
        NSPoint newDragLocation = [[self superview] convertPoint:[theEvent locationInWindow] fromView:nil];
        NSPoint thisOrigin = [self frame].origin;
        thisOrigin.x += (-self.lastDragLocation.x + newDragLocation.x);
        thisOrigin.y += (-self.lastDragLocation.y + newDragLocation.y);
        NSInteger posNum = [self.parentView positionIndexForPoint:thisOrigin];
        self.positionIndex = posNum;
        currentPos = posNum;
        [self setFrameOrigin:[self.parentView pointForChild:self andPos:posNum]];
        //[self.parentView stopDragForView:self];
        [self.parentView arrangeToGrid];
#if defined __DEBUG__
        NSLog(@"sorted: %@", [self.parentView sortedUserObjects]);
#endif
    }
}

-(void)setPositionIndex:(NSInteger)positionIndex {
    currentPos = positionIndex;
    _positionIndex = positionIndex;
}

@synthesize currentPos, positionIndex = _positionIndex;

@end
