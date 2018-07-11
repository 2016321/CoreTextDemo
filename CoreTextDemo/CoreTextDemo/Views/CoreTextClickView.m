//
//  CoreTextClickView.m
//  CoreTextDemo
//
//  Created by Bingo on 2018/7/9.
//  Copyright © 2018年 Bingo. All rights reserved.
//

#import "CoreTextClickView.h"
#import <CoreText/CoreText.h>

NSString *const CoreTextHighLightAttributeName = @"CoreTextHighLightAttributeName";

typedef void(^CoreTextHighLightBlock)(NSDictionary *parameter);

@interface CoreTextClickModel: NSObject

@property (nonatomic, copy) CoreTextHighLightBlock coreTextHighLightBlock;

@property (nonatomic, assign) CGRect rect;

@property (nonatomic, assign) NSRange range;

@property (nonatomic, copy) NSString *string;

@end

@implementation CoreTextClickModel

@end

@interface CoreTextClickView()

@property (nonatomic, strong) NSMutableDictionary *clickDic;

@end

@implementation CoreTextClickView

- (NSMutableDictionary *)clickDic{
    if (!_clickDic) {
        _clickDic = [NSMutableDictionary dictionary];
    }
    return _clickDic;
}


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
    
    NSMutableAttributedString *attachment1 = [self getAttachment:(CGSizeMake(160, 100)) imageName:@"ShadowFiend"];
    [att insertAttributedString:attachment1 atIndex:20];
    
    [self setHighLight:att range:(NSMakeRange(23, 20)) action:^(NSDictionary *parameter) {
        [[[UIAlertView alloc] initWithTitle:@"click text" message:[NSString stringWithFormat:@"parameter:\n%@",parameter] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
    }];
    [self setHighLight:att range:(NSMakeRange(20, 1)) action:^(NSDictionary *parameter) {
        [[[UIAlertView alloc] initWithTitle:@"click image" message:[NSString stringWithFormat:@"parameter:\n%@",parameter] delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil] show];
    }];
    
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
            NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
            //判断是否有绑定的点击方法
            if (attributes[CoreTextHighLightAttributeName]) {
                //将范围、绘制区域、
                CFRange _range = CTRunGetStringRange(run);
                NSRange range = NSMakeRange((long)_range.location, (long)_range.length);
                CGRect rect = [self drawWithRectangle:frame line:line run:run point:point];
                CoreTextClickModel *model = attributes[CoreTextHighLightAttributeName];
                model.string = [att attributedSubstringFromRange:range].string;
                model.range = range;
                model.rect = rect;
                NSValue *value = [NSValue valueWithCGRect:rect];
                self.clickDic[value] = model;
            }
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
    callBacks.dealloc = ClickDelegateDeallocCallback;
    callBacks.getAscent = ClickDelegateAscentCallBacks;
    callBacks.getDescent = ClickDelegateDescentCallBacks;
    callBacks.getWidth = ClickDelegateWidthCallBacks;
    //设置代理回调的对象
    NSString *sizeStr = NSStringFromCGSize(size);
    //初始化CTRun回调代理
    CTRunDelegateRef delegate = CTRunDelegateCreate(&callBacks, (__bridge void *)sizeStr);
    //先设置一个占位的空格
    unichar placeHolder = 0xFFFC;
    NSString * placeHolderStr = [NSString stringWithCharacters:&placeHolder length:1];
    NSMutableAttributedString * imageAttachment = [[NSMutableAttributedString alloc] initWithString:placeHolderStr];
    //设置图片名
    [imageAttachment addAttribute:@"imageName" value:imageName range:(NSMakeRange(0, 1))];
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)imageAttachment, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
    CFRelease(delegate);
    
    return imageAttachment;
}

void ClickDelegateDeallocCallback (void *refCon){
    NSLog(@"dealloc");
}

CGFloat ClickDelegateAscentCallBacks(void * refCon){
    CGSize size = CGSizeFromString((__bridge NSString *)refCon);
    return size.height;
}

CGFloat ClickDelegateDescentCallBacks(void * refCon){
    return 0;
}

CGFloat ClickDelegateWidthCallBacks(void * refCon){
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
    CGRect drawBounds = [self drawWithRectangle:frame line:line run:run point:point];
    NSValue *value = [NSValue valueWithCGRect:drawBounds];
    NSLog(@"---------%lu", (unsigned long)value.hash);
    NSDictionary *dic = @{
                          @(value.hash): value
                          };
    
    NSLog(@"%@ ------- %lu", dic, (unsigned long)value.hash);
    [self drawWithImageName:imageName rect:drawBounds];
}

- (CGRect)drawWithRectangle:(CTFrameRef)frame line:(CTLineRef)line run:(CTRunRef)run point:(CGPoint)point{
    CGFloat ascent;
    CGFloat descent;
    CGRect bounds;
    bounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
    bounds.size.height = ascent + descent;
    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
    bounds.origin.x = point.x + xOffset;
    bounds.origin.y = point.y - descent;
    CGPathRef path = CTFrameGetPath(frame);
    CGRect cutRect = CGPathGetBoundingBox(path);
    CGRect drawBounds = CGRectOffset(bounds, cutRect.origin.x, cutRect.origin.y);
    return drawBounds;
}

- (void)drawWithImageName:(NSString *)imageName rect:(CGRect)rect{
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIImage * image = [UIImage imageNamed:imageName];
    CGContextDrawImage(context, rect, image.CGImage);
}

- (void)setHighLight:(NSMutableAttributedString *)att range:(NSRange)range action:(CoreTextHighLightBlock)action{
    if (att.length < range.location + range.length) {
        return;
    }
    CoreTextClickModel *model = [CoreTextClickModel new];
    model.coreTextHighLightBlock = action;
    [att addAttribute:CoreTextHighLightAttributeName value:model range:range];
    [att addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:range];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    [self.clickDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSValue *value = key;
        CGRect rect = [self convertRect:value.CGRectValue];
        if (CGRectContainsPoint(rect, location)) {
            CoreTextClickModel *model = obj;
            NSDictionary *parameter = @{
                                        @"string": model.string,
                                        @"range": [NSValue valueWithRange:model.range],
                                        @"rect":[NSValue valueWithCGRect:model.rect]
                                        };
            model.coreTextHighLightBlock(parameter);
            *stop = YES;
        }
    }];
}

-(CGRect)convertRect:(CGRect)rect{
    return CGRectMake(rect.origin.x, self.bounds.size.height - rect.origin.y - rect.size.height, rect.size.width, rect.size.height);
}

@end
