//
//  DrawLinesView.h
//  Breadcrumb
//
//  Created by tengxiangyin on 13-8-29.
//
//

#import <UIKit/UIKit.h>
@protocol touchDelegate

- (void)touchBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchEnded:(NSSet *)touches withEvent:(UIEvent *)event;


@end

@interface DrawLinesView : UIImageView
@property (assign)id <touchDelegate> delegate;
@end
