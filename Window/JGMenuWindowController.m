//
//  JGMenuWindowController.m
//  StatusItem
//
//  Created by Joshua Garnham on 15/04/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "JGMenuWindowController.h"
#import "NSColor+JGAdditions.h"

@interface JGMenuWindowController()

- (void)loadHeights;
- (BOOL)loadHeightsWithWindowOrigin:(NSPoint)origin whichIsSubmenu:(BOOL)isSubmenu;

@end

@implementation JGMenuWindowController
@synthesize itemsTable, _headerView, menuDelegate, proMode, canBecomeKey, parentMenu, mouseOverRow;
@dynamic menuItems, headerView, statusItemImage, statusItemAlternateImage, statusItemTitle, isStatusItem;

- (id)initWithWindowNibName:(NSString *)windowNibName {
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
		// Set delegates
		[(RoundWindowFrameView *)[[self.window contentView] superview] setTableDelegate:self];
		[[self window] setDelegate:self];
        [self setCanBecomeKey:YES];
		
		// Set up ivars
		mouseOverRow = -1;
	}
	return self;
}

#pragma mark Misc.

- (void)highlightMenuItemAtIndex:(NSInteger)rowIndex {
	mouseOverRow = rowIndex;
	[itemsTable reloadData];
    [itemsTable setNeedsDisplay:YES];
}

#pragma mark Opening menu without status items

- (void)popUpContextMenuAtPoint:(NSPoint)point {
	if (timer) { // Window shouldn't be closing right now. Stop the timer.
		[timer invalidate];
        [timer release];
        timer = nil;
		[self.window setAlphaValue:1.0]; 
	}
	
	[self loadHeightsWithWindowOrigin:point whichIsSubmenu:NO];
	[(RoundWindowFrameView *)[[self.window contentView] superview] setAllCornersRounded:YES];
	[(RoundWindowFrameView *)[[self.window contentView] superview] setProMode:proMode];
    [(BorderlessWindow *)self.window setAllowsKey:[self canBecomeKey]];
	[self.window makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)selectItemAtIndex:(NSInteger)index
{
    isSelecting = YES;
    [self resetMouseOverRowToAndClose:[NSNumber numberWithInt:index]];
    JGMenuItem *selectedItem = [menuItems objectAtIndex:index];
    [[selectedItem target] performSelector:[selectedItem action] withObject:selectedItem];
}

#pragma mark Dealing with submenu's

- (void)popUpSubmenuAtPoint:(NSPoint)point whichIsSide:(int)preferedSide {
	if (timer) { // Window shouldn't be closing right now. Stop the timer.
		[timer invalidate];
        [timer release];
        timer = nil;
		[self.window setAlphaValue:1.0]; 
	}
	
	BOOL side = ![self loadHeightsWithWindowOrigin:point whichIsSubmenu:YES]; // Returns 0 = right while we want 0 = left
    
	[(RoundWindowFrameView *)[[self.window contentView] superview] setIsSubmenuOnSide:side];
	[self setProMode:parentMenu.proMode]; // Respects parent's style
	[(RoundWindowFrameView *)[[self.window contentView] superview] setProMode:proMode]; 
    [(BorderlessWindow *)self.window setAllowsKey:[self canBecomeKey]];
	[self.window makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)displaySubmenuForRow:(NSNumber *)numRow {
	int row = [numRow intValue];
	
	if (mouseOverRow == row) {
		if (itemWithOpenSubmenu == nil) {
			JGMenuItem *item = [menuItems objectAtIndex:row];
			
			itemWithOpenSubmenu = item; // Do it before so as to ensure main menu does not close
			
			NSRect rectOfSubmenuRow = [itemsTable rectOfRow:row];
			NSRect windowConvert = [[self.window.contentView superview] convertRect:rectOfSubmenuRow fromView:itemsTable];
			NSRect screenConvert = NSMakeRect(self.window.frame.origin.x + windowConvert.origin.x, self.window.frame.origin.y + windowConvert.origin.y, rectOfSubmenuRow.size.width, rectOfSubmenuRow.size.height);
			
			[[item submenu] setParentMenu:self];
			[[item submenu] popUpSubmenuAtPoint:NSMakePoint(screenConvert.origin.x + self.window.frame.size.width, screenConvert.origin.y - 4) whichIsSide:0];
			
			[itemsTable reloadData];
		}
	}
}

#pragma mark Handling changes to the window

- (void)windowDidBecomeKey:(NSNotification *)notification {
	isMovingBackToParent = NO;	
}

- (void)windowDidResignKey:(NSNotification *)notification {
	if (itemWithOpenSubmenu != nil)
		return;
	else {
		[self closeWindow];
	}
}

- (void)closeWindow {
	if ([menuDelegate respondsToSelector:@selector(menuWillClose)])
		[menuDelegate menuWillClose];	
	
	if (parentMenu != nil && !isMovingBackToParent) {
	//	NSLog(@"close above menu");
		[parentMenu closeWindow];
	} 
	
    [self.window orderOut:nil];
	[customStatusView setHighlighted:NO];
}

#pragma mark Handling changes to menuItems and headerView

- (NSArray *)menuItems {
	return menuItems;
}

- (void)setMenuItems:(NSArray *)items {
	menuItems = [items copy];
	
	// Work out headerView sizing based on string size
    float width = 0;
    for (JGMenuItem *item in menuItems) {
        NSSize size = [item.title sizeWithAttributes:[NSDictionary dictionaryWithObject:[NSFont systemFontOfSize:12] forKey:NSFontAttributeName]];
        int amountToAdd = 40;
        if (item.submenu != nil)
            amountToAdd += 15;
        if (size.width + amountToAdd > width)
            width = size.width + amountToAdd;
    }
    
    CGFloat minWidth = [self minWidth];
    CGFloat maxWidth = [self maxWidth];
    
    if (minWidth > 0) {
        width = MAX(width, minWidth);
    }
    
    if (maxWidth > 0) {
        width = MIN(width, maxWidth);
    }
    
	if (headerView == nil) {
		headerView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, 0)];
	} else {
        NSRect headerRect = [headerView frame];
        headerRect.size.width = width;
        [headerView setFrame:headerRect];
    }

	[itemsTable reloadData];
}

- (NSView *)headerView {
	return headerView;
}

- (void)setHeaderView:(NSView *)view {
	headerView = view;
	[self loadHeights];
}

#pragma mark Handling changes to dynamic properties to be relayed to status item view

- (NSImage *)statusItemImage {
	return statusItemImage;
}

- (void)setStatusItemImage:(NSImage *)newImage
{
	if(newImage != statusItemImage)
	{
		[statusItemImage release];
		statusItemImage = [newImage copy];
		[customStatusView setImage:statusItemImage];
	}
}

- (NSImage *)statusItemAlternateImage {
	return statusItemAlternateImage;
}

- (void)setStatusItemAlternateImage:(NSImage *)newAltImage
{
	if(newAltImage != statusItemAlternateImage)
	{
		[statusItemAlternateImage release];
		statusItemAlternateImage = [newAltImage copy];
		[customStatusView setAlternateImage:statusItemAlternateImage];
	}
}

- (NSString *)statusItemTitle {
	return statusItemTitle;
}

- (void)setStatusItemTitle:(NSString *)newTitle
{
	if(newTitle != statusItemTitle)
	{
		[statusItemTitle release];
		statusItemTitle = [newTitle copy];
		[customStatusView setTitle:statusItemTitle];
	}
}

#pragma mark Handling the Status Item

- (BOOL)isStatusItem {
	return isStatusItem;
}

- (void)setIsStatusItem:(BOOL)flag {
	isStatusItem = flag;
	if (flag == NO) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
		[statusItem release];
		statusItem = nil;
		[customStatusView release];
		customStatusView = nil;
	} else {
		NSStatusBar *bar = [NSStatusBar systemStatusBar];
		
		statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
		[statusItem retain];
		
		customStatusView = [[CustomStatusItemView alloc] initWithFrame:NSMakeRect(0, 0, 30, 20)];
		[customStatusView setTarget:self];
		[customStatusView setSelectingAction:@selector(statusItemSelected:)];
		[customStatusView setDeselectingAction:@selector(statusItemDeselected:)];
		[customStatusView setStatusItem:statusItem];
		[statusItem setView:customStatusView];
	}
}

- (BOOL)loadHeightsWithWindowOrigin:(NSPoint)point whichIsSubmenu:(BOOL)isSubmenu {
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
	
	for (JGMenuItem *item in menuItems) {
		sizeOfCellsInTableView += [itemsTable rectOfRow:[menuItems indexOfObject:item]].size.height;
	}
	
	if ([menuItems count] != 0)
		sizeOfCellsInTableView = sizeOfCellsInTableView + 6;
	
	// Adjust what will be window frame
	
	newFrame.size.width = headerView.frame.size.width;
	newFrame.size.height = sizeOfCellsInTableView + headerView.frame.size.height;
	newFrame.origin.y = point.y;
	newFrame.origin.x = point.x;
	
	// Decide which side to draw the menu
	
	CGFloat xOrigin = newFrame.origin.x;
	
	BOOL whichSide = 0; // 0 = shown to the right, 1 = shown to the left
	NSRect screenRect = [[NSScreen mainScreen] frame];
	
	if ((newFrame.origin.x + newFrame.size.width) > screenRect.size.width)
		whichSide = 1;
	
	if (whichSide && isSubmenu && parentMenu != nil) {
		xOrigin = xOrigin - parentMenu.window.frame.size.width - newFrame.size.width;
	}
	
	newFrame.origin.x = xOrigin;
	
	// Set the windows frame
	
	[self.window setFrame:newFrame display:NO];
	
	// Adjust Table view frame, has to be done after window frame change other wise there are some complications with autoresizing
	
	if ([menuItems count] != 0) {
		NSRect tableOldFrame = itemsTable.frame;
		tableOldFrame.origin.x = 0;
		tableOldFrame.origin.y = 0;
		tableOldFrame.size.height = sizeOfCellsInTableView;
		tableOldFrame.size.width = headerView.frame.size.width;
		tableOldFrame = NSIntegralRect(tableOldFrame);
		[itemsTable setFrame:tableOldFrame];
		[[[itemsTable tableColumns] objectAtIndex:0] setWidth:tableOldFrame.size.width];
		[[[itemsTable superview] superview] setFrame:NSMakeRect(tableOldFrame.origin.x, tableOldFrame.origin.y - 3, tableOldFrame.size.width, tableOldFrame.size.height)];
	}
	
	return whichSide;
}

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
	
	for (JGMenuItem *item in menuItems) {
		sizeOfCellsInTableView += [itemsTable rectOfRow:[menuItems indexOfObject:item]].size.height;
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
		tableOldFrame.origin.y = 0;
		tableOldFrame.size.height = sizeOfCellsInTableView;
		tableOldFrame.size.width = headerView.frame.size.width;
		tableOldFrame = NSIntegralRect(tableOldFrame);
		[itemsTable setFrame:tableOldFrame];
		[[[itemsTable tableColumns] objectAtIndex:0] setWidth:tableOldFrame.size.width];
		[[[itemsTable superview] superview] setFrame:NSMakeRect(tableOldFrame.origin.x, tableOldFrame.origin.y - 2, tableOldFrame.size.width, tableOldFrame.size.height)];
	}
}

- (void)statusItemDeselected:(id)sender {
	[self closeWindow];
}

- (void)statusItemSelected:(id)sender {	
	NSMenu *fakeMenu = [[[NSMenu alloc] init] autorelease]; // Used to make sure another menu such as Spotlight will disapear when this is opened
	[statusItem popUpStatusItemMenu:fakeMenu];
	
	if (timer) { // Window shouldn't be closing right now. Stop the timer.
		[timer invalidate];
        [timer release];
        timer = nil;
		[self.window setAlphaValue:1.0]; 
	}
	
	if ([menuDelegate respondsToSelector:@selector(menuWillOpen)])
		[menuDelegate menuWillOpen];	
	
	mouseOverRow = -1;
	isSelecting = NO;
	
	[self loadHeights];
	[(RoundWindowFrameView *)[[self.window contentView] superview] setProMode:proMode];
	[self.window makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

#pragma mark TableDetectionDelegate

- (void)resetMouseOverRowToAndClose:(NSNumber *)row {
	mouseOverRow = [row intValue];
	[itemsTable reloadData];
	if ([menuDelegate respondsToSelector:@selector(shouldCloseMenuAfterSelectingRow:)]) {
		if ([menuDelegate shouldCloseMenuAfterSelectingRow:[row intValue]]) {
			[self closeWindow];
		}
	} else {
		[self closeWindow];
	}
}

- (void)mouseMovedIntoLocation:(NSPoint)loc {
	[timer invalidate];
	[timer release];
	timer = nil;
	timeHovering = 0;
		
	timer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(upTime) userInfo:nil repeats:YES] retain];
		
	mouseOverRow = [itemsTable rowAtPoint:[itemsTable convertPoint:loc fromView:nil]];
		
	if (itemWithOpenSubmenu != nil && mouseOverRow != [menuItems indexOfObject:itemWithOpenSubmenu]) {
		itemWithOpenSubmenu = nil;
	}
	
	[itemsTable reloadData];
}

- (void)mouseMovedOutOfViewToLoc:(NSPoint)loc {	
	[timer invalidate];
	[timer release];
	timer = nil;
	timeHovering = 0;
	
	if (mouseOverRow != -1 && itemWithOpenSubmenu == nil) {	
		mouseOverRow = -1;
		[itemsTable reloadData];
	}
		
	NSPoint convertedLoc = NSMakePoint(self.window.frame.origin.x + loc.x, self.window.frame.origin.y + loc.y);
		
//	NSLog(@"parentMenuOrigin = %@", NSStringFromPoint([parentMenu window].frame.origin));
//	NSLog(@"convertedLoc = %@", NSStringFromPoint(convertedLoc));
	
	if (parentMenu != nil) {
		// i know i'm a submenu
		if (convertedLoc.x > parentMenu.window.frame.origin.x && convertedLoc.y > parentMenu.window.frame.origin.y && convertedLoc.x < parentMenu.window.frame.origin.x + parentMenu.window.frame.size.width && convertedLoc.y < parentMenu.window.frame.origin.y + parentMenu.window.frame.size.height) {
            NSPoint convertedPoint = [parentMenu.window convertRectFromScreen:(NSRect){.origin = convertedLoc, .size = NSZeroSize}].origin;
			int mouseAtLoc = [parentMenu.itemsTable rowAtPoint:[parentMenu.itemsTable convertPoint:convertedPoint fromView:nil]];
			if (mouseAtLoc == parentMenu.mouseOverRow)
				return;
			
			isMovingBackToParent = YES;
			[parentMenu.window makeKeyAndOrderFront:self];
		}
	} else {
		// i may be the main menu but i still need to respect my little brother and make him active if the mouse heads towards him. i'm nice aren't i?
		if (convertedLoc.x > itemWithOpenSubmenu.submenu.window.frame.origin.x && convertedLoc.y > itemWithOpenSubmenu.submenu.window.frame.origin.y && convertedLoc.x < itemWithOpenSubmenu.submenu.window.frame.origin.x + itemWithOpenSubmenu.submenu.window.frame.size.width && convertedLoc.y < itemWithOpenSubmenu.submenu.window.frame.origin.y + itemWithOpenSubmenu.submenu.window.frame.size.height) {
			[itemWithOpenSubmenu.submenu.window makeKeyAndOrderFront:self];
		}
	}
}

- (void)mouseDownAtLocation:(NSPoint)loc {
	int row = [itemsTable rowAtPoint:[itemsTable convertPoint:loc fromView:nil]];
	if (row >= 0) {
		[self selectItemAtIndex:row];
	}
}

- (void)upTime {
	timeHovering += 0.1;
	
	if (mouseOverRow != -1 && [[menuItems objectAtIndex:mouseOverRow] submenu] != nil && itemWithOpenSubmenu == nil && timeHovering >= 0.1) {
	//	[self performSelector:@selector(displaySubmenuForRow:) withObject:[NSNumber numberWithInt:mouseOverRow] afterDelay:0.1];
		[self displaySubmenuForRow:[NSNumber numberWithInt:mouseOverRow]];
	}
}

- (void)escapeKeyPressed {
	[self closeWindow];
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [menuItems count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[[menuItems objectAtIndex:rowIndex] title] isEqualToString:@"--[SEPERATOR]--"])
		return @"";
	return [[menuItems objectAtIndex:rowIndex] title];
}

#pragma mark NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)rowIndex {
	if ([[[menuItems objectAtIndex:rowIndex] title] isEqualToString:@"--[SEPERATOR]--"])
		return 10;
	if ([[menuItems objectAtIndex:rowIndex] image] != nil)
		if ([[menuItems objectAtIndex:rowIndex] image].size.height + 2 >= 18)
			return [[menuItems objectAtIndex:rowIndex] image].size.height + 2; // 2 for padding specificially got 16*16 images
	return 18;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{		
	//NSLog(@"row index %i. time hovering %f", rowIndex, timeHovering);
	
	if (timeHovering > 1 && rowIndex == mouseOverRow && isSelecting == NO) {
	//	NSLog(@"RETURN AND STOP --------------------------------------------------------");
		return;
	}
	
	//NSLog(@"willdisplaycell");
	
	JGMenuItem *item = [menuItems objectAtIndex:rowIndex];
		
	if (item.enabled == NO) {
		[aCell setTextColor:[NSColor colorWithDeviceRed:0.502 green:0.502 blue:0.565 alpha:1.000]];
		return;
	}
	
	// Draw seperator
	
	if ([[item title] isEqualToString:@"--[SEPERATOR]--"]) {
		NSRect rowRect = [aTableView rectOfRow:rowIndex];
		rowRect.origin.x = 1;
		rowRect.origin.y += (int) (NSHeight(rowRect)/2);
		rowRect.size.width = rowRect.size.width - 2;
		rowRect.size.height = 1.0;
		[[NSColor colorWithDeviceWhite:0.871 alpha:1.000] set];
		if (proMode)
			[[NSColor colorWithDeviceWhite:0.3 alpha:1.000] set];
		NSRectFill(rowRect);
		return;
	}
	
	// Draw highlight
	
	if (mouseOverRow == rowIndex && ([aTableView selectedRow] != rowIndex) && item.enabled == YES) {
			NSRect rowRect = [aTableView rectOfRow:rowIndex];
			//NSRect columnRect = [aTableView rectOfColumn:[[aTableView tableColumns] indexOfObject:aTableColumn]];
            
            rowRect.origin.y--;
			
        if (!proMode) {
            NSRect rectToDraw = rowRect;
            rectToDraw.size.height = rowRect.size.height - 1;
            rectToDraw.origin.y = rectToDraw.origin.y + 1;
            [[NSColor jg_rowHighlightColor] set];
            NSRectFill(rectToDraw);
            
            [aCell setTextColor:[NSColor whiteColor]];
        } else {
            NSGradient* aGradient =
            [[[NSGradient alloc]
              initWithColorsAndLocations:
              [NSColor colorWithDeviceWhite:0.925 alpha:1.000], (CGFloat)0.0,
              [NSColor colorWithDeviceWhite:0.753 alpha:1.000], (CGFloat)1.0,
              nil]
             autorelease];
            NSRect rectToDraw = rowRect;
            rectToDraw.size.height = rowRect.size.height - 1;
            rectToDraw.origin.y = rectToDraw.origin.y + 1;
            [aGradient drawInRect:rectToDraw angle:90];
            
            [aTableView unlockFocus];
            
            [aCell setTextColor:[NSColor blackColor]];
        }
		
	} else if (item.enabled == YES) {
		[aCell setTextColor:[NSColor labelColor]];

		if (proMode)
			[aCell setTextColor:[NSColor whiteColor]];
	} 
	
	// Draw Disclosure Indicator for items with submenu
	
	if (item.submenu != nil && mouseOverRow != rowIndex) {
		// Not highlighted
		NSRect rowRect = [aTableView rectOfRow:rowIndex];
		CGPoint originToDrawFrom =  CGPointMake(rowRect.origin.x + headerView.frame.size.width - 20, NSMidY(rowRect) - 5); // Bottom left origin. Uses headerView width because rowRect width does not stay constant
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		
		CGContextSetRGBStrokeColor(context, 0.3, 0.6, 1.0, 1.0);
		CGContextSetRGBFillColor(context, 0.3, 0.6, 1.0, 1.0);
		CGContextSetLineWidth(context, 2.0);
		CGContextMoveToPoint(context, 10.0, 30.0);
		
		CGPoint addLines[] =
		{
			CGPointMake(originToDrawFrom.x, originToDrawFrom.y),
			CGPointMake(originToDrawFrom.x, originToDrawFrom.y + 10.0),
			CGPointMake(originToDrawFrom.x + 1.0, originToDrawFrom.y + 10.0),
			CGPointMake(originToDrawFrom.x + 8.0, originToDrawFrom.y + 5.0),
			CGPointMake(originToDrawFrom.x + 1.0, originToDrawFrom.y),
			CGPointMake(originToDrawFrom.x, originToDrawFrom.y),
		};		
		CGContextAddLines(context, addLines, sizeof(addLines)/sizeof(addLines[0]));
		
		if (!proMode)
			[[NSColor colorWithDeviceRed:0.424 green:0.424 blue:0.427 alpha:1.000] setFill];
		else
			[[NSColor colorWithDeviceWhite:0.761 alpha:1.000] setFill];
			
		CGContextDrawPath(context, kCGPathFill);
	} else if (item.submenu != nil && mouseOverRow == rowIndex) {
		// Highlighted	
		NSRect rowRect = [aTableView rectOfRow:rowIndex];
		CGPoint originToDrawFrom =  CGPointMake(rowRect.origin.x + headerView.frame.size.width - 20, NSMidY(rowRect) - 5); // Bottom left origin. Uses headerView width because rowRect width does not stay constant
		
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		
		CGContextSetRGBStrokeColor(context, 0.3, 0.6, 1.0, 1.0);
		CGContextSetRGBFillColor(context, 0.3, 0.6, 1.0, 1.0);
		CGContextSetLineWidth(context, 2.0);
		CGContextMoveToPoint(context, 10.0, 30.0);
		
		CGPoint addLines[] =
		{
			CGPointMake(originToDrawFrom.x, originToDrawFrom.y),
			CGPointMake(originToDrawFrom.x, originToDrawFrom.y + 10.0),
			CGPointMake(originToDrawFrom.x + 1.0, originToDrawFrom.y + 10.0),
			CGPointMake(originToDrawFrom.x + 8.0, originToDrawFrom.y + 5.0),
			CGPointMake(originToDrawFrom.x + 1.0, originToDrawFrom.y),
			CGPointMake(originToDrawFrom.x, originToDrawFrom.y),
		};		
		CGContextAddLines(context, addLines, sizeof(addLines)/sizeof(addLines[0]));
		
		if (!proMode)
			[[NSColor whiteColor] setFill];
		else 
			[[NSColor colorWithDeviceWhite:0.255 alpha:1.000] setFill];
			
		CGContextDrawPath(context, kCGPathFill);
	}
		
	// Now Draw Image
	
	NSImage *image = [[menuItems objectAtIndex:rowIndex] image];
	
	if (image) {
		NSRect rowRect = [aTableView rectOfRow:rowIndex];
		NSRect centeredRect = NSMakeRect(0, 0, [image size].width, [image size].height);
		centeredRect.origin.x = 17;
		centeredRect.origin.y = NSMidY(rowRect) - (([image size].height / 2) - 1);
		centeredRect = NSIntegralRect(centeredRect);
		[image drawAtPoint:centeredRect.origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
		
		// Pad the text accross further
		[(PaddedTextFieldCell *)aCell setLeftMargin:15 + image.size.width + 3];
	} else {
		[(PaddedTextFieldCell *)aCell setLeftMargin:15];	
	}
}

@end
