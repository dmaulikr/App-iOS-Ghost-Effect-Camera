//
//  ViewController.h
//  Ghost Effect Camera
//
//  Created by Hao Wu on 6/16/15.
//  Copyright (c) 2015 Hao Wu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

SLComposeViewController *mySLComposerSheet;

@interface ViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>




@property (strong, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)button1:(id)sender;
- (IBAction)button2:(id)sender;
- (IBAction)button3:(id)sender;
- (IBAction)backButton:(id)sender;
- (IBAction)startoverButton:(id)sender;
- (IBAction)nextButton:(id)sender;
- (IBAction)sliderTopValueChanged:(id)sender;
- (IBAction)sliderButtomValueChanged:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *buttonLeft;
@property (strong, nonatomic) IBOutlet UIButton *buttonRight;
@property (strong, nonatomic) IBOutlet UIButton *buttonMiddle;
@property (strong, nonatomic) IBOutlet UIButton *goNext;
@property (strong, nonatomic) IBOutlet UIButton *goBack;
@property (strong, nonatomic) IBOutlet UIButton *goStartover;
@property (strong, nonatomic) IBOutlet UILabel *textButtom;
@property (strong, nonatomic) IBOutlet UISlider *sliderTop;
@property (strong, nonatomic) IBOutlet UISlider *sliderButtom;
@property (strong, nonatomic) IBOutlet UILabel *textButtom2;
@property (strong, nonatomic) IBOutlet UILabel *transLabel;
@property (strong, nonatomic) IBOutlet UILabel *zoomLabel;
@property (strong, nonatomic) IBOutlet UITextView *moreInfo;
- (IBAction)toFacebook:(id)sender;
- (IBAction)toTwitter:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *facebookButton;
@property (strong, nonatomic) IBOutlet UIButton *twitterButton;
@property (strong, nonatomic) IBOutlet UIVisualEffectView *blurView;
@property (strong, nonatomic) IBOutlet UICollectionView *ghostCollectionView;


@end

