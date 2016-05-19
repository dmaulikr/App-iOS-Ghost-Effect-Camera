//
//  ViewController.m
//  Ghost Effect Camera
//
//  Created by Hao Wu on 6/16/15.
//  Copyright (c) 2015 Hao Wu. All rights reserved.
//

#import "ViewController.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@property int phase;
//1 is choosing the photo, 2 is choosing the ghost, 3 is modifing the ghost and 4 is finishing.

@end

@implementation ViewController
{
    
    //original images with full resolution
    UIImage *imageOri;
    UIImage *ghostImageOri;
    
    //ghost library
    NSArray *ghostLib;
    
    //other image stuff
    CGImageRef image;
    CGImageRef ghostImage;
    UIImage *tempImage;
    UIImage *tempGhostImage;
    UIImage *imageToPost;
    CGContextRef imageContext;
    CGContextRef ghostContext;
    CGColorSpaceRef colorSpace;
    NSUInteger bytesPerPixel;
    NSUInteger bitsPerComponent;
    NSUInteger imageBytesPerRow;
    NSUInteger ghostBytesPerRow;
    
    
    //width and height
    NSUInteger imageWidthOri;
    NSUInteger imageHeightOri;
    NSUInteger imageWidth;
    NSUInteger imageHeight;
    NSUInteger ghostWidthOri;
    NSUInteger ghostHeightOri;
    NSUInteger ghostWidth;
    NSUInteger ghostHeight;
    UInt32 *imagePixels;
    UInt32 *ghostPixels;
    CGSize ghostSize;
    CGPoint ghostOrigin;
    
    
    //ratios
    CGFloat imageViewRatio;
    CGFloat pickedImageRatio;
    CGFloat ghostRatio;
    CGFloat imageScaledRatio;
    
    
    //other stuff
    BOOL horizontalImage;
    BOOL readyToGo;
    BOOL canGoBack;
    float transValue;
    float zoomValue;
    int iStart;
    int jStart;
    int iEnd;
    int jEnd;
}

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )

- (void)viewDidLoad
{
    [super viewDidLoad];

    
    self.phase = 1;
    readyToGo = NO;
    canGoBack = YES;
    [self.goBack setImage:[UIImage imageNamed:@"backbutton"] forState:UIControlStateNormal];
    [self.goStartover setImage:[UIImage imageNamed:@"trashbutton"] forState:UIControlStateNormal];
    [self.goNext setImage:[UIImage imageNamed:@"nextbutton"] forState:UIControlStateNormal];
    self.goBack.enabled = NO;
    self.goNext.enabled = NO;
    self.goStartover.enabled = NO;
    self.sliderTop.hidden = YES;
    self.sliderTop.enabled = NO;
    self.sliderButtom.hidden = YES;
    self.sliderButtom.enabled = NO;
    self.transLabel.hidden = YES;
    self.zoomLabel.hidden = YES;
    [self.buttonLeft setImage:[UIImage imageNamed:@"folderbutton"] forState:UIControlStateNormal];
    [self.buttonRight setImage:[UIImage imageNamed:@"camerabutton"] forState:UIControlStateNormal];
    self.buttonLeft.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:25];
    self.buttonRight.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:25];
    [self.buttonMiddle setImage:[UIImage imageNamed:@"ghostbutton"] forState:UIControlStateNormal];
    self.buttonMiddle.hidden = YES;
    self.textButtom.text = @"Select a Photo from Library or Camera to Apply Ghost Effect.";
    self.textButtom2.hidden = YES;
    self.moreInfo.hidden = YES;
    self.facebookButton.hidden = YES;
    self.twitterButton.hidden = YES;
    self.blurView.hidden = YES;
    ghostLib = [NSArray arrayWithObjects:@"ghostLib1.png",@"ghostLib2.png",@"ghostLib3.png", nil];

    _ghostCollectionView.delegate = self;
    _ghostCollectionView.dataSource = self;
    self.ghostCollectionView.hidden = YES;

    
    self.imageView.userInteractionEnabled = YES;
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [self.imageView addGestureRecognizer:panRecognizer];

    
    imageViewRatio = self.imageView.frame.size.width / self.imageView.frame.size.height;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    bytesPerPixel = 4;
    bitsPerComponent = 8;
    


}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)button1:(id)sender
{
    if (self.phase == 1) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    if (self.phase == 2) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    if (self.phase == 4) {
        [self actualSaving];
    }

    
}

- (IBAction)button2:(id)sender
{
    if (self.phase == 1) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    if (self.phase == 2) {
        self.moreInfo.hidden = NO;
        self.textButtom.hidden = YES;
        self.goNext.hidden = YES;
        self.goStartover.hidden = YES;
        self.blurView.hidden = NO;
        [self.goBack setTitle:@"GOT IT" forState:UIControlStateNormal];
        self.phase = 10;
    }
    if (self.phase == 4) {
        self.blurView.hidden = NO;

        self.facebookButton.hidden = NO;
        self.twitterButton.hidden = NO;
        self.goBack.enabled = YES;
        self.textButtom.hidden = YES;
        //self.buttonLeft.enabled = NO;
        self.buttonLeft.hidden = YES;
        self.buttonRight.hidden = YES;
        //self.buttonRight.enabled = NO;
        
        self.phase = 40;
    }
    
}

- (IBAction)button3:(id)sender {
    self.phase = 30;
    self.ghostCollectionView.hidden = NO;
    self.blurView.hidden = NO;
    self.textButtom2.text = @"More Photos Will be Updated Soon and Will be Free to Use.";
    self.textButtom2.hidden = NO;
}

- (IBAction)backButton:(id)sender
{
    
    
    if (self.phase == 10) {
        canGoBack = NO;
        [self.goBack setTitle:@"BACK" forState:UIControlStateNormal];
        self.moreInfo.hidden = YES;
        self.goNext.hidden = NO;
        self.goStartover.hidden = NO;
        self.textButtom.hidden = NO;
        self.phase = 2;
        self.blurView.hidden = YES;
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                       {
                           canGoBack = YES;
                       });

    }
    if (self.phase == 30) {
        canGoBack = NO;
        self.phase = 2;
        self.blurView.hidden = YES;
        self.ghostCollectionView.hidden = YES;
        self.goNext.enabled = NO;
        double delayInSeconds = 1.0;
        self.textButtom2.text = @"Drag to Change the Position of the Ghost, Use the Sliders to Adjust the Transparency and Size.";
        self.textButtom2.hidden = YES;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                       {
                           canGoBack = YES;
                       });
        
            }
    if (self.phase == 40) {
        self.phase = 4;
        self.goBack.enabled = NO;
        canGoBack = NO;
        self.blurView.hidden = YES;
        self.facebookButton.hidden = YES;
        self.twitterButton.hidden = YES;
        self.textButtom.hidden = NO;
        self.buttonLeft.hidden = NO;
        self.buttonRight.hidden = NO;
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                       {
                           canGoBack = YES;
                       });
        
    }
    if (self.phase == 2 && canGoBack == YES) {
        canGoBack = NO;
        self.phase = 1;
        self.imageView.image = nil;
        readyToGo = NO;
        self.goBack.enabled = NO;
        self.goNext.enabled = NO;
        self.goStartover.enabled = NO;
        self.sliderTop.hidden = YES;
        self.sliderTop.enabled = NO;
        self.sliderButtom.hidden = YES;
        self.sliderButtom.enabled = NO;
        self.transLabel.hidden = YES;
        self.zoomLabel.hidden = YES;
        self.buttonMiddle.hidden = YES;
        [self.buttonLeft setImage:[UIImage imageNamed:@"folderbutton"] forState:UIControlStateNormal];
        [self.buttonRight setImage:[UIImage imageNamed:@"camerabutton"] forState:UIControlStateNormal];
        [self.goNext setTitle:@"NEXT" forState:UIControlStateNormal];
        self.textButtom.text = @"Select a Photo from Library or Camera to Apply Ghost Effect.";
        self.textButtom.hidden = NO;
        self.textButtom2.hidden = YES;
        self.moreInfo.hidden = YES;
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                       {
                           canGoBack = YES;
                       });


    }
    if (self.phase == 3 && canGoBack == YES) {
        CGContextRelease(ghostContext);
        free(ghostPixels);
        canGoBack = NO;
        self.phase = 2;
        [self.goNext setImage:[UIImage imageNamed:@"nextbutton"] forState:UIControlStateNormal];
        //[self.buttonRight setTitle:@"HELP" forState:UIControlStateNormal];
        [self.buttonLeft setImage:[UIImage imageNamed:@"folderbutton"] forState:UIControlStateNormal];
        [self.buttonRight setImage:[UIImage imageNamed:@"infobutton"] forState:UIControlStateNormal];
        [self.buttonRight setImage:[UIImage imageNamed:@"infobutton"] forState:UIControlStateNormal];
        self.buttonRight.hidden = NO;
        self.buttonLeft.hidden = NO;
        self.buttonRight.enabled = YES;
        self.buttonLeft.enabled = YES;
        readyToGo = NO;
        self.goNext.enabled = NO;
        self.goBack.enabled = YES;
        self.goStartover.enabled = YES;
        self.textButtom.text = @"Choose a Ghost Photo form Your Local Library or Our Database. Ghost Photo Should be a PNG File with TRANSPARENT BACKGROUND.  Click INFO for more Infomation.";
        self.sliderTop.hidden = YES;
        self.sliderTop.enabled = NO;
        self.sliderButtom.hidden = YES;
        self.sliderButtom.enabled = NO;
        self.goNext.enabled = NO;
        self.textButtom.hidden = NO;
        self.textButtom2.hidden = YES;
        self.transLabel.hidden = YES;
        self.zoomLabel.hidden = YES;
        self.buttonMiddle.hidden = NO;
        CGContextDrawImage(imageContext, CGRectMake(0, 0, imageWidth, imageHeight), image);
        CGImageRef finalCGImage = CGBitmapContextCreateImage(imageContext);
        UIImage *finalImage = [UIImage imageWithCGImage:finalCGImage];
        self.imageView.image = finalImage;
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                       {
                           canGoBack = YES;
                       });
    }
    
}

- (IBAction)startoverButton:(id)sender
{
    self.imageView.image = nil;
    readyToGo = NO;
    self.goBack.enabled = NO;
    self.goNext.enabled = NO;
    self.goStartover.enabled = NO;
    [self.goNext setImage:[UIImage imageNamed:@"nextbutton"] forState:UIControlStateNormal];
    self.sliderTop.hidden = YES;
    self.sliderTop.enabled = NO;
    self.sliderButtom.hidden = YES;
    self.sliderButtom.enabled = NO;
    self.transLabel.hidden = YES;
    self.zoomLabel.hidden = YES;
    self.buttonMiddle.hidden = YES;
    [self.buttonLeft setImage:[UIImage imageNamed:@"folderbutton"] forState:UIControlStateNormal];
    [self.buttonRight setImage:[UIImage imageNamed:@"camerabutton"] forState:UIControlStateNormal];
    [self.goStartover setImage:[UIImage imageNamed:@"trashbutton"] forState:UIControlStateNormal];
    self.textButtom.text = @"Select a Photo from Library or Camera to Apply Ghost Effect.";
    self.textButtom.hidden = NO;
    self.textButtom2.hidden = YES;
    self.moreInfo.hidden = YES;

    
    if (self.phase == 1 && readyToGo == YES) {
        CGContextRelease(imageContext);
        free(imagePixels);
    }
    if (self.phase == 2) {
        self.phase = 1;
        CGContextRelease(imageContext);
        free(imagePixels);
        if (readyToGo == YES) {
            CGContextRelease(ghostContext);
            free(ghostPixels);
        }
    }
    if (self.phase == 3) {
        self.phase = 1;
        CGContextRelease(imageContext);
        CGContextRelease(ghostContext);
        free(imagePixels);
        free(ghostPixels);
    }
    if (self.phase == 4) {
        self.phase = 1;
        self.buttonLeft.enabled = YES;
        CGContextRelease(imageContext);
        CGContextRelease(ghostContext);
        free(imagePixels);
        free(ghostPixels);
    }
    
}

- (IBAction)nextButton:(id)sender
{
    if (self.phase == 1 && readyToGo == YES) {
        //change the interface
        self.phase = 2;
        //[self.buttonRight setTitle:@"HELP" forState:UIControlStateNormal];
        [self.buttonRight setImage:[UIImage imageNamed:@"infobutton"] forState:UIControlStateNormal];
        readyToGo = NO;
        self.buttonMiddle.hidden = NO;
        self.goNext.enabled = NO;
        self.goBack.enabled = YES;
        self.goStartover.enabled = YES;
        self.textButtom.text = @"Choose a Ghost Photo form Your Local Library or Our Database. Ghost Photo Should be a PNG File with TRANSPARENT BACKGROUND.  Click INFO for more Infomation.";
        
    }
    if (self.phase == 2 && readyToGo == YES) {
        readyToGo = NO;
        self.goNext.enabled = NO;
        self.phase = 3;
        self.buttonLeft.hidden = YES;
        self.buttonRight.hidden = YES;
        self.buttonLeft.enabled = NO;
        self.buttonRight.enabled = NO;
        self.buttonMiddle.hidden = YES;
        self.sliderTop.hidden = NO;
        self.sliderTop.enabled = YES;
        self.sliderButtom.hidden = NO;
        self.sliderButtom.enabled = YES;
        self.sliderTop.value = 0.5;
        self.sliderButtom.value = 0.5;
        transValue = 0.5;
        zoomValue = 0.5;
        self.textButtom.hidden = YES;
        self.textButtom2.text = @"Drag to Change the Position of the Ghost, Use the Sliders to Adjust the Transparency and Size.";
        self.textButtom2.hidden = NO;
        self.transLabel.hidden = NO;
        self.zoomLabel.hidden = NO;
        [self.goNext setTitle:@"DONE" forState:UIControlStateNormal];
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
        {
            [self.goNext setImage:[UIImage imageNamed:@"donebutton"] forState:UIControlStateNormal];
            self.goNext.enabled = YES;
            readyToGo = YES;
        });
    
    }
    if (self.phase == 3 && readyToGo == YES) {
        [self saveImage];
        self.phase = 4;
        self.goNext.enabled = NO;
        self.goBack.enabled = NO;
        self.sliderTop.hidden = YES;
        self.sliderTop.enabled = NO;
        self.sliderButtom.hidden = YES;
        self.sliderButtom.enabled = NO;
        [self.buttonLeft setImage:[UIImage imageNamed:@"savebutton"] forState:UIControlStateNormal];
        [self.buttonRight setImage:[UIImage imageNamed:@"sharebutton"] forState:UIControlStateNormal];
        self.buttonLeft.hidden = NO;
        self.buttonRight.hidden = NO;
        self.buttonLeft.enabled = YES;
        self.buttonRight.enabled = YES;
        self.transLabel.hidden = YES;
        self.zoomLabel.hidden = YES;
        self.textButtom2.hidden = YES;
        self.textButtom.text = @"Congratulations! You've Made a Ghost Picture. Save or Share or Restart to Make Another One!";
        self.textButtom.hidden = NO;
        [self.goStartover setImage:[UIImage imageNamed:@"restartbutton"] forState:UIControlStateNormal];

        
    }
}

- (IBAction)sliderTopValueChanged:(UISlider *)slider
{
    transValue = slider.value;
    CGContextDrawImage(imageContext, CGRectMake(0, 0, imageWidth, imageHeight), image);
    NSInteger offsetPixelCountForInput = ghostOrigin.y * imageWidth + ghostOrigin.x;
    iEnd = ghostSize.width;
    jEnd = ghostSize.height;
    iStart = 0;
    jStart = 0;
    if (ghostOrigin.x + ghostSize.width > imageWidth) {
        iEnd = (int)( - ghostOrigin.x + imageWidth);
    }
    if (ghostOrigin.y + ghostSize.height > imageHeight) {
        jEnd = (int)( -ghostOrigin.y + imageHeight);
    }
    if (ghostOrigin.x < 0) {
        iStart = 0 - ghostOrigin.x;
    }
    if (ghostOrigin.y < 0) {
        jStart = 0 - ghostOrigin.y;
    }
    for (int j = jStart; j < jEnd; j++) {
        for (int i = iStart; i < iEnd; i++) {
            UInt32 *inputPixel = imagePixels + j * imageWidth + i + offsetPixelCountForInput;
            UInt32 inputColor = *inputPixel;
            UInt32 *ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel;
            
            CGFloat ghostAlpha = (transValue) * (A(ghostColor) / 255.0);
            UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha;
            UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
            UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
            
            newR = MAX(0, MIN(255, newR));
            newG = MAX(0, MIN(255, newG));
            newB = MAX(0, MIN(255, newB));
            
            *inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
        }
    }
    
    
    
    CGImageRef finalCGImage = CGBitmapContextCreateImage(imageContext);
    UIImage *finalImage = [UIImage imageWithCGImage:finalCGImage];
    self.imageView.image = finalImage;
    

}

- (IBAction)sliderButtomValueChanged:(UISlider *)slider {
    zoomValue = slider.value;
    CGContextRelease(ghostContext);
    free(ghostPixels);
    CGContextDrawImage(imageContext, CGRectMake(0, 0, imageWidth, imageHeight), image);
    
    ghostWidth = (int)(ghostWidthOri * zoomValue);
    if (ghostWidth < 5) {
        ghostWidth = 5;
    }
    ghostHeight = (int)(ghostHeightOri * zoomValue);
    if (ghostHeight < 5) {
        ghostHeight = 5;
    }
    
    ghostImage = [ghostImageOri CGImage];
    ghostSize = CGSizeMake(ghostWidth, ghostHeight);
    ghostOrigin = CGPointMake((int)(ghostOrigin.x), (int)(ghostOrigin.y));
    
    ghostBytesPerRow = bytesPerPixel * ghostSize.width;
    ghostPixels = (UInt32 *)calloc(ghostSize.width * ghostSize.height, sizeof(UInt32));
    
    ghostContext = CGBitmapContextCreate(ghostPixels, ghostSize.width, ghostSize.height, bitsPerComponent, ghostBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostSize.width, ghostSize.height), ghostImage);
    NSInteger offsetPixelCountForInput = ghostOrigin.y * imageWidth + ghostOrigin.x;
    
    iEnd = ghostSize.width;
    jEnd = ghostSize.height;
    iStart = 0;
    jStart = 0;
    if (ghostOrigin.x + ghostSize.width > imageWidth) {
        iEnd = (int)( - ghostOrigin.x + imageWidth);
    }
    if (ghostOrigin.y + ghostSize.height > imageHeight) {
        jEnd = (int)( -ghostOrigin.y + imageHeight);
    }
    if (ghostOrigin.x < 0) {
        iStart = 0 - ghostOrigin.x;
    }
    if (ghostOrigin.y < 0) {
        jStart = 0 - ghostOrigin.y;
    }
    for (int j = jStart; j < jEnd; j++) {
        for (int i = iStart; i < iEnd; i++) {
            UInt32 *inputPixel = imagePixels + j * imageWidth + i + offsetPixelCountForInput;
            UInt32 inputColor = *inputPixel;
            UInt32 *ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel;
            
            CGFloat ghostAlpha = (transValue) * (A(ghostColor) / 255.0);
            UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha;
            UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
            UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
            
            newR = MAX(0, MIN(255, newR));
            newG = MAX(0, MIN(255, newG));
            newB = MAX(0, MIN(255, newB));
            
            *inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
        }
    }
    
    
    CGImageRef finalCGImage = CGBitmapContextCreateImage(imageContext);
    UIImage *finalImage = [UIImage imageWithCGImage:finalCGImage];
    self.imageView.image = finalImage;
    

}


-(void)loadPickedImage:(UIImage*)pickedImage;
{
    imageOri = pickedImage;
    imageWidthOri = pickedImage.size.width;
    imageHeightOri = pickedImage.size.height;
    pickedImageRatio = (float)imageWidthOri/(float)imageHeightOri;

    if (pickedImageRatio > imageViewRatio) {
        horizontalImage = YES;
        imageWidth = (int)(self.imageView.frame.size.width);
        imageHeight = (int)(self.imageView.frame.size.width * (float)imageHeightOri/(float)imageWidthOri);
        imageScaledRatio = imageWidthOri / self.imageView.frame.size.width;
    }
    else {
        horizontalImage = NO;
        imageHeight = (int)(self.imageView.frame.size.height);
        imageWidth = (int)(self.imageView.frame.size.height * (float)imageWidthOri/(float)imageHeightOri);
        imageScaledRatio = imageHeightOri / self.imageView.frame.size.height;
    }
    
    
    //resize
    
    tempImage = nil;
    CGSize targetSize = CGSizeMake(imageWidth,imageHeight);
    UIGraphicsBeginImageContext(targetSize);
    CGRect thumbnailRect = CGRectMake(0, 0, 0, 0);
    thumbnailRect.origin = CGPointMake(0.0,0.0);
    thumbnailRect.size.width  = targetSize.width;
    thumbnailRect.size.height = targetSize.height;
    [pickedImage drawInRect:thumbnailRect];
    tempImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = [tempImage CGImage];
    
    //draw
    
    imageBytesPerRow = bytesPerPixel * imageWidth;
    imagePixels = (UInt32 *)calloc(imageHeight * imageWidth, sizeof(UInt32));
    imageContext = CGBitmapContextCreate(imagePixels, imageWidth, imageHeight, bitsPerComponent, imageBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(imageContext, CGRectMake(0, 0, imageWidth, imageHeight), image);
    CGImageRef finalCGImage = CGBitmapContextCreateImage(imageContext);
    UIImage *finalImage = [UIImage imageWithCGImage:finalCGImage];
    self.imageView.image = finalImage;

    readyToGo = YES;
    self.textButtom.text = @"Continue or Choose another Photo.";
    self.goNext.enabled = YES;
    self.goStartover.enabled = YES;
}


-(void)loadGhostImage:(UIImage*)pickedGhost;
{
    CGContextDrawImage(imageContext, CGRectMake(0, 0, imageWidth, imageHeight), image);
    ghostImageOri = pickedGhost;
    
    ghostWidthOri = pickedGhost.size.width;
    ghostHeightOri = pickedGhost.size.height;
    ghostRatio = (float)ghostWidthOri/(float)ghostHeightOri;
    
    if (ghostRatio > pickedImageRatio) {
        ghostWidth = (int)(imageWidth);
        ghostHeight = (int)(ghostHeightOri * imageWidth / ghostWidthOri);
    }
    else {
        ghostWidth = (int)(ghostWidthOri * imageHeight / ghostHeightOri);
        ghostHeight = (int)(imageHeight);
    }
    ghostWidthOri = ghostWidth;
    ghostHeightOri = ghostHeight;
    
    ghostWidth = (int)(ghostWidth/2);
    ghostHeight = (int)(ghostHeight/2);

    
    //resize
    
    tempGhostImage = nil;
    CGSize targetSize = CGSizeMake(ghostWidth,ghostHeight);
    UIGraphicsBeginImageContext(targetSize);
    CGRect thumbnailRect = CGRectMake(0, 0, 0, 0);
    thumbnailRect.origin = CGPointMake(0.0,0.0);
    thumbnailRect.size.width  = targetSize.width;
    thumbnailRect.size.height = targetSize.height;
    [pickedGhost drawInRect:thumbnailRect];
    tempGhostImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    ghostImage = [tempGhostImage CGImage];
    
    
    ghostSize = CGSizeMake(ghostWidth, ghostHeight);
    ghostOrigin = CGPointMake((int)(imageWidth * 0.5 - ghostSize.width/2), (int)(imageHeight * 0.5) - (int)(ghostSize.width/2));
    ghostBytesPerRow = bytesPerPixel * ghostWidth;
    ghostPixels = (UInt32 *)calloc(ghostWidth * ghostHeight, sizeof(UInt32));
    ghostContext = CGBitmapContextCreate(ghostPixels, ghostWidth, ghostHeight, bitsPerComponent, ghostBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostWidth, ghostHeight), ghostImage);

    
    //draw
    NSInteger offsetPixelCountForInput = ghostOrigin.y * imageWidth + ghostOrigin.x;
    for (int j = 0; j < ghostSize.height; j++) {
        for (int i = 0; i < ghostSize.width; i++) {
            UInt32 *imagePixel = imagePixels + j * imageWidth + i + offsetPixelCountForInput;
            UInt32 inputColor = *imagePixel;
            UInt32 *ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel;
            
            CGFloat ghostAlpha = 0.5 *(A(ghostColor) / 255.0);
            UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha;
            UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
            UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
            
            newR = MAX(0, MIN(255, newR));
            newG = MAX(0, MIN(255, newG));
            newB = MAX(0, MIN(255, newB));
            
            *imagePixel = RGBAMake(newR, newG, newB, A(inputColor));
        }
    }
    
    CGImageRef finalCGImage = CGBitmapContextCreateImage(imageContext);
    UIImage *finalImage = [UIImage imageWithCGImage:finalCGImage];
    self.imageView.image = finalImage;
    
    self.textButtom2.text = @"Drag to Change the Position of the Ghost, Use the Sliders to Adjust the Transparency and Size.";
    self.textButtom2.hidden = YES;
    readyToGo = YES;
    self.goNext.enabled = YES;
    self.textButtom.text = @"Press Next to Modify Ghost Photo.";

}


-(void)saveImage
{
    //self.buttonLeft.enabled = NO;
    CGContextRelease(imageContext);
    CGContextRelease(ghostContext);
    free(imagePixels);
    free(ghostPixels);
    
    //image = [imageOri CGImage];
    imageWidth = imageWidthOri;
    imageHeight = imageHeightOri;
    //imageWidth = (int)(imageWidth *imageScaledRatio);
    //imageHeight = (int)(imageHeight * imageScaledRatio);
    
    tempImage = nil;
    CGSize targetSize1 = CGSizeMake(imageWidth,imageHeight);
    UIGraphicsBeginImageContext(targetSize1);
    CGRect thumbnailRect1 = CGRectMake(0, 0, 0, 0);
    thumbnailRect1.origin = CGPointMake(0.0,0.0);
    thumbnailRect1.size.width  = targetSize1.width;
    thumbnailRect1.size.height = targetSize1.height;
    [imageOri drawInRect:thumbnailRect1];
    tempImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = [tempImage CGImage];

    imageBytesPerRow = bytesPerPixel * imageWidth;
    imagePixels = (UInt32 *)calloc(imageHeight * imageWidth, sizeof(UInt32));
    imageContext = CGBitmapContextCreate(imagePixels, imageWidth, imageHeight, bitsPerComponent, imageBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(imageContext, CGRectMake(0, 0, imageWidth, imageHeight), image);
   
    ghostWidth = (int)(ghostWidth * imageScaledRatio);
    ghostHeight = (int)(ghostHeight * imageScaledRatio);
    ghostSize = CGSizeMake(ghostWidth, ghostHeight);
    ghostOrigin.x = (int)(ghostOrigin.x * imageScaledRatio);
    ghostOrigin.y = (int)(ghostOrigin.y * imageScaledRatio);
    
    tempGhostImage = nil;
    CGSize targetSize = CGSizeMake(ghostWidth,ghostHeight);
    UIGraphicsBeginImageContext(targetSize);
    CGRect thumbnailRect = CGRectMake(0, 0, 0, 0);
    thumbnailRect.origin = CGPointMake(0.0,0.0);
    thumbnailRect.size.width  = targetSize.width;
    thumbnailRect.size.height = targetSize.height;
    [ghostImageOri drawInRect:thumbnailRect];
    tempGhostImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    ghostImage = [tempGhostImage CGImage];
    
    ghostBytesPerRow = bytesPerPixel * ghostWidth;
    ghostPixels = (UInt32 *)calloc(ghostWidth * ghostHeight, sizeof(UInt32));
    
    ghostContext = CGBitmapContextCreate(ghostPixels, ghostWidth, ghostHeight, bitsPerComponent, ghostBytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(ghostContext, CGRectMake(0, 0, ghostWidth, ghostHeight), ghostImage);
    
    NSInteger offsetPixelCountForInput = ghostOrigin.y * imageWidth + ghostOrigin.x;
    iEnd = ghostSize.width;
    jEnd = ghostSize.height;
    iStart = 0;
    jStart = 0;
    if (ghostOrigin.x + ghostSize.width > imageWidth) {
        iEnd = (int)( - ghostOrigin.x + imageWidth);
    }
    if (ghostOrigin.y + ghostSize.height > imageHeight) {
        jEnd = (int)( -ghostOrigin.y + imageHeight);
    }
    if (ghostOrigin.x < 0) {
        iStart = 0 - ghostOrigin.x;
    }
    if (ghostOrigin.y < 0) {
        jStart = 0 - ghostOrigin.y;
    }
    for (int j = jStart; j < jEnd; j++) {
        for (int i = iStart; i < iEnd; i++) {
            UInt32 *inputPixel = imagePixels + j * imageWidth + i + offsetPixelCountForInput;
            UInt32 inputColor = *inputPixel;
            UInt32 *ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel;
            
            CGFloat ghostAlpha = (transValue) * (A(ghostColor) / 255.0);
            UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha;
            UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
            UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
            
            newR = MAX(0, MIN(255, newR));
            newG = MAX(0, MIN(255, newG));
            newB = MAX(0, MIN(255, newB));
            
            *inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
        }
    }

    /*for (int j = 0; j < ghostSize.height; j++) {
        for (int i = 0; i < ghostSize.width; i++) {
            UInt32 *imagePixel = imagePixels + j * imageWidth + i + offsetPixelCountForInput;
            UInt32 inputColor = *imagePixel;
            UInt32 *ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
            UInt32 ghostColor = *ghostPixel;
            
            CGFloat ghostAlpha = transValue *(A(ghostColor) / 255.0);
            UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha;
            UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
            UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
            
            newR = MAX(0, MIN(255, newR));
            newG = MAX(0, MIN(255, newG));
            newB = MAX(0, MIN(255, newB));
            
            *imagePixel = RGBAMake(newR, newG, newB, A(inputColor));
        }
    }*/
    
    CGImageRef finalCGImage = CGBitmapContextCreateImage(imageContext);
    UIImage *finalImage = [UIImage imageWithCGImage:finalCGImage];
    self.imageView.image = finalImage;
    imageToPost = finalImage;
    self.buttonRight.enabled = YES;
    //UIImageWriteToSavedPhotosAlbum(finalImage, nil, @selector(sendAlert), nil);
    /*UIImageWriteToSavedPhotosAlbum(finalImage, self,
                                   @selector(image:finishedSavingWithError:contextInfo:),
                                   nil);*/
    
    
}

-(void)actualSaving
{
    UIImageWriteToSavedPhotosAlbum(imageToPost, self, @selector(image:finishedSavingWithError:contextInfo:), nil);
    self.buttonLeft.enabled = NO;
    
}


//dragging


-(void)drag:(UIPanGestureRecognizer *)panRecognizer
{
    if (self.phase == 3) {
        CGPoint touchlocation = [panRecognizer locationInView:self.imageView];
        int xposition;
        int yposition;
        if (horizontalImage == YES) {
            xposition = (int)(touchlocation.x * imageWidth/self.imageView.frame.size.width - ghostSize.width/2);
            yposition = (int)(touchlocation.y * imageWidth/self.imageView.frame.size.width - ghostSize.height/2 + imageHeight/2 - self.imageView.frame.size.height * imageWidth/self.imageView.frame.size.width/2);
        }
        else {
            xposition = (int)(touchlocation.x * imageHeight/self.imageView.frame.size.height - ghostSize.width/2 + imageWidth/2 - self.imageView.frame.size.width * imageHeight/self.imageView.frame.size.height/2);
            yposition = (int)(touchlocation.y * imageHeight/self.imageView.frame.size.height - ghostSize.height/2);
        }
        ghostOrigin = CGPointMake(xposition, yposition);
        CGContextDrawImage(imageContext, CGRectMake(0, 0, imageWidth, imageHeight), image);
        NSInteger offsetPixelCountForInput = ghostOrigin.y * imageWidth + ghostOrigin.x;
        iEnd = ghostSize.width;
        jEnd = ghostSize.height;
        iStart = 0;
        jStart = 0;
        if (ghostOrigin.x + ghostSize.width > imageWidth) {
            iEnd = (int)( - ghostOrigin.x + imageWidth);
        }
        if (ghostOrigin.y + ghostSize.height > imageHeight) {
            jEnd = (int)( -ghostOrigin.y + imageHeight);
        }
        if (ghostOrigin.x < 0) {
            iStart = 0 - ghostOrigin.x;
        }
        if (ghostOrigin.y < 0) {
            jStart = 0 - ghostOrigin.y;
        }
        for (int j = jStart; j < jEnd; j++) {
            for (int i = iStart; i < iEnd; i++) {
                UInt32 *inputPixel = imagePixels + j * imageWidth + i + offsetPixelCountForInput;
                UInt32 inputColor = *inputPixel;
                UInt32 *ghostPixel = ghostPixels + j * (int)ghostSize.width + i;
                UInt32 ghostColor = *ghostPixel;
                
                CGFloat ghostAlpha = (transValue) * (A(ghostColor) / 255.0);
                UInt32 newR = R(inputColor) * (1 - ghostAlpha) + R(ghostColor) * ghostAlpha;
                UInt32 newG = G(inputColor) * (1 - ghostAlpha) + G(ghostColor) * ghostAlpha;
                UInt32 newB = B(inputColor) * (1 - ghostAlpha) + B(ghostColor) * ghostAlpha;
                
                newR = MAX(0, MIN(255, newR));
                newG = MAX(0, MIN(255, newG));
                newB = MAX(0, MIN(255, newB));
                
                *inputPixel = RGBAMake(newR, newG, newB, A(inputColor));
            }
        }
        
        
        CGImageRef finalCGImage = CGBitmapContextCreateImage(imageContext);
        UIImage *finalImage = [UIImage imageWithCGImage:finalCGImage];
        self.imageView.image = finalImage;
    }
    
    
}





//imagePicker stuff

- (UIImagePickerController *)imagePickerController
{
    if (!_imagePickerController) {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.allowsEditing = NO;
        _imagePickerController.delegate = self;
    }
    return _imagePickerController;
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    if (self.phase == 1) {
        [self loadPickedImage:info[UIImagePickerControllerOriginalImage]];
    }
    if (self.phase == 2) {
        [self loadGhostImage:info[UIImagePickerControllerOriginalImage]];
    }
}


-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)image:(UIImage *)image
finishedSavingWithError:(NSError *)
error contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Save failed"
                              message: @"Failed to save image/video"
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"SAVE SUCCESSFUL!"
                                                       message: @"Your Photo Has Been Saved."
                                                      delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alert show];
        //self.buttonLeft.enabled = YES;
    }
}




//social networking stuff


- (IBAction)toFacebook:(id)sender {
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) //check if Facebook Account is linked
    {
        mySLComposerSheet = [[SLComposeViewController alloc] init]; //initiate the Social Controller
        mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook]; //Tell him with what social plattform to use it, e.g. facebook or twitter
        [mySLComposerSheet setInitialText:[NSString stringWithFormat:@"Check out my new photo, it has a ghost in it!:\n %@ \n", mySLComposerSheet.serviceType]]; //the message you want to post
        [mySLComposerSheet addImage:imageToPost]; //an image you could post
        //for more instance methodes, go here:https://developer.apple.com/library/ios/#documentation/NetworkingInternet/Reference/SLComposeViewController_Class/Reference/Reference.html#//apple_ref/doc/uid/TP40012205
        [self presentViewController:mySLComposerSheet animated:YES completion:nil];
    }
    else {
        UIAlertView *alert1 = [[UIAlertView alloc] initWithTitle:@"Unable to Post!" message:@"Please login to Facebook in your device settings." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert1 show];
        return;
    }
    [mySLComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
        NSString *output;
        switch (result) {
            case SLComposeViewControllerResultCancelled:
                output = @"Post Cancelled";
                break;
            case SLComposeViewControllerResultDone:
                output = @"Post Successfull";
                break;
            default:
                break;
        } //check if everything worked properly. Give out a message on the state.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook" message:output delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }];
}

- (IBAction)toTwitter:(id)sender {
    if(![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) //check if Facebook Account is linked
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unable to Tweet!" message:@"Please login to Twitter in your device settings." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
        return;
    }
    //self.mySLComposerSheet = [[SLComposeViewController alloc] init]; //initiate the Social Controller
    mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [mySLComposerSheet setInitialText:[NSString stringWithFormat:@"Check out my new photo, it has a ghost in it!:\n %@ \n", mySLComposerSheet.serviceType]]; //the message you want to post
    [mySLComposerSheet addImage:imageToPost];
    
    [self presentViewController:mySLComposerSheet animated:YES completion:nil];
    //}
    
    [mySLComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
        NSString *output;
        switch (result) {
            case SLComposeViewControllerResultCancelled:
                output = @"Post Cancelled";
                break;
            case SLComposeViewControllerResultDone:
                output = @"Post Successfull";
                break;
            default:
                break;
        } //check if everything worked properly. Give out a message on the state.
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Twitter" message:output delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alert show];
    }];
}


#pragma mark - UICollectionView DataSource


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 3;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"Cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    //cell.frame.size.height = 100;
    //cell.backgroundColor = [UIColor whiteColor];
    cell.layer.borderWidth = 2.0f;
    cell.layer.borderColor=[UIColor grayColor].CGColor;
    
    UIImageView *collectionImageView = (UIImageView *)[cell viewWithTag:100];
    
    collectionImageView.image = [UIImage imageNamed:[ghostLib objectAtIndex:indexPath.row]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //UIImage *tempLibImage = [ghostLib objectAtIndex:indexPath.row];
    //You may want to create a divider to scale the size by the way..
    CGFloat cellSize = (self.ghostCollectionView.frame.size.width - 20)/2;
    return CGSizeMake(cellSize, cellSize);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // If you need to use the touched cell, you can retrieve it like so
    //UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    [self loadGhostImage:[UIImage imageNamed:[ghostLib objectAtIndex:indexPath.row]]];
    self.blurView.hidden = YES;
    self.ghostCollectionView.hidden = YES;
    self.phase = 2;
    readyToGo = YES;
    self.goNext.enabled = YES;
    
    //NSLog(@"touched cell %@ at indexPath %@", cell, indexPath);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
    
}



@end
