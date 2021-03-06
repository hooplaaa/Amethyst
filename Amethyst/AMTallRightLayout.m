//
//  AMTallRightLayout.m
//  
//
//  Created by Shayne Sweeney on 7/6/15.
//
//

#import "AMTallRightLayout.h"

#import "AMReflowOperation.h"
#import "AMWindowManager.h"

@interface AMTallRightReflowOperation : AMReflowOperation
- (instancetype)initWithScreen:(NSScreen *)screen windows:(NSArray *)windows layout:(AMTallRightLayout *)layout;
@property (nonatomic, strong) AMTallRightLayout *layout;
@end

@interface AMTallRightLayout ()
// Ratio of screen width taken up by main pane
@property (nonatomic, assign) CGFloat mainPaneRatio;
// The number of windows that should be displayed in the main pane.
@property (nonatomic, assign) NSInteger mainPaneCount;
@end

@implementation AMTallRightLayout

#pragma mark Lifecycle

- (id)init {
    self = [super init];
    if (self) {
        self.mainPaneCount = 1;
        self.mainPaneRatio = 0.5;
    }
    return self;
}

#pragma mark AMLayout

+ (NSString *)layoutName {
    return @"Tall Right";
}

- (NSOperation *)reflowOperationForScreen:(NSScreen *)screen withWindows:(NSArray *)windows {
    return [[AMTallRightReflowOperation alloc] initWithScreen:screen windows:windows layout:self];
}

- (void)expandMainPane {
    self.mainPaneRatio = MAX(0, self.mainPaneRatio - 0.05);

}

- (void)shrinkMainPane {
    self.mainPaneRatio = MIN(1, self.mainPaneRatio + 0.05);
}

- (void)increaseMainPaneCount {
    self.mainPaneCount = self.mainPaneCount + 1;
}

- (void)decreaseMainPaneCount {
    self.mainPaneCount = MAX(1, self.mainPaneCount - 1);
}

@end

@implementation AMTallRightReflowOperation

- (instancetype)initWithScreen:(NSScreen *)screen windows:(NSArray *)windows layout:(AMTallRightLayout *)layout {
    self = [super initWithScreen:screen windows:windows];
    if (self) {
        self.layout = layout;
    }
    return self;
}

- (void)main {
    if (self.windows.count == 0) return;

    NSMutableArray *frameAssignments = [NSMutableArray array];
    NSUInteger mainPaneCount = MIN(self.windows.count, self.layout.mainPaneCount);
    
    NSInteger secondaryPaneCount = self.windows.count - mainPaneCount;
    BOOL hasSecondaryPane = (secondaryPaneCount > 0);
    
    CGRect screenFrame = [self adjustedFrameForLayout:self.screen];
    
    CGFloat mainPaneWindowHeight = round(screenFrame.size.height / mainPaneCount);
    CGFloat secondaryPaneWindowHeight = (hasSecondaryPane ? round(screenFrame.size.height / secondaryPaneCount) : 0.0);
    
    CGFloat mainPaneWindowWidth = round(screenFrame.size.width * (hasSecondaryPane ? self.layout.mainPaneRatio : 1));
    CGFloat secondaryPaneWindowWidth = screenFrame.size.width - mainPaneWindowWidth;
    
    SIWindow *focusedWindow = [SIWindow focusedWindow];

    for (NSUInteger windowIndex = 0; windowIndex < self.windows.count; ++windowIndex) {
        if (self.cancelled) {
            return;
        }
        SIWindow *window = self.windows[windowIndex];
        CGRect windowFrame;
        
        if (windowIndex < mainPaneCount) {
            windowFrame.origin.x = screenFrame.origin.x + secondaryPaneWindowWidth;
            windowFrame.origin.y = screenFrame.origin.y + (mainPaneWindowHeight * windowIndex);
            windowFrame.size.width = mainPaneWindowWidth;
            windowFrame.size.height = mainPaneWindowHeight;
        } else {
            windowFrame.origin.x = screenFrame.origin.x;
            windowFrame.origin.y = CGRectGetMaxY(screenFrame) - (secondaryPaneWindowHeight * (windowIndex - mainPaneCount + 1));
            windowFrame.size.width = secondaryPaneWindowWidth;
            windowFrame.size.height = secondaryPaneWindowHeight;
        }

        AMFrameAssignment *frameAssignment = [[AMFrameAssignment alloc] initWithFrame:windowFrame window:window focused:[window isEqualTo:focusedWindow] screenFrame:screenFrame];
        [frameAssignments addObject:frameAssignment];
    }

    [self performFrameAssignments:frameAssignments];
}

@end
