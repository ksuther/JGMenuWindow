
#import "DetectingTableView.h"
#import "RoundWindowFrameView.h"

@implementation DetectingTableView

- (void)mouseDown:(NSEvent *)event {
	// Pass it on to window controller view
	[(RoundWindowFrameView *)[[[self window] contentView] superview] mouseDownInTableViewWithEvent:event];
//	[super mouseDown:event];
}

@end