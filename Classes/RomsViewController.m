//
//  RomsViewController.m
//  nds4ios
//
//  Created by rock88 on 20/12/2012.
//  Copyright (c) 2012 Homebrew. All rights reserved.
//

#import "RomsViewController.h"
#import "EmuViewController.h"

#define DOCUMENTS_PATH() [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

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

- (void)dealloc
{
    [self viewDidUnload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"nds4ios";
    self.romsArray = [[NSMutableArray alloc] init];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                          target:self
                                                                                          action:@selector(reloadRomList)];
    
    BOOL isDir;
    NSString* batteryDir = [NSString stringWithFormat:@"%@/Battery",DOCUMENTS_PATH()];
    NSFileManager* fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:batteryDir isDirectory:&isDir]) {
        [fm createDirectoryAtPath:batteryDir withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    [self reloadRomList];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.romsArray = nil;
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

- (void)reloadRomList
{
    [self.romsArray removeAllObjects];
    
    NSArray* roms = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DOCUMENTS_PATH() error:nil];
    
    for (NSString* rom in roms) {
        if ([rom rangeOfString:@".nds" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self.romsArray addObject:rom];
        }
    }
    
    [self.tableView reloadData];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [self.romsArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* rom = [self.romsArray objectAtIndex:indexPath.row];
    EmuViewController* controller = [[EmuViewController alloc] initWithRom:rom];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
