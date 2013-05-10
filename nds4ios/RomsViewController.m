//
//  RomsViewController.m
//  nds4ios
//
//  Created by Admin on 20/12/2012.
//  Copyright (c) 2012 Homebrew. All rights reserved.
//

#import "RomsViewController.h"
#import "EmuViewController.h"

@interface RomsViewController ()

@property (nonatomic,retain) NSMutableArray* romsArray;

@end

@implementation RomsViewController
@synthesize romsArray;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"nds4ios";
    
    NSString *documetsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray* roms = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documetsPath error:nil];
    
    BOOL isDir;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Battery",documetsPath] isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/Battery",documetsPath] withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    self.romsArray = [[[NSMutableArray alloc] init] autorelease];
    
    for (NSString* rom in roms) {
        if ([rom rangeOfString:@".nds" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self.romsArray addObject:rom];
        }
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.romsArray = nil;
}

- (void)dealloc
{
    [self viewDidUnload];
    [super dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.romsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    cell.textLabel.text = [self.romsArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* rom = [self.romsArray objectAtIndex:indexPath.row];
    EmuViewController* controller = [[[EmuViewController alloc] initWithRom:rom] autorelease];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
