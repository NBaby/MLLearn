//
//  MLTestViewController.m
//  MLTest
//
//  Created by panzihao on 2018/8/13.
//  Copyright © 2018年 panzihao. All rights reserved.
//

#import "MLTestViewController.h"
#import "animal.h"

@interface MLTestViewController ()

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@property (strong, nonatomic) animal *netModel;

@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@end

@implementation MLTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUp];
}


- (void)setUp{
    _netModel =  [[animal alloc] init];
    
}

- (IBAction)tapPhotoBtn:(id)sender {
    
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    //判断数据来源为相册
    picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    //设置代理
    picker.delegate = self;
    //打开相册
    [self presentViewController:picker animated:YES completion:nil];
    
    
    
    
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    //获取图片
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    self.photoView.image = image;
    UIImage * newSizeImage = [self scaleToSize:CGSizeMake(299, 299) image:image];
    
    CVPixelBufferRef imageRef = [self pixelBufferFromCGImage:newSizeImage.CGImage];
    
    NSError * error = nil;
    animalOutput * outPut = [_netModel predictionFromImage:imageRef error:&error];
    if (error == nil) {
        NSNumber * num = [outPut.classLabelProbs objectForKey:outPut.classLabel];
        NSString * resultStr = [NSString stringWithFormat:@"%@ : %.2lf",outPut.classLabel,[num doubleValue]];

        self.resultLabel.text = resultStr;
    }
    else {
        self.resultLabel.text = error.description;
    }
    
}

//用户取消选择
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (UIImage *)scaleToSize:(CGSize)size image:(UIImage *)image {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}





- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image{
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = CGImageGetWidth(image);
    CGFloat frameHeight = CGImageGetHeight(image);
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, CGRectMake(0,
                                           0,
                                           frameWidth,
                                           frameHeight),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
