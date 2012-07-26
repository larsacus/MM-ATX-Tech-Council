
//  MMFullScreenDribbbleViewController.m
//  Dribbble
//
//  Copyright (c) 2012 Mutual Mobile. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "MMFullScreenDribbbleViewController.h"
#import "TWTweet.h"
#import "MMDataManager.h"
#import "MMTweetCell.h"
#import "UIImageView+AFNetworking.h"
#import "UIView+Animations.h"

#import <QuartzCore/QuartzCore.h>

static const NSInteger kOnDeckPlayers = 4;

static const CGFloat kAvatarHeightDifference = 110.0f;
static const CGFloat kAvatarStartingX = 1058.0f;

@interface MMFullScreenDribbbleViewController ()
@property (strong, nonatomic) NSArray               * tweetArray;
@property (strong, nonatomic) NSTimer               * tweetTimer;
@property (strong, nonatomic) NSString              * twitterSearchString;

- (void)fetchNewTweets;
- (void)updateTweetArrayWithNewTweets:(NSArray*)tweets;

- (void)roundThemCornersForImageViews:(NSArray*)imageViews;

@end

@implementation MMFullScreenDribbbleViewController
@synthesize tweetTableView = _tweetTableView;
@synthesize tweetArray = _tweetArray;
@synthesize tweetTimer = _tweetTimer;



@synthesize twitterImageView = _twitterImageView;



@synthesize twitterSearchString = _twitterSearchString;

- (id)initWithDribbbleUserName:(NSString *)dribbbleUserName reboundShotID:(NSString *)reboundShotID twitterSearchString:(NSString *)twitterSearchString {
    if ((self = [self initWithNibName:@"MMFullScreenDribbbleViewController" bundle:nil])) {
        _twitterSearchString = [twitterSearchString copy];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setTweetTableView:nil];
    [self setTwitterImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    self.view.frame = CGRectMake(0.0f, 0.0f, 1920.0f, 1080.0f);
    
    [self fetchNewTweets];
    _tweetTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                   target:self
                                                 selector:@selector(fetchNewTweets)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_tweetTimer invalidate];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Private

- (void)roundThemCornersForImageViews:(NSArray *)imageViews {
    for (UIImageView *imageView in imageViews) {
        imageView.layer.cornerRadius = 5.0f;
        imageView.layer.masksToBounds = YES;
    }
}

- (void)fetchNewTweets{
    NSManagedObjectContext *context = [[MMDataManager sharedDataManager] managedObjectContext];
    NSString * maxIdString = nil;
    if([_tweetArray count]>0){
        NSSortDescriptor * sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"tweetIdString"
                                                                          ascending:NO];
        NSArray * sortedArray = [_tweetArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        TWTweet * latestTweet = [sortedArray objectAtIndex:0];
        maxIdString = latestTweet.tweetIdString;
    }
    
    [TWTweet 
     tweetsForSearchString:self.twitterSearchString
     maxIdString:maxIdString
     context:context
     resultBlock:^(NSArray *tweets) {
         NSLog(@"Fetched %i new tweets!", tweets.count);
         
         if([tweets count]>0){
             [self animateTwitterGlow];
         }
         else{
             [self rotateTwitterLogo];
         }
         [self updateTweetArrayWithNewTweets:tweets];
     } 
     failureBlock:^(NSError *error) {

     }];
}
- (void)updateTweetArrayWithNewTweets:(NSArray*)tweets{
    if(!_tweetArray){
        _tweetArray = [[NSArray alloc] init];
    }
    
    NSMutableArray * tempArray = [NSMutableArray arrayWithArray:_tweetArray];
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [tweets count])];
    [tempArray insertObjects:tweets atIndexes:indexSet];
    
    NSMutableArray * indexPaths = [NSMutableArray arrayWithCapacity:[tweets count]];
    for (int i = 0; i < [tweets count]; i++){
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:i
                                                     inSection:0];
        [indexPaths addObject:indexPath];
    }
    
    _tweetArray = [NSArray arrayWithArray:tempArray];
    
    [_tweetTableView insertRowsAtIndexPaths:indexPaths
                           withRowAnimation:UITableViewRowAnimationTop];
}

- (void)setTwitterSearchString:(NSString *)twitterSearchString{
    _twitterSearchString = [twitterSearchString copy];
    
    NSLog(@"setting twitter search string to: %@", _twitterSearchString);
    
}

#pragma mark - UITableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_tweetArray count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"MMTweetCell";
    
    MMTweetCell *cell = (MMTweetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        
        cell = [[MMTweetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    TWTweet * tweet = [_tweetArray objectAtIndex:indexPath.row];
    [cell updateWithTweet:tweet];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    TWTweet * tweet = [_tweetArray objectAtIndex:indexPath.row];
    return [MMTweetCell cellHeightForWidth:tableView.bounds.size.width
                                 withTweet:tweet];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {

}

- (void)animateTwitterGlow{
//    self.twitterImageView.image = [UIImage imageNamed:@"twitter_on.png"];
    
    NSLog(@"animating twitter icon!");
    [UIView transitionWithView:self.twitterImageView
                      duration:0.25f
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent | UIViewAnimationOptionCurveEaseOut
                    animations:^{
                        self.twitterImageView.image = [UIImage imageNamed:@"twitter_on.png"];
                    }completion:^(BOOL finished) {
                        if (finished == YES) {
                            [UIView transitionWithView:self.twitterImageView
                                              duration:1.5f
                                               options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionCurveEaseIn
                                            animations:^{
                                                self.twitterImageView.image = [UIImage imageNamed:@"twitter_off.png"];
                                            } completion:nil];
                        }
                    }];
}

- (void)rotateTwitterLogo{
    [UIView transitionWithView:self.twitterImageView
                      duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:nil
                    completion:nil];
}

@end
