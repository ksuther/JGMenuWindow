//
//  JGMenuWindowController.m
//  StatusItem
//
//  Created by Joshua Garnham on 15/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JGMenuWindowController.h"

@implementation JGMenuWindowController
@synthesize itemsTable, _headerView, menuDelegate;
@dynamic menuItems, headerView;

- (id)initWithWindowNibName:(NSString *)windowNibName {
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
		// Set up status item
	    NSStatusBar *bar = [NSStatusBar systemStatusBar];
		
		statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
		[statusItem retain];
		
		customStatusView = [[CustomStatusItemView alloc] initWithFrame:NSMakeRect(0, 0, 30, 20)];
		[customStatusView setTarget:self];
		[customStatusView setSelectingAction:@selector(statusItemSelected:)];
		[customStatusView setDeselectingAction:@selector(statusItemDeselected:)];
		[statusItem setView:customStatusView];
		
		[(RoundWindowFrameView *)[[self.window contentView] superview] setTableDelegate:self];
		
		[[self window] setDelegate:self];
	}
	return self;
}


+ (NSString *)seperatorItem {
	return @"--[SEPERATOR]--";
}

#pragma mark Handling changes to the window

- (void)closeWindow {
    timer = [[NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(fade:) userInfo:nil repeats:YES] retain];
	[customStatusView setHighlighted:NO];
}

- (void)fade:(NSTimer *)theTimer
{
    if ([self.window alphaValue] > 0.0) {
        // If window is still partially opaque, reduce its opacity.
        [self.window setAlphaValue:[self.window alphaValue] - 0.3];
    } else {
        // Otherwise, if window is completely transparent, destroy the timer and close the window.
        [timer invalidate];
        [timer release];
        timer = nil;
        
        [self.window close];
        
        // Make the window fully opaque again for next time.
        [self.window setAlphaValue:1.0];
    }
}

#pragma mark Handling changes to menuItems and headerView

- (NSArray *)menuItems {
	return menuItems;
}

- (void)setMenuItems:(NSArray *)items {
	menuItems = [items copy];
	
	// Work out headerView sizing based on string size
	if (headerView == nil) {
		float width = 0;
		for (NSString *string in menuItems) {
			NSSize size = [string sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName: @"Lucida Grande" size: 13] forKey:NSFontAttributeName]];
			if (size.width + 50 > width)
				width = size.width + 50;
		}
		headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, 0)];	
	}	

	[itemsTable reloadData];
	[self loadHeights];
}

- (NSView *)headerView {
	return headerView;
}

- (void)setHeaderView:(NSView *)view {
	headerView = view;
	[self loadHeights];
}

#pragma mark Handling the Status Item

- (void)loadHeights {	
	NSRect newFrame = [[customStatusView window] frame];
	
	// Work out the _headerView's (basically a container) frame from the actually headerView frame
	
	NSRect _headerViewOldFrame = _headerView.frame;
	_headerViewOldFrame.origin.x = 0;
	_headerViewOldFrame.origin.y = self.window.frame.size.height - headerView.frame.size.height;
	_headerViewOldFrame.size.height = headerView.frame.size.height;
	_headerViewOldFrame.size.width = headerView.frame.size.width;
	[_headerView setFrame:_headerViewOldFrame];

	NSRect headerViewOldFrame = headerView.frame;
	headerViewOldFrame.origin.x = 0;
	headerViewOldFrame.origin.y = 0;
	[headerView setFrame:headerViewOldFrame];
	
	// Add the headerView as a subview to the container
	
	[_headerView addSubview:headerView];
	
	// Work out the height of the cells in the table view
	
	int sizeOfCellsInTableView = 0;
	
//	if ([menuItems count] != 0) {
//		sizeOfCellsInTableView = (20 * [menuItems count]) + 6;
//	}
	
	for (NSString *string in menuItems) {
		if ([string isEqualToString:@"--[SEPERATOR]--"]) {
			sizeOfCellsInTableView = sizeOfCellsInTableView + 12;
		} else {
			sizeOfCellsInTableView = sizeOfCellsInTableView + 20;
		}
	}
	
	if ([menuItems count] != 0)
		sizeOfCellsInTableView = sizeOfCellsInTableView + 6;
	
	// Adjust what will be window frame
			
	newFrame.size.width = headerView.frame.size.width;
	newFrame.size.height = sizeOfCellsInTableView + headerView.frame.size.height;
	newFrame.origin.y = newFrame.origin.y - (sizeOfCellsInTableView + headerView.frame.size.height);
	newFrame.origin.x = newFrame.origin.x;
	
	// Decide which side to draw the menu
	
	CGFloat xOrigin = newFrame.origin.x;
	
	BOOL whichSide = 0; // 0 = shown to the right, 1 = shown to the left
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect statusItemRect = [[customStatusView window] frame];
		
	if ((statusItemRect.origin.x + headerView.frame.size.width) > screenRect.size.width)
		whichSide = 1;
		
	if (whichSide) {
		xOrigin = xOrigin - self.window.frame.size.width + customStatusView.frame.size.width;
	}
	
	newFrame.origin.x = xOrigin;
	
	// Set the windows frame
	
	[self.window setFrame:newFrame display:YES];
	
	// Adjust Table view frame, has to be done after window frame change other wise there are some complications with autoresizing
	
	if ([menuItems count] != 0) {
		NSRect tableOldFrame = itemsTable.frame;
		tableOldFrame.origin.x = 0;
		//	if (headerView.size.height = 0)
		tableOldFrame.origin.y = -2;
		tableOldFrame.size.height = sizeOfCellsInTableView;
		tableOldFrame.size.width = headerView.frame.size.width;
		[itemsTable setFrame:tableOldFrame];
		[[[itemsTable superview] superview] setFrame:tableOldFrame];
	}
}

- (void)statusItemDeselected:(id)sender {
	[self closeWindow];
}

- (void)statusItemSelected:(id)sender {
	[self loadHeights];
	[self.window makeKeyAndOrderFront:self];
	[customStatusView setHighlighted:YES];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

#pragma mark TableDetectionDelegate

- (void)mouseMovedIntoLocation:(NSPoint)loc {
	mouseOverRow = [itemsTable rowAtPoint:[itemsTable convertPoint:loc fromView:nil]];
	[itemsTable reloadData];
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [menuItems count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[menuItems objectAtIndex:rowIndex] isEqualToString:@"--[SEPERATOR]--"])
		return @"";
	return [menuItems objectAtIndex:rowIndex];
}

#pragma mark NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)rowIndex {
	if ([[menuItems objectAtIndex:rowIndex] isEqualToString:@"--[SEPERATOR]--"])
		return 10;
	return 18;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	if ([menuDelegate respondsToSelector:@selector(didSelectMenuItemAtIndex:)])
		[menuDelegate didSelectMenuItemAtIndex:rowIndex];	
	return NO;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{	
	if ([[menuItems objectAtIndex:rowIndex] isEqualToString:@"--[SEPERATOR]--"]) {
		NSRect rowRect = [aTableView rectOfRow:rowIndex];
		rowRect.origin.x = 1;
		rowRect.origin.y += (int) (NSHeight(rowRect)/2);
		rowRect.size.width = rowRect.size.width - 2;
		rowRect.size.height = 1.0;
		[[NSColor colorWithDeviceWhite:0.871 alpha:1.000] set];
		NSRectFill(rowRect);
		return;
	}
	
	if (mouseOverRow == rowIndex && ([aTableView selectedRow] != rowIndex)) {
		if ([aTableView lockFocusIfCanDraw]) {
			NSRect rowRect = [aTableView rectOfRow:rowIndex];
			NSRect columnRect = [aTableView rectOfColumn:[[aTableView tableColumns] indexOfObject:aTableColumn]];
			
			NSGradient* aGradient =
			[[[NSGradient alloc]
			  initWithColorsAndLocations:
			  [NSColor colorWithDeviceRed:0.416 green:0.529 blue:0.961 alpha:1.000], (CGFloat)0.0,
			  [NSColor colorWithDeviceRed:0.212 green:0.365 blue:0.949 alpha:1.000], (CGFloat)1.0,
			  nil]
			 autorelease];
			NSRect rectToDraw = NSIntersectionRect(rowRect, columnRect);
			rectToDraw.size.height = 19;
			rectToDraw.origin.y = rectToDraw.origin.y + 1;
			[aGradient drawInRect:rectToDraw angle:90];
			[aTableView unlockFocus];
			
			[aCell setTextColor:[NSColor selectedMenuItemTextColor]];
		}
	} else {
		[aCell setTextColor:[NSColor blackColor]];
	}
}

@end