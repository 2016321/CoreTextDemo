//
//  CoreTextImageView.m
//  CoreTextDemo
//
//  Created by Bingo on 2018/7/9.
//  Copyright © 2018年 Bingo. All rights reserved.
//

#import "CoreTextImageView.h"
#import <CoreText/CoreText.h>

@implementation CoreTextImageView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    //1.获取绘制的上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //2.初始化要绘制的区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    //3.对坐标进行转换
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context , 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    //4.1 初始化富文本文字部分
    NSMutableAttributedString *att = [self getAtt];
    
    //4.2 初始化富文本图片部分
    NSMutableAttributedString *attachment = [self getAttachment:(CGSizeMake(50, 50)) imageName:@"SuperMary"];
    [att insertAttributedString:attachment atIndex:3];
    
    NSMutableAttributedString *attachment1 = [self getAttachment:(CGSizeMake(80, 50)) imageName:@"ShadowFiend"];
    [att insertAttributedString:attachment1 atIndex:20];
    
    //5.初始化绘制区域的工厂对象
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)att);
    
    //6.初始化绘制区域
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, [att length]), path, NULL);
    
    //7.遍历行之后遍历本行的CTRun进行绘制
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineNumber =  CFArrayGetCount(lines);
    CGPoint lineOrigins[lineNumber];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
    for (int i = 0 ; i < CFArrayGetCount(lines); i++) {
        CGPoint point = lineOrigins[i];
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGContextSetTextPosition(context, point.x, point.y);
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        CFIndex runNumber = CFArrayGetCount(runs);
        for (int j = 0; j < runNumber; j++) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            
            //判断本CTRun是否与图片相对应
            if ([self isImageAttachment:run]) {
                [self drawImage:frame line:line run:run point:point];
            }
            CTRunDraw(run, context, CFRangeMake(0, 0));
        }
    }
    
    //8.释放之前申请的内容
    CFRelease(path);
    CFRelease(frameSetter);
    CFRelease(frame);
}

//创建富文本文字部分
- (NSMutableAttributedString *)getAtt{
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:@"Core Text, Core Text, Core Text, Core Text, Core Text, Core Text, "];
    CTFontRef font = CTFontCreateWithName(CFSTR("PingFang SC"), 24, NULL);
    [att addAttribute:(id)kCTFontAttributeName value:(__bridge id)font  range:NSMakeRange(0, att.length)];
    long number = 10;
    CFNumberRef num = CFNumberCreate(kCFAllocatorDefault,kCFNumberSInt8Type,&number);
    [att addAttribute:(id)kCTKernAttributeName value:(__bridge id)num range:NSMakeRange(10, 4)];
    return att;
}

//创建富文本图片部分
- (NSMutableAttributedString *)getAttachment:(CGSize)size imageName:(NSString *)imageName{
    //初始化CTRun回调代理结构体
    CTRunDelegateCallbacks callBacks;
    callBacks.version = kCTRunDelegateVersion1;
    callBacks.dealloc = DelegateDeallocCallback;
    callBacks.getAscent = DelegateAscentCallBacks;
    callBacks.getDescent = DelegateDescentCallBacks;
    callBacks.getWidth = DelegateWidthCallBacks;
    //设置代理回调的对象
    NSString *sizeStr = NSStringFromCGSize(size);
    //初始化CTRun回调代理
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callBacks, (__bridge void *)sizeStr);
    //先设置一个占位的空格
    NSMutableAttributedString * imageAttachment = [[NSMutableAttributedString alloc] initWithString:@" "];
    //设置图片名
    [imageAttachment addAttribute:@"imageName" value:imageName range:(NSMakeRange(0, 1))];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)imageAttachment, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    
    return imageAttachment;
}

void DelegateDeallocCallback (void *refCon){
    NSLog(@"dealloc");
}

CGFloat DelegateAscentCallBacks(void * refCon){
    CGSize size = CGSizeFromString((__bridge NSString *)refCon);
    return size.height;
}

CGFloat DelegateDescentCallBacks(void * refCon){
    return 0;
}

CGFloat DelegateWidthCallBacks(void * refCon){
    CGSize size = CGSizeFromString((__bridge NSString *)refCon);
    return size.width;
}

- (BOOL)isImageAttachment:(CTRunRef)run{
    NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
    CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];
    NSString *sizeStr = CTRunDelegateGetRefCon(delegate);
    if (delegate == nil || ![sizeStr isKindOfClass:[NSString class]]) {
        return NO;
    }
    return YES;
}

- (void)drawImage:(CTFrameRef)frame line:(CTLineRef)line run:(CTRunRef)run point:(CGPoint)point{
    
    NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
    NSString *imageName = attributes[@"imageName"];
    if (!imageName) {
        return;
    }
    CGFloat ascent;
    CGFloat descent;
    CGRect bounds;
    bounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
    bounds.size.height = ascent + descent;
    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
    bounds.origin.x = point.x + xOffset;
    bounds.origin.y = point.y - descent;
    CGPathRef path = CTFrameGetPath(frame);
    CGRect colRect = CGPathGetBoundingBox(path);
    CGRect imageBounds = CGRectOffset(bounds, colRect.origin.x, colRect.origin.y);
    
    [self drawWithImageName:imageName rect:imageBounds];
}

- (void)drawWithImageName:(NSString *)imageName rect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIImage * image = [UIImage imageNamed:imageName];
    CGContextDrawImage(context, rect, image.CGImage);
}

@end

