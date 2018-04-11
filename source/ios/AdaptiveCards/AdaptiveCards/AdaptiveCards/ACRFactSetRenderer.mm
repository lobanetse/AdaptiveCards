//
//  ACRFactSetRenderer
//  ACRFactSetRenderer.mm
//
//  Copyright © 2017 Microsoft. All rights reserved.
//
#import "ACRTextBlockRenderer.h"
#import "ACRContentHoldingUIView.h"
#import "ACRFactSetRenderer.h"
#import "ACRSeparator.h"
#import "ACRColumnSetView.h"
#import "FactSet.h"
#import "ACOHostConfigPrivate.h"
#import "ACOBaseCardElementPrivate.h"
#import "ACRUILabel.h"

@implementation ACRFactSetRenderer

+ (ACRFactSetRenderer *)getInstance
{
    static ACRFactSetRenderer *singletonInstance = [[self alloc] init];
    return singletonInstance;
}

+ (ACRCardElementType)elemType
{
    return ACRFactSet;
}

+ (UILabel *)buildLabel:(NSString *)text
             hostConfig:(ACOHostConfig *)acoConfig
             textConfig:(TextConfig const &)textConfig
         containerStyle:(ACRContainerStyle)style
              elementId:(NSString *)elementId
               rootView:(ACRView *)rootView
                element:(std::shared_ptr<BaseCardElement> const &)element
{
    ACRUILabel *lab = [[ACRUILabel alloc] init];
    lab.translatesAutoresizingMaskIntoConstraints = NO;
    lab.style = style;
    __block NSMutableAttributedString *content = nil;
    if(rootView){
        NSMutableDictionary *textMap = [rootView getTextMap];
        // Syncronize access to imageViewMap
        dispatch_sync([rootView getSerialTextQueue], ^{
            if(textMap[elementId]) { // if content is available, get it, otherwise cache label, so it can be used used later
                content = textMap[elementId];
            } else {
                textMap[elementId] = lab;
            }
        });
    }

    if(content){

        std::shared_ptr<HostConfig> config = [acoConfig getHostConfig];
        // Set paragraph style such as line break mode and alignment
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = textConfig.wrap ? NSLineBreakByWordWrapping:NSLineBreakByTruncatingTail;

        // Obtain text color to apply to the attributed string
        ACRContainerStyle style = lab.style;
        ColorsConfig &colorConfig = (style == ACREmphasis) ? config->containerStyles.emphasisPalette.foregroundColors :
                                                             config->containerStyles.defaultPalette.foregroundColors;

        // Add paragraph style, text color, text weight as attributes to a NSMutableAttributedString, content.
        [content addAttributes:@{NSParagraphStyleAttributeName:paragraphStyle,
                                NSForegroundColorAttributeName:[ACOHostConfig getTextBlockColor:textConfig.color colorsConfig:colorConfig subtleOption:textConfig.isSubtle],
                                    NSStrokeWidthAttributeName:[ACOHostConfig getTextStrokeWidthForWeight:textConfig.weight]}
                         range:NSMakeRange(0, content.length)];
        lab.attributedText = content;

        std::string ID = element->GetId();
        std::size_t idx = ID.find_last_of('_');
        if(std::string::npos != idx){
            element->SetId(ID.substr(0, idx));
        }
    }

    lab.numberOfLines = textConfig.wrap ? 0 : 1;

    return lab;
}

- (UIView *)render:(UIView<ACRIContentHoldingView> *)viewGroup
          rootView:(ACRView *)rootView
            inputs:(NSMutableArray *)inputs
   baseCardElement:(ACOBaseCardElement *)acoElem
        hostConfig:(ACOHostConfig *)acoConfig;
{
    std::shared_ptr<HostConfig> config = [acoConfig getHostConfig];
    std::shared_ptr<BaseCardElement> elem = [acoElem element];
    std::shared_ptr<FactSet> fctSet = std::dynamic_pointer_cast<FactSet>(elem);

    ACRContainerStyle style = [viewGroup style];
    NSString *key = [NSString stringWithCString:elem->GetId().c_str() encoding:[NSString defaultCStringEncoding]];
    key = [key stringByAppendingString:@"*"];
    int rowFactId = 0;

    UIStackView *titleStack = [[UIStackView alloc] init];
    titleStack.axis = UILayoutConstraintAxisVertical;

    UIStackView *valueStack = [[UIStackView alloc] init];
    valueStack.axis = UILayoutConstraintAxisVertical;

    ACRColumnSetView *factSetWrapperView = [[ACRColumnSetView alloc] init];
    [factSetWrapperView addArrangedSubview:titleStack];
    [titleStack setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [ACRSeparator renderSeparationWithFrame:CGRectMake(0, 0, config->factSet.spacing, config->factSet.spacing) superview:factSetWrapperView axis:UILayoutConstraintAxisHorizontal];
    [factSetWrapperView addArrangedSubview:valueStack];
    [ACRSeparator renderSeparationWithFrame:CGRectMake(0, 0, config->factSet.spacing, config->factSet.spacing) superview:factSetWrapperView axis:UILayoutConstraintAxisHorizontal];

    [factSetWrapperView adjustHuggingForLastElement];

    for(auto fact :fctSet->GetFacts())
    {
        NSString *title = [NSString stringWithCString:fact->GetTitle().c_str() encoding:NSUTF8StringEncoding];
        UILabel *titleLab = [ACRFactSetRenderer buildLabel:title
                                                hostConfig:acoConfig
                                                textConfig:config->factSet.title
                                            containerStyle:style
                                                 elementId:[key stringByAppendingString:[[NSNumber numberWithInt:rowFactId++] stringValue]]
                                                  rootView:rootView
                                                   element:elem];
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:titleLab attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:config->factSet.title.maxWidth];
        constraint.active = YES;
        constraint.priority = UILayoutPriorityDefaultHigh;
        NSString *value = [NSString stringWithCString:fact->GetValue().c_str() encoding:NSUTF8StringEncoding];
        UILabel *valueLab = [ACRFactSetRenderer buildLabel:value
                                                hostConfig:acoConfig
                                                textConfig:config->factSet.value
                                            containerStyle:style
                                                 elementId:[key stringByAppendingString:[[NSNumber numberWithInt:rowFactId++] stringValue]]
                                                  rootView:rootView
                                                   element:elem];
        [titleStack addArrangedSubview:titleLab];
        [valueStack addArrangedSubview:valueLab];
        [NSLayoutConstraint constraintWithItem:valueLab attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:titleLab attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0].active = YES;
    }

    [viewGroup addArrangedSubview:factSetWrapperView];

    return factSetWrapperView;
}
@end
