/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2014-2022 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#pragma once

#include "CSSCounterStyleRegistry.h"
#include "CSSCounterStyleRule.h"
#include "CSSCounterValue.h"
#include "CSSCursorImageValue.h"
#include "CSSFontValue.h"
#include "CSSFontVariantAlternatesValue.h"
#include "CSSGradientValue.h"
#include "CSSGridTemplateAreasValue.h"
#include "CSSPropertyParserHelpers.h"
#include "CSSRectValue.h"
#include "CSSRegisteredCustomProperty.h"
#include "CSSShadowValue.h"
#include "CounterContent.h"
#include "CursorList.h"
#include "ElementAncestorIterator.h"
#include "FontVariantBuilder.h"
#include "Frame.h"
#include "HTMLElement.h"
#include "SVGElement.h"
#include "SVGRenderStyle.h"
#include "StyleBuilderConverter.h"
#include "StyleCachedImage.h"
#include "StyleCursorImage.h"
#include "StyleFontSizeFunctions.h"
#include "StyleGeneratedImage.h"
#include "StyleImageSet.h"
#include "StyleResolver.h"
#include "StyleScope.h"
#include "WillChangeData.h"

namespace WebCore {
namespace Style {

#define DECLARE_PROPERTY_CUSTOM_HANDLERS(property) \
    static void applyInherit##property(BuilderState&); \
    static void applyInitial##property(BuilderState&); \
    static void applyValue##property(BuilderState&, CSSValue&)

template<typename T> inline T forwardInheritedValue(T&& value) { return std::forward<T>(value); }
inline Length forwardInheritedValue(const Length& value) { auto copy = value; return copy; }
inline LengthSize forwardInheritedValue(const LengthSize& value) { auto copy = value; return copy; }
inline LengthBox forwardInheritedValue(const LengthBox& value) { auto copy = value; return copy; }
inline GapLength forwardInheritedValue(const GapLength& value) { auto copy = value; return copy; }

// Note that we assume the CSS parser only allows valid CSSValue types.
class BuilderCustom {
public:
    // Custom handling of inherit, initial and value setting.
    DECLARE_PROPERTY_CUSTOM_HANDLERS(AspectRatio);
    // FIXME: <https://webkit.org/b/212506> Teach makeprop.pl to generate setters for hasExplicitlySet* flags
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BorderBottomLeftRadius);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BorderBottomRightRadius);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BorderTopLeftRadius);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BorderTopRightRadius);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BorderImageOutset);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BorderImageRepeat);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BorderImageSlice);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BorderImageWidth);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(BoxShadow);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(CaretColor);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(Clip);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(Contain);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(ContainIntrinsicWidth);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(ContainIntrinsicHeight);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(Content);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(CounterIncrement);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(CounterReset);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(Cursor);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(Fill);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(FontFamily);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(FontSize);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(FontStyle);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(FontVariantAlternates);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(FontVariantLigatures);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(FontVariantNumeric);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(FontVariantEastAsian);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(GridTemplateAreas);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(GridTemplateColumns);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(GridTemplateRows);
#if ENABLE(CSS_IMAGE_RESOLUTION)
    DECLARE_PROPERTY_CUSTOM_HANDLERS(ImageResolution);
#endif
    DECLARE_PROPERTY_CUSTOM_HANDLERS(LetterSpacing);
#if ENABLE(TEXT_AUTOSIZING)
    DECLARE_PROPERTY_CUSTOM_HANDLERS(LineHeight);
#endif
    DECLARE_PROPERTY_CUSTOM_HANDLERS(ListStyleType);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(OutlineStyle);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(Size);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(Stroke);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(TextEmphasisStyle);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(TextIndent);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(TextShadow);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(WebkitBoxShadow);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(WebkitMaskBoxImageOutset);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(WebkitMaskBoxImageRepeat);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(WebkitMaskBoxImageSlice);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(WebkitMaskBoxImageWidth);
    DECLARE_PROPERTY_CUSTOM_HANDLERS(Zoom);

    // Custom handling of initial + inherit value setting only.
    static void applyInitialFontFeatureSettings(BuilderState&) { }
    static void applyInheritFontFeatureSettings(BuilderState&) { }
    static void applyInitialFontVariationSettings(BuilderState&);
    static void applyInheritFontVariationSettings(BuilderState&);
    static void applyInitialWebkitMaskImage(BuilderState&) { }
    static void applyInheritWebkitMaskImage(BuilderState&) { }

    // Custom handling of inherit + value setting only.
    static void applyInheritDisplay(BuilderState&);
    static void applyValueDisplay(BuilderState&, CSSValue&);
    static void applyInheritVerticalAlign(BuilderState&);
    static void applyValueVerticalAlign(BuilderState&, CSSValue&);
    static void applyInheritBaselineShift(BuilderState&);
    static void applyValueBaselineShift(BuilderState&, CSSValue&);

    // Custom handling of value setting only.
    static void applyValueDirection(BuilderState&, CSSValue&);
    static void applyValueWebkitLocale(BuilderState&, CSSValue&);
    static void applyValueTextOrientation(BuilderState&, CSSValue&);
#if ENABLE(TEXT_AUTOSIZING)
    static void applyValueWebkitTextSizeAdjust(BuilderState&, CSSValue&);
#endif
    static void applyValueWebkitTextZoom(BuilderState&, CSSValue&);
    static void applyValueWritingMode(BuilderState&, CSSValue&);
    static void applyValueAlt(BuilderState&, CSSValue&);
    static void applyValueWillChange(BuilderState&, CSSValue&);
    static void applyValueFontSizeAdjust(BuilderState&, CSSValue&);

#if ENABLE(DARK_MODE_CSS)
    static void applyValueColorScheme(BuilderState&, CSSValue&);
#endif

    static void applyValueStrokeWidth(BuilderState&, CSSValue&);
    static void applyValueStrokeColor(BuilderState&, CSSValue&);

    static void applyInitialCustomProperty(BuilderState&, const CSSRegisteredCustomProperty*, const AtomString& name);
    static void applyInheritCustomProperty(BuilderState&, const CSSRegisteredCustomProperty*, const AtomString& name);
    static void applyValueCustomProperty(BuilderState&, const CSSRegisteredCustomProperty*, const CSSCustomPropertyValue&);

    static void applyValueColor(BuilderState&, CSSValue&);

private:
    static void resetEffectiveZoom(BuilderState&);

    static Length mmLength(double mm);
    static Length inchLength(double inch);
    static bool getPageSizeFromName(CSSPrimitiveValue* pageSizeName, CSSPrimitiveValue* pageOrientation, Length& width, Length& height);

    template <CSSPropertyID id>
    static void applyTextOrBoxShadowValue(BuilderState&, CSSValue&);
    static bool isValidDisplayValue(BuilderState&, DisplayType);

    enum CounterBehavior {Increment = 0, Reset};
    template <CounterBehavior counterBehavior>
    static void applyInheritCounter(BuilderState&);
    template <CounterBehavior counterBehavior>
    static void applyValueCounter(BuilderState&, CSSValue&);

    static float largerFontSize(float size);
    static float smallerFontSize(float size);
    static float determineRubyTextSizeMultiplier(BuilderState&);
};

inline void BuilderCustom::applyValueDirection(BuilderState& builderState, CSSValue& value)
{
    builderState.style().setDirection(fromCSSValue<TextDirection>(value));
    builderState.style().setHasExplicitlySetDirection(true);
}

inline void BuilderCustom::resetEffectiveZoom(BuilderState& builderState)
{
    // Reset the zoom in effect. This allows the setZoom method to accurately compute a new zoom in effect.
    builderState.setEffectiveZoom(builderState.parentStyle().effectiveZoom());
}

inline void BuilderCustom::applyInitialZoom(BuilderState& builderState)
{
    resetEffectiveZoom(builderState);
    builderState.setZoom(RenderStyle::initialZoom());
}

inline void BuilderCustom::applyInheritZoom(BuilderState& builderState)
{
    resetEffectiveZoom(builderState);
    builderState.setZoom(builderState.parentStyle().zoom());
}

inline void BuilderCustom::applyValueZoom(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);

    if (primitiveValue.valueID() == CSSValueNormal) {
        resetEffectiveZoom(builderState);
        builderState.setZoom(RenderStyle::initialZoom());
    } else if (primitiveValue.valueID() == CSSValueReset) {
        builderState.setEffectiveZoom(RenderStyle::initialZoom());
        builderState.setZoom(RenderStyle::initialZoom());
    } else if (primitiveValue.valueID() == CSSValueDocument) {
        float docZoom = builderState.rootElementStyle() ? builderState.rootElementStyle()->zoom() : RenderStyle::initialZoom();
        builderState.setEffectiveZoom(docZoom);
        builderState.setZoom(docZoom);
    } else if (primitiveValue.isPercentage()) {
        resetEffectiveZoom(builderState);
        if (float percent = primitiveValue.floatValue())
            builderState.setZoom(percent / 100.0f);
    } else if (primitiveValue.isNumber()) {
        resetEffectiveZoom(builderState);
        if (float number = primitiveValue.floatValue())
            builderState.setZoom(number);
    }
}

inline Length BuilderCustom::mmLength(double mm)
{
    return CSSPrimitiveValue::create(mm, CSSUnitType::CSS_MM).get().computeLength<Length>({ });
}

inline Length BuilderCustom::inchLength(double inch)
{
    return CSSPrimitiveValue::create(inch, CSSUnitType::CSS_IN).get().computeLength<Length>({ });
}

bool BuilderCustom::getPageSizeFromName(CSSPrimitiveValue* pageSizeName, CSSPrimitiveValue* pageOrientation, Length& width, Length& height)
{
    static NeverDestroyed<Length> a5Width(mmLength(148));
    static NeverDestroyed<Length> a5Height(mmLength(210));
    static NeverDestroyed<Length> a4Width(mmLength(210));
    static NeverDestroyed<Length> a4Height(mmLength(297));
    static NeverDestroyed<Length> a3Width(mmLength(297));
    static NeverDestroyed<Length> a3Height(mmLength(420));
    static NeverDestroyed<Length> b5Width(mmLength(176));
    static NeverDestroyed<Length> b5Height(mmLength(250));
    static NeverDestroyed<Length> b4Width(mmLength(250));
    static NeverDestroyed<Length> b4Height(mmLength(353));
    static NeverDestroyed<Length> letterWidth(inchLength(8.5));
    static NeverDestroyed<Length> letterHeight(inchLength(11));
    static NeverDestroyed<Length> legalWidth(inchLength(8.5));
    static NeverDestroyed<Length> legalHeight(inchLength(14));
    static NeverDestroyed<Length> ledgerWidth(inchLength(11));
    static NeverDestroyed<Length> ledgerHeight(inchLength(17));

    if (!pageSizeName)
        return false;

    switch (pageSizeName->valueID()) {
    case CSSValueA5:
        width = a5Width;
        height = a5Height;
        break;
    case CSSValueA4:
        width = a4Width;
        height = a4Height;
        break;
    case CSSValueA3:
        width = a3Width;
        height = a3Height;
        break;
    case CSSValueB5:
        width = b5Width;
        height = b5Height;
        break;
    case CSSValueB4:
        width = b4Width;
        height = b4Height;
        break;
    case CSSValueLetter:
        width = letterWidth;
        height = letterHeight;
        break;
    case CSSValueLegal:
        width = legalWidth;
        height = legalHeight;
        break;
    case CSSValueLedger:
        width = ledgerWidth;
        height = ledgerHeight;
        break;
    default:
        return false;
    }

    if (pageOrientation) {
        switch (pageOrientation->valueID()) {
        case CSSValueLandscape:
            std::swap(width, height);
            break;
        case CSSValuePortrait:
            // Nothing to do.
            break;
        default:
            return false;
        }
    }
    return true;
}

inline void BuilderCustom::applyInheritVerticalAlign(BuilderState& builderState)
{
    builderState.style().setVerticalAlignLength(forwardInheritedValue(builderState.parentStyle().verticalAlignLength()));
    builderState.style().setVerticalAlign(forwardInheritedValue(builderState.parentStyle().verticalAlign()));
}

inline void BuilderCustom::applyValueVerticalAlign(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (primitiveValue.valueID() != CSSValueInvalid)
        builderState.style().setVerticalAlign(fromCSSValueID<VerticalAlign>(primitiveValue.valueID()));
    else
        builderState.style().setVerticalAlignLength(primitiveValue.convertToLength<FixedIntegerConversion | PercentConversion | CalculatedConversion>(builderState.cssToLengthConversionData()));
}

#if ENABLE(CSS_IMAGE_RESOLUTION)

inline void BuilderCustom::applyInheritImageResolution(BuilderState& builderState)
{
    builderState.style().setImageResolutionSource(builderState.parentStyle().imageResolutionSource());
    builderState.style().setImageResolutionSnap(builderState.parentStyle().imageResolutionSnap());
    builderState.style().setImageResolution(builderState.parentStyle().imageResolution());
}

inline void BuilderCustom::applyInitialImageResolution(BuilderState& builderState)
{
    builderState.style().setImageResolutionSource(RenderStyle::initialImageResolutionSource());
    builderState.style().setImageResolutionSnap(RenderStyle::initialImageResolutionSnap());
    builderState.style().setImageResolution(RenderStyle::initialImageResolution());
}

inline void BuilderCustom::applyValueImageResolution(BuilderState& builderState, CSSValue& value)
{
    ImageResolutionSource source = RenderStyle::initialImageResolutionSource();
    ImageResolutionSnap snap = RenderStyle::initialImageResolutionSnap();
    double resolution = RenderStyle::initialImageResolution();
    for (auto& item : downcast<CSSValueList>(value)) {
        CSSPrimitiveValue& primitiveValue = downcast<CSSPrimitiveValue>(item.get());
        if (primitiveValue.valueID() == CSSValueFromImage)
            source = ImageResolutionSource::FromImage;
        else if (primitiveValue.valueID() == CSSValueSnap)
            snap = ImageResolutionSnap::Pixels;
        else
            resolution = primitiveValue.doubleValue(CSSUnitType::CSS_DPPX);
    }
    builderState.style().setImageResolutionSource(source);
    builderState.style().setImageResolutionSnap(snap);
    builderState.style().setImageResolution(resolution);
}

#endif // ENABLE(CSS_IMAGE_RESOLUTION)

inline void BuilderCustom::applyInheritSize(BuilderState&)
{
}

inline void BuilderCustom::applyInitialSize(BuilderState&)
{
}

inline void BuilderCustom::applyValueSize(BuilderState& builderState, CSSValue& value)
{
    builderState.style().resetPageSizeType();

    if (!is<CSSValueList>(value))
        return;

    Length width;
    Length height;
    PageSizeType pageSizeType = PAGE_SIZE_AUTO;

    auto& valueList = downcast<CSSValueList>(value);
    switch (valueList.length()) {
    case 2: {
        auto firstValue = valueList.itemWithoutBoundsCheck(0);
        auto secondValue = valueList.itemWithoutBoundsCheck(1);
        // <length>{2} | <page-size> <orientation>
        if (!is<CSSPrimitiveValue>(*firstValue) || !is<CSSPrimitiveValue>(*secondValue))
            return;
        auto& firstPrimitiveValue = downcast<CSSPrimitiveValue>(*firstValue);
        auto& secondPrimitiveValue = downcast<CSSPrimitiveValue>(*secondValue);
        if (firstPrimitiveValue.isLength()) {
            // <length>{2}
            if (!secondPrimitiveValue.isLength())
                return;
            CSSToLengthConversionData conversionData = builderState.cssToLengthConversionData().copyWithAdjustedZoom(1.0f);
            width = firstPrimitiveValue.computeLength<Length>(conversionData);
            height = secondPrimitiveValue.computeLength<Length>(conversionData);
        } else {
            // <page-size> <orientation>
            // The value order is guaranteed. See CSSParser::parseSizeParameter.
            if (!getPageSizeFromName(&firstPrimitiveValue, &secondPrimitiveValue, width, height))
                return;
        }
        pageSizeType = PAGE_SIZE_RESOLVED;
        break;
    }
    case 1: {
        auto value = valueList.itemWithoutBoundsCheck(0);
        // <length> | auto | <page-size> | [ portrait | landscape]
        if (!is<CSSPrimitiveValue>(*value))
            return;
        auto& primitiveValue = downcast<CSSPrimitiveValue>(*value);
        if (primitiveValue.isLength()) {
            // <length>
            pageSizeType = PAGE_SIZE_RESOLVED;
            width = height = primitiveValue.computeLength<Length>(builderState.cssToLengthConversionData().copyWithAdjustedZoom(1.0f));
        } else {
            switch (primitiveValue.valueID()) {
            case 0:
                return;
            case CSSValueAuto:
                pageSizeType = PAGE_SIZE_AUTO;
                break;
            case CSSValuePortrait:
                pageSizeType = PAGE_SIZE_AUTO_PORTRAIT;
                break;
            case CSSValueLandscape:
                pageSizeType = PAGE_SIZE_AUTO_LANDSCAPE;
                break;
            default:
                // <page-size>
                pageSizeType = PAGE_SIZE_RESOLVED;
                if (!getPageSizeFromName(&primitiveValue, nullptr, width, height))
                    return;
            }
        }
        break;
    }
    default:
        return;
    }
    builderState.style().setPageSizeType(pageSizeType);
    builderState.style().setPageSize({ WTFMove(width), WTFMove(height) });
}

inline void BuilderCustom::applyInheritTextIndent(BuilderState& builderState)
{
    builderState.style().setTextIndent(Length { builderState.parentStyle().textIndent() });
    builderState.style().setTextIndentLine(builderState.parentStyle().textIndentLine());
    builderState.style().setTextIndentType(builderState.parentStyle().textIndentType());
}

inline void BuilderCustom::applyInitialTextIndent(BuilderState& builderState)
{
    builderState.style().setTextIndent(RenderStyle::initialTextIndent());
    builderState.style().setTextIndentLine(RenderStyle::initialTextIndentLine());
    builderState.style().setTextIndentType(RenderStyle::initialTextIndentType());
}

inline void BuilderCustom::applyValueTextIndent(BuilderState& builderState, CSSValue& value)
{
    Length lengthOrPercentageValue;
    TextIndentLine textIndentLineValue = RenderStyle::initialTextIndentLine();
    TextIndentType textIndentTypeValue = RenderStyle::initialTextIndentType();

    if (auto* valueList = dynamicDowncast<CSSValueList>(value)) {
        for (auto& item : *valueList) {
            auto& primitiveValue = downcast<CSSPrimitiveValue>(item.get());
            if (!primitiveValue.valueID())
                lengthOrPercentageValue = primitiveValue.convertToLength<FixedIntegerConversion | PercentConversion | CalculatedConversion>(builderState.cssToLengthConversionData());
            else if (primitiveValue.valueID() == CSSValueEachLine)
                textIndentLineValue = TextIndentLine::EachLine;
            else if (primitiveValue.valueID() == CSSValueHanging)
                textIndentTypeValue = TextIndentType::Hanging;
        }
    } else if (auto* primitiveValue = dynamicDowncast<CSSPrimitiveValue>(value)) {
        // Values coming from CSSTypedOM didn't go through the parser and may not have been converted to a CSSValueList.
        lengthOrPercentageValue = primitiveValue->convertToLength<FixedIntegerConversion | PercentConversion | CalculatedConversion>(builderState.cssToLengthConversionData());
    } else
        return;

    if (lengthOrPercentageValue.isUndefined())
        return;

    builderState.style().setTextIndent(WTFMove(lengthOrPercentageValue));
    builderState.style().setTextIndentLine(textIndentLineValue);
    builderState.style().setTextIndentType(textIndentTypeValue);
}

enum BorderImageType { BorderImage, WebkitMaskBoxImage };
enum BorderImageModifierType { Outset, Repeat, Slice, Width };
template<BorderImageType type, BorderImageModifierType modifier>
class ApplyPropertyBorderImageModifier {
public:
    static void applyInheritValue(BuilderState& builderState)
    {
        NinePieceImage image(getValue(builderState.style()));
        switch (modifier) {
        case Outset:
            image.copyOutsetFrom(getValue(builderState.parentStyle()));
            break;
        case Repeat:
            image.copyRepeatFrom(getValue(builderState.parentStyle()));
            break;
        case Slice:
            image.copyImageSlicesFrom(getValue(builderState.parentStyle()));
            break;
        case Width:
            image.copyBorderSlicesFrom(getValue(builderState.parentStyle()));
            break;
        }
        setValue(builderState.style(), image);
    }

    static void applyInitialValue(BuilderState& builderState)
    {
        NinePieceImage image(getValue(builderState.style()));
        switch (modifier) {
        case Outset:
            image.setOutset(LengthBox(LengthType::Relative));
            break;
        case Repeat:
            image.setHorizontalRule(NinePieceImageRule::Stretch);
            image.setVerticalRule(NinePieceImageRule::Stretch);
            break;
        case Slice:
            // Masks have a different initial value for slices. Preserve the value of "0 fill" for backwards compatibility.
            image.setImageSlices(type == BorderImage ? LengthBox(Length(100, LengthType::Percent), Length(100, LengthType::Percent), Length(100, LengthType::Percent), Length(100, LengthType::Percent)) : LengthBox(LengthType::Fixed));
            image.setFill(type != BorderImage);
            break;
        case Width:
            // FIXME: This is a local variable to work around a bug in the GCC 8.1 Address Sanitizer.
            // Might be slightly less efficient when the type is not BorderImage since this is unused in that case.
            // Should be switched back to a temporary when possible. See https://webkit.org/b/186980
            LengthBox lengthBox(Length(1, LengthType::Relative), Length(1, LengthType::Relative), Length(1, LengthType::Relative), Length(1, LengthType::Relative));
            // Masks have a different initial value for widths. They use an 'auto' value rather than trying to fit to the border.
            image.setBorderSlices(type == BorderImage ? lengthBox : LengthBox());
            image.setOverridesBorderWidths(false);
            break;
        }
        setValue(builderState.style(), image);
    }

    static void applyValue(BuilderState& builderState, CSSValue& value)
    {
        NinePieceImage image(getValue(builderState.style()));
        switch (modifier) {
        case Outset:
            image.setOutset(builderState.styleMap().mapNinePieceImageQuad(value));
            break;
        case Repeat:
            builderState.styleMap().mapNinePieceImageRepeat(value, image);
            break;
        case Slice:
            builderState.styleMap().mapNinePieceImageSlice(value, image);
            break;
        case Width:
            builderState.styleMap().mapNinePieceImageWidth(value, image);
            break;
        }
        setValue(builderState.style(), image);
    }

private:
    static const NinePieceImage& getValue(const RenderStyle& style)
    {
        return type == BorderImage ? style.borderImage() : style.maskBoxImage();
    }

    static void setValue(RenderStyle& style, const NinePieceImage& value)
    {
        return type == BorderImage ? style.setBorderImage(value) : style.setMaskBoxImage(value);
    }
};

#define DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(type, modifier) \
inline void BuilderCustom::applyInherit##type##modifier(BuilderState& builderState) \
{ \
    ApplyPropertyBorderImageModifier<type, modifier>::applyInheritValue(builderState); \
} \
inline void BuilderCustom::applyInitial##type##modifier(BuilderState& builderState) \
{ \
    ApplyPropertyBorderImageModifier<type, modifier>::applyInitialValue(builderState); \
} \
inline void BuilderCustom::applyValue##type##modifier(BuilderState& builderState, CSSValue& value) \
{ \
    ApplyPropertyBorderImageModifier<type, modifier>::applyValue(builderState, value); \
}

DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(BorderImage, Outset)
DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(BorderImage, Repeat)
DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(BorderImage, Slice)
DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(BorderImage, Width)
DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(WebkitMaskBoxImage, Outset)
DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(WebkitMaskBoxImage, Repeat)
DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(WebkitMaskBoxImage, Slice)
DEFINE_BORDER_IMAGE_MODIFIER_HANDLER(WebkitMaskBoxImage, Width)

static inline void applyLetterSpacing(BuilderState& builderState, float letterSpacing)
{
    // Setting the letter-spacing from a positive value to another positive value shouldn't require fonts to get updated.

    bool shouldDisableLigaturesForSpacing = letterSpacing;
    if (shouldDisableLigaturesForSpacing != builderState.fontDescription().shouldDisableLigaturesForSpacing()) {
        auto fontDescription = builderState.fontDescription();
        fontDescription.setShouldDisableLigaturesForSpacing(letterSpacing);
        builderState.setFontDescription(WTFMove(fontDescription));
    }

    builderState.style().setLetterSpacingWithoutUpdatingFontDescription(letterSpacing);
}

inline void BuilderCustom::applyInheritLetterSpacing(BuilderState& builderState)
{
    applyLetterSpacing(builderState, builderState.parentStyle().letterSpacing());
}

inline void BuilderCustom::applyInitialLetterSpacing(BuilderState& builderState)
{
    applyLetterSpacing(builderState, RenderStyle::initialLetterSpacing());
}

void maybeUpdateFontForLetterSpacing(BuilderState& builderState, CSSValue& value)
{
    // This is unfortunate. It's related to https://github.com/w3c/csswg-drafts/issues/5498.
    //
    // From StyleBuilder's point of view, there's a dependency cycle:
    // letter-spacing accepts an arbitrary <length>, which must be resolved against a font, which must
    // be selected after all the properties that affect font selection are processed, but letter-spacing
    // itself affects font selection because it can disable font features. StyleBuilder has some (valid)
    // ASSERT()s which would fire because of this cycle.
    //
    // There isn't *actually* a dependency cycle, though, as none of the font-relative units are
    // actually sensitive to font features (luckily). The problem is that our StyleBuilder is only
    // smart enough to consider fonts as one indivisible thing, rather than having the deeper
    // understanding that different parts of fonts may or may not depend on each other.
    //
    // So, we update the font early here, so that if there is a font-relative unit inside the CSSValue,
    // its font is updated and ready to go. In the worst case there might be a second call to
    // updateFont() later, but that isn't bad for perf because 1. It only happens twice if there is
    // actually a font-relative unit passed to letter-spacing, and 2. updateFont() internally has logic
    // to only do work if the font is actually dirty.

    if (is<CSSPrimitiveValue>(value)) {
        auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
        if (primitiveValue.isFontRelativeLength() || primitiveValue.isCalculated())
            builderState.updateFont();
    }
}

inline void BuilderCustom::applyValueLetterSpacing(BuilderState& builderState, CSSValue& value)
{
    maybeUpdateFontForLetterSpacing(builderState, value);
    applyLetterSpacing(builderState, BuilderConverter::convertSpacing(builderState, value));
}

#if ENABLE(TEXT_AUTOSIZING)

inline void BuilderCustom::applyInheritLineHeight(BuilderState& builderState)
{
    builderState.style().setLineHeight(Length { builderState.parentStyle().lineHeight() });
    builderState.style().setSpecifiedLineHeight(Length { builderState.parentStyle().specifiedLineHeight() });
}

inline void BuilderCustom::applyInitialLineHeight(BuilderState& builderState)
{
    builderState.style().setLineHeight(RenderStyle::initialLineHeight());
    builderState.style().setSpecifiedLineHeight(RenderStyle::initialSpecifiedLineHeight());
}

static inline float computeBaseSpecifiedFontSize(const Document& document, const RenderStyle& style, bool percentageAutosizingEnabled)
{
    float result = style.specifiedFontSize();
    auto* frame = document.frame();
    if (frame && style.textZoom() != TextZoom::Reset)
        result *= frame->textZoomFactor();
    result *= style.effectiveZoom();
    if (percentageAutosizingEnabled
        && (!document.settings().textAutosizingUsesIdempotentMode() || document.settings().idempotentModeAutosizingOnlyHonorsPercentages()))
        result *= style.textSizeAdjust().multiplier();
    return result;
}

static inline float computeLineHeightMultiplierDueToFontSize(const Document& document, const RenderStyle& style, const CSSPrimitiveValue& value)
{
    bool percentageAutosizingEnabled = document.settings().textAutosizingEnabled() && style.textSizeAdjust().isPercentage();

    if (value.isLength()) {
        auto minimumFontSize = document.settings().minimumFontSize();
        if (minimumFontSize > 0) {
            auto specifiedFontSize = computeBaseSpecifiedFontSize(document, style, percentageAutosizingEnabled);
            // Small font sizes cause a preposterously large (near infinity) line-height. Add a fuzz-factor of 1px which opts out of
            // boosted line-height.
            if (specifiedFontSize < minimumFontSize && specifiedFontSize >= 1) {
                // FIXME: There are two settings which are relevant here: minimum font size, and minimum logical font size (as
                // well as things like the zoom property, text zoom on the page, and text autosizing). The minimum logical font
                // size is nonzero by default, and already incorporated into the computed font size, so if we just use the ratio
                // of the computed : specified font size, it will be > 1 in the cases where the minimum logical font size kicks
                // in. In general, this is the right thing to do, however, this kind of blanket change is too risky to perform
                // right now. https://bugs.webkit.org/show_bug.cgi?id=174570 tracks turning this on. For now, we can just pretend
                // that the minimum font size is the only thing affecting the computed font size.

                // This calculation matches the line-height computed size calculation in
                // TextAutoSizing::Value::adjustTextNodeSizes().
                auto scaleChange = minimumFontSize / specifiedFontSize;
                return scaleChange;
            }
        }
    }

    if (percentageAutosizingEnabled && !document.settings().textAutosizingUsesIdempotentMode())
        return style.textSizeAdjust().multiplier();
    return 1;
}

inline void BuilderCustom::applyValueLineHeight(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value) && CSSPropertyParserHelpers::isSystemFontShorthand(downcast<CSSPrimitiveValue>(value).valueID())) {
        applyInitialLineHeight(builderState);
        return;
    }

    auto lineHeight = BuilderConverter::convertLineHeight(builderState, value, 1);

    Length computedLineHeight;
    if (lineHeight.isNegative())
        computedLineHeight = lineHeight;
    else {
        auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
        auto multiplier = computeLineHeightMultiplierDueToFontSize(builderState.document(), builderState.style(), primitiveValue);
        if (multiplier == 1)
            computedLineHeight = lineHeight;
        else
            computedLineHeight = BuilderConverter::convertLineHeight(builderState, value, multiplier);
    }

    builderState.style().setLineHeight(WTFMove(computedLineHeight));
    builderState.style().setSpecifiedLineHeight(WTFMove(lineHeight));
}

#endif

inline void BuilderCustom::applyInheritListStyleType(BuilderState& builderState)
{
    builderState.style().setListStyleType(builderState.parentStyle().listStyleType());
    builderState.style().setListStyleStringValue(builderState.parentStyle().listStyleStringValue());
}

inline void BuilderCustom::applyInitialListStyleType(BuilderState& builderState)
{
    builderState.style().setListStyleType(RenderStyle::initialListStyleType());
    builderState.style().setListStyleStringValue(RenderStyle::initialListStyleStringValue());
}

inline void BuilderCustom::applyValueListStyleType(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (primitiveValue.isValueID()) {
        builderState.style().setListStyleType(fromCSSValue<ListStyleType>(primitiveValue));
        builderState.style().setListStyleStringValue(RenderStyle::initialListStyleStringValue());
        return;
    }
    // FIXME: handle counter-style: rdar://102988393.
    // We should skip handling counter style until we can represent all systems with CSSCounterStyle::text(). We currently don't accept custom-ident in list-style-type parser-grammar (CSSProperties.json).
    if (primitiveValue.isCustomIdent()) {
        builderState.style().setListStyleType(ListStyleType::CustomCounterStyle);
        builderState.style().setListStyleStringValue(makeAtomString(primitiveValue.stringValue()));
        return;
    }
    builderState.style().setListStyleType(ListStyleType::String);
    builderState.style().setListStyleStringValue(AtomString { primitiveValue.stringValue() });
}

inline void BuilderCustom::applyInheritOutlineStyle(BuilderState& builderState)
{
    builderState.style().setOutlineStyleIsAuto(builderState.parentStyle().outlineStyleIsAuto());
    builderState.style().setOutlineStyle(builderState.parentStyle().outlineStyle());
}

inline void BuilderCustom::applyInitialOutlineStyle(BuilderState& builderState)
{
    builderState.style().setOutlineStyleIsAuto(RenderStyle::initialOutlineStyleIsAuto());
    builderState.style().setOutlineStyle(RenderStyle::initialBorderStyle());
}

inline void BuilderCustom::applyValueOutlineStyle(BuilderState& builderState, CSSValue& value)
{
    builderState.style().setOutlineStyleIsAuto(fromCSSValue<OutlineIsAuto>(value));
    builderState.style().setOutlineStyle(fromCSSValue<BorderStyle>(value));
}

inline void BuilderCustom::applyInitialCaretColor(BuilderState& builderState)
{
    if (builderState.applyPropertyToRegularStyle())
        builderState.style().setHasAutoCaretColor();
    if (builderState.applyPropertyToVisitedLinkStyle())
        builderState.style().setHasVisitedLinkAutoCaretColor();
}

inline void BuilderCustom::applyInheritCaretColor(BuilderState& builderState)
{
    auto color = builderState.parentStyle().caretColor();
    if (builderState.applyPropertyToRegularStyle()) {
        if (builderState.parentStyle().hasAutoCaretColor())
            builderState.style().setHasAutoCaretColor();
        else
            builderState.style().setCaretColor(color);
    }
    if (builderState.applyPropertyToVisitedLinkStyle()) {
        if (builderState.parentStyle().hasVisitedLinkAutoCaretColor())
            builderState.style().setHasVisitedLinkAutoCaretColor();
        else
            builderState.style().setVisitedLinkCaretColor(color);
    }
}

inline void BuilderCustom::applyValueCaretColor(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (builderState.applyPropertyToRegularStyle()) {
        if (primitiveValue.valueID() == CSSValueAuto)
            builderState.style().setHasAutoCaretColor();
        else
            builderState.style().setCaretColor(builderState.colorFromPrimitiveValue(primitiveValue, ForVisitedLink::No));
    }
    if (builderState.applyPropertyToVisitedLinkStyle()) {
        if (primitiveValue.valueID() == CSSValueAuto)
            builderState.style().setHasVisitedLinkAutoCaretColor();
        else
            builderState.style().setVisitedLinkCaretColor(builderState.colorFromPrimitiveValue(primitiveValue, ForVisitedLink::Yes));
    }
}

inline void BuilderCustom::applyInitialClip(BuilderState& builderState)
{
    builderState.style().setClip(Length(), Length(), Length(), Length());
    builderState.style().setHasClip(false);
}

inline void BuilderCustom::applyInheritClip(BuilderState& builderState)
{
    auto& parentStyle = builderState.parentStyle();
    if (!parentStyle.hasClip())
        return applyInitialClip(builderState);
    builderState.style().setClip(Length { parentStyle.clipTop() }, Length { parentStyle.clipRight() },
        Length { parentStyle.clipBottom() }, Length { parentStyle.clipLeft() });
    builderState.style().setHasClip(true);
}

inline void BuilderCustom::applyValueClip(BuilderState& builderState, CSSValue& value)
{
    if (value.isRect()) {
        auto& conversionData = builderState.cssToLengthConversionData();
        auto top = value.rect().top().convertToLength<FixedIntegerConversion | PercentConversion | AutoConversion>(conversionData);
        auto right = value.rect().right().convertToLength<FixedIntegerConversion | PercentConversion | AutoConversion>(conversionData);
        auto bottom = value.rect().bottom().convertToLength<FixedIntegerConversion | PercentConversion | AutoConversion>(conversionData);
        auto left = value.rect().left().convertToLength<FixedIntegerConversion | PercentConversion | AutoConversion>(conversionData);
        builderState.style().setClip(WTFMove(top), WTFMove(right), WTFMove(bottom), WTFMove(left));
        builderState.style().setHasClip(true);
    } else {
        ASSERT(value.valueID() == CSSValueAuto);
        applyInitialClip(builderState);
    }
}

inline void BuilderCustom::applyValueWebkitLocale(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);

    FontCascadeDescription fontDescription = builderState.fontDescription();
    if (primitiveValue.valueID() == CSSValueAuto)
        fontDescription.setSpecifiedLocale(nullAtom());
    else
        fontDescription.setSpecifiedLocale(AtomString { primitiveValue.stringValue() });
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyValueWritingMode(BuilderState& builderState, CSSValue& value)
{
    builderState.setWritingMode(fromCSSValue<WritingMode>(value));
    builderState.style().setHasExplicitlySetWritingMode(true);
}

inline void BuilderCustom::applyValueTextOrientation(BuilderState& builderState, CSSValue& value)
{
    builderState.setTextOrientation(fromCSSValue<TextOrientation>(value));
}

#if ENABLE(TEXT_AUTOSIZING)
inline void BuilderCustom::applyValueWebkitTextSizeAdjust(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (primitiveValue.valueID() == CSSValueAuto)
        builderState.style().setTextSizeAdjust(TextSizeAdjustment(AutoTextSizeAdjustment));
    else if (primitiveValue.valueID() == CSSValueNone)
        builderState.style().setTextSizeAdjust(TextSizeAdjustment(NoTextSizeAdjustment));
    else
        builderState.style().setTextSizeAdjust(TextSizeAdjustment(primitiveValue.floatValue()));

    builderState.setFontDirty();
}
#endif

inline void BuilderCustom::applyValueWebkitTextZoom(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (primitiveValue.valueID() == CSSValueNormal)
        builderState.style().setTextZoom(TextZoom::Normal);
    else if (primitiveValue.valueID() == CSSValueReset)
        builderState.style().setTextZoom(TextZoom::Reset);
    builderState.setFontDirty();
}

#if ENABLE(DARK_MODE_CSS)
inline void BuilderCustom::applyValueColorScheme(BuilderState& builderState, CSSValue& value)
{
    builderState.style().setColorScheme(BuilderConverter::convertColorScheme(builderState, value));
    builderState.style().setHasExplicitlySetColorScheme(true);
}
#endif

template<CSSPropertyID property>
inline void BuilderCustom::applyTextOrBoxShadowValue(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value)) {
        ASSERT(downcast<CSSPrimitiveValue>(value).valueID() == CSSValueNone);
        if (property == CSSPropertyTextShadow)
            builderState.style().setTextShadow(nullptr);
        else
            builderState.style().setBoxShadow(nullptr);
        return;
    }

    bool isFirstEntry = true;
    for (auto& item : downcast<CSSValueList>(value)) {
        auto& shadowValue = downcast<CSSShadowValue>(item.get());
        auto& conversionData = builderState.cssToLengthConversionData();
        auto x = shadowValue.x->computeLength<Length>(conversionData);
        auto y = shadowValue.y->computeLength<Length>(conversionData);
        auto blur = shadowValue.blur ? shadowValue.blur->computeLength<Length>(conversionData) : Length(0, LengthType::Fixed);
        auto spread = shadowValue.spread ? shadowValue.spread->computeLength<Length>(conversionData) : Length(0, LengthType::Fixed);
        ShadowStyle shadowStyle = shadowValue.style && shadowValue.style->valueID() == CSSValueInset ? ShadowStyle::Inset : ShadowStyle::Normal;
        Color color;
        if (shadowValue.color)
            color = builderState.colorFromPrimitiveValueWithResolvedCurrentColor(*shadowValue.color);
        else
            color = builderState.style().color();

        auto shadowData = makeUnique<ShadowData>(LengthPoint(x, y), blur, spread, shadowStyle, property == CSSPropertyWebkitBoxShadow, color.isValid() ? color : Color::transparentBlack);
        if (property == CSSPropertyTextShadow)
            builderState.style().setTextShadow(WTFMove(shadowData), !isFirstEntry); // add to the list if this is not the first entry
        else
            builderState.style().setBoxShadow(WTFMove(shadowData), !isFirstEntry); // add to the list if this is not the first entry
        isFirstEntry = false;
    }
}

inline void BuilderCustom::applyInitialTextShadow(BuilderState& builderState)
{
    builderState.style().setTextShadow(nullptr);
}

inline void BuilderCustom::applyInheritTextShadow(BuilderState& builderState)
{
    builderState.style().setTextShadow(builderState.parentStyle().textShadow() ? makeUnique<ShadowData>(*builderState.parentStyle().textShadow()) : nullptr);
}

inline void BuilderCustom::applyValueTextShadow(BuilderState& builderState, CSSValue& value)
{
    applyTextOrBoxShadowValue<CSSPropertyTextShadow>(builderState, value);
}

inline void BuilderCustom::applyInitialBoxShadow(BuilderState& builderState)
{
    builderState.style().setBoxShadow(nullptr);
}

inline void BuilderCustom::applyInheritBoxShadow(BuilderState& builderState)
{
    builderState.style().setBoxShadow(builderState.parentStyle().boxShadow() ? makeUnique<ShadowData>(*builderState.parentStyle().boxShadow()) : nullptr);
}

inline void BuilderCustom::applyValueBoxShadow(BuilderState& builderState, CSSValue& value)
{
    applyTextOrBoxShadowValue<CSSPropertyBoxShadow>(builderState, value);
}

inline void BuilderCustom::applyInitialWebkitBoxShadow(BuilderState& builderState)
{
    applyInitialBoxShadow(builderState);
}

inline void BuilderCustom::applyInheritWebkitBoxShadow(BuilderState& builderState)
{
    applyInheritBoxShadow(builderState);
}

inline void BuilderCustom::applyValueWebkitBoxShadow(BuilderState& builderState, CSSValue& value)
{
    applyTextOrBoxShadowValue<CSSPropertyWebkitBoxShadow>(builderState, value);
}

inline void BuilderCustom::applyInitialFontFamily(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    auto initialDesc = FontCascadeDescription();

    // We need to adjust the size to account for the generic family change from monospace to non-monospace.
    if (fontDescription.useFixedDefaultSize()) {
        if (CSSValueID sizeIdentifier = fontDescription.keywordSizeAsIdentifier())
            builderState.setFontSize(fontDescription, Style::fontSizeForKeyword(sizeIdentifier, false, builderState.document()));
    }
    if (!initialDesc.firstFamily().isEmpty())
        fontDescription.setFamilies(initialDesc.families());

    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInheritFontFamily(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    auto parentFontDescription = builderState.parentStyle().fontDescription();

    fontDescription.setFamilies(parentFontDescription.families());
    fontDescription.setIsSpecifiedFont(parentFontDescription.isSpecifiedFont());
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyValueFontFamily(BuilderState& builderState, CSSValue& value)
{
    auto fontDescription = builderState.fontDescription();
    // Before mapping in a new font-family property, we should reset the generic family.
    bool oldFamilyUsedFixedDefaultSize = fontDescription.useFixedDefaultSize();

    Vector<AtomString> families;

    if (is<CSSPrimitiveValue>(value)) {
        auto valueID = downcast<CSSPrimitiveValue>(value).valueID();
        ASSERT(CSSPropertyParserHelpers::isSystemFontShorthand(valueID));
        AtomString family = SystemFontDatabase::singleton().systemFontShorthandFamily(CSSPropertyParserHelpers::lowerFontShorthand(valueID));
        ASSERT(!family.isEmpty());
        fontDescription.setIsSpecifiedFont(false);
        families = Vector<AtomString>::from(WTFMove(family));
    } else {
        auto& valueList = downcast<CSSValueList>(value);
        families.reserveInitialCapacity(valueList.length());
        for (auto& item : valueList) {
            auto& contentValue = downcast<CSSPrimitiveValue>(item.get());
            AtomString family;
            bool isGenericFamily = false;
            if (contentValue.isFontFamily())
                family = AtomString { contentValue.stringValue() };
            else if (contentValue.valueID() == CSSValueWebkitBody)
                family = AtomString { builderState.document().settings().standardFontFamily() };
            else {
                isGenericFamily = true;
                family = CSSPropertyParserHelpers::genericFontFamily(contentValue.valueID());
            }
            if (family.isEmpty())
                continue;
            if (families.isEmpty())
                fontDescription.setIsSpecifiedFont(!isGenericFamily);
            families.uncheckedAppend(WTFMove(family));
        }
        if (families.isEmpty())
            return;
    }

    fontDescription.setFamilies(families);

    if (fontDescription.useFixedDefaultSize() != oldFamilyUsedFixedDefaultSize) {
        if (CSSValueID sizeIdentifier = fontDescription.keywordSizeAsIdentifier())
            builderState.setFontSize(fontDescription, Style::fontSizeForKeyword(sizeIdentifier, !oldFamilyUsedFixedDefaultSize, builderState.document()));
    }

    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInitialBorderBottomLeftRadius(BuilderState& builderState)
{
    builderState.style().setBorderBottomLeftRadius(RenderStyle::initialBorderRadius());
    builderState.style().setHasExplicitlySetBorderBottomLeftRadius(false);
}

inline void BuilderCustom::applyInheritBorderBottomLeftRadius(BuilderState& builderState)
{
    builderState.style().setBorderBottomLeftRadius(forwardInheritedValue(builderState.parentStyle().borderBottomLeftRadius()));
    builderState.style().setHasExplicitlySetBorderBottomLeftRadius(builderState.parentStyle().hasExplicitlySetBorderBottomLeftRadius());
}

inline void BuilderCustom::applyValueBorderBottomLeftRadius(BuilderState& builderState, CSSValue& value)
{
    builderState.style().setBorderBottomLeftRadius(BuilderConverter::convertRadius(builderState, value));
    builderState.style().setHasExplicitlySetBorderBottomLeftRadius(true);
}

inline void BuilderCustom::applyInitialBorderBottomRightRadius(BuilderState& builderState)
{
    builderState.style().setBorderBottomRightRadius(RenderStyle::initialBorderRadius());
    builderState.style().setHasExplicitlySetBorderBottomRightRadius(false);
}

inline void BuilderCustom::applyInheritBorderBottomRightRadius(BuilderState& builderState)
{
    builderState.style().setBorderBottomRightRadius(forwardInheritedValue(builderState.parentStyle().borderBottomRightRadius()));
    builderState.style().setHasExplicitlySetBorderBottomRightRadius(builderState.parentStyle().hasExplicitlySetBorderBottomRightRadius());
}

inline void BuilderCustom::applyValueBorderBottomRightRadius(BuilderState& builderState, CSSValue& value)
{
    builderState.style().setBorderBottomRightRadius(BuilderConverter::convertRadius(builderState, value));
    builderState.style().setHasExplicitlySetBorderBottomRightRadius(true);
}

inline void BuilderCustom::applyInitialBorderTopLeftRadius(BuilderState& builderState)
{
    builderState.style().setBorderTopLeftRadius(RenderStyle::initialBorderRadius());
    builderState.style().setHasExplicitlySetBorderTopLeftRadius(false);
}

inline void BuilderCustom::applyInheritBorderTopLeftRadius(BuilderState& builderState)
{
    builderState.style().setBorderTopLeftRadius(forwardInheritedValue(builderState.parentStyle().borderTopLeftRadius()));
    builderState.style().setHasExplicitlySetBorderTopLeftRadius(builderState.parentStyle().hasExplicitlySetBorderTopLeftRadius());
}

inline void BuilderCustom::applyValueBorderTopLeftRadius(BuilderState& builderState, CSSValue& value)
{
    builderState.style().setBorderTopLeftRadius(BuilderConverter::convertRadius(builderState, value));
    builderState.style().setHasExplicitlySetBorderTopLeftRadius(true);
}

inline void BuilderCustom::applyInitialBorderTopRightRadius(BuilderState& builderState)
{
    builderState.style().setBorderTopRightRadius(RenderStyle::initialBorderRadius());
    builderState.style().setHasExplicitlySetBorderTopRightRadius(false);
}

inline void BuilderCustom::applyInheritBorderTopRightRadius(BuilderState& builderState)
{
    builderState.style().setBorderTopRightRadius(forwardInheritedValue(builderState.parentStyle().borderTopRightRadius()));
    builderState.style().setHasExplicitlySetBorderTopRightRadius(builderState.parentStyle().hasExplicitlySetBorderTopRightRadius());
}

inline void BuilderCustom::applyValueBorderTopRightRadius(BuilderState& builderState, CSSValue& value)
{
    builderState.style().setBorderTopRightRadius(BuilderConverter::convertRadius(builderState, value));
    builderState.style().setHasExplicitlySetBorderTopRightRadius(true);
}

inline bool BuilderCustom::isValidDisplayValue(BuilderState& builderState, DisplayType display)
{
    if (is<SVGElement>(builderState.element()) && builderState.style().styleType() == PseudoId::None)
        return display == DisplayType::Inline || display == DisplayType::Block || display == DisplayType::None;
    return true;
}

inline void BuilderCustom::applyInitialFontVariationSettings(BuilderState& builderState)
{
    builderState.style().setFontVariationSettings({ });
}

inline void BuilderCustom::applyInheritFontVariationSettings(BuilderState& builderState)
{
    builderState.style().setFontVariationSettings(builderState.parentStyle().fontVariationSettings());
}

inline void BuilderCustom::applyInheritDisplay(BuilderState& builderState)
{
    DisplayType display = builderState.parentStyle().display();
    if (isValidDisplayValue(builderState, display))
        builderState.style().setDisplay(display);
}

inline void BuilderCustom::applyValueDisplay(BuilderState& builderState, CSSValue& value)
{
    auto display = fromCSSValue<DisplayType>(value);
    if (isValidDisplayValue(builderState, display))
        builderState.style().setDisplay(display);
}

inline void BuilderCustom::applyInheritBaselineShift(BuilderState& builderState)
{
    auto& svgStyle = builderState.style().accessSVGStyle();
    auto& svgParentStyle = builderState.parentStyle().svgStyle();
    svgStyle.setBaselineShift(forwardInheritedValue(svgParentStyle.baselineShift()));
    svgStyle.setBaselineShiftValue(forwardInheritedValue(svgParentStyle.baselineShiftValue()));
}

inline void BuilderCustom::applyValueBaselineShift(BuilderState& builderState, CSSValue& value)
{
    SVGRenderStyle& svgStyle = builderState.style().accessSVGStyle();
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (primitiveValue.isValueID()) {
        switch (primitiveValue.valueID()) {
        case CSSValueBaseline:
            svgStyle.setBaselineShift(BaselineShift::Baseline);
            break;
        case CSSValueSub:
            svgStyle.setBaselineShift(BaselineShift::Sub);
            break;
        case CSSValueSuper:
            svgStyle.setBaselineShift(BaselineShift::Super);
            break;
        default:
            break;
        }
    } else {
        svgStyle.setBaselineShift(BaselineShift::Length);
        svgStyle.setBaselineShiftValue(SVGLengthValue::fromCSSPrimitiveValue(primitiveValue, builderState.cssToLengthConversionData()));
    }
}

inline void BuilderCustom::applyInitialTextEmphasisStyle(BuilderState& builderState)
{
    builderState.style().setTextEmphasisFill(RenderStyle::initialTextEmphasisFill());
    builderState.style().setTextEmphasisMark(RenderStyle::initialTextEmphasisMark());
    builderState.style().setTextEmphasisCustomMark(RenderStyle::initialTextEmphasisCustomMark());
}

inline void BuilderCustom::applyInheritTextEmphasisStyle(BuilderState& builderState)
{
    builderState.style().setTextEmphasisFill(builderState.parentStyle().textEmphasisFill());
    builderState.style().setTextEmphasisMark(builderState.parentStyle().textEmphasisMark());
    builderState.style().setTextEmphasisCustomMark(builderState.parentStyle().textEmphasisCustomMark());
}

inline void BuilderCustom::applyInitialAspectRatio(BuilderState& builderState)
{
    builderState.style().setAspectRatioType(RenderStyle::initialAspectRatioType());
    builderState.style().setAspectRatio(RenderStyle::initialAspectRatioWidth(), RenderStyle::initialAspectRatioHeight());
}

inline void BuilderCustom::applyInheritAspectRatio(BuilderState&)
{
}

inline void BuilderCustom::applyValueAspectRatio(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value)) {
        ASSERT(downcast<CSSPrimitiveValue>(value).valueID() == CSSValueAuto);
        return builderState.style().setAspectRatioType(AspectRatioType::Auto);
    }

    if (!is<CSSValueList>(value))
        return;

    auto& list = downcast<CSSValueList>(value);
    if (list.item(1)->isValueList()) {
        builderState.style().setAspectRatioType(AspectRatioType::AutoAndRatio);
        auto ratioList = downcast<CSSValueList>(list.item(1));
        ASSERT(ratioList->length() == 2);
        builderState.style().setAspectRatio(downcast<CSSPrimitiveValue>(ratioList->item(0))->doubleValue(), downcast<CSSPrimitiveValue>(ratioList->item(1))->doubleValue());
        return;
    }

    ASSERT(list.length() == 2);
    auto width = downcast<CSSPrimitiveValue>(list.item(0))->doubleValue();
    auto height = downcast<CSSPrimitiveValue>(list.item(1))->doubleValue();
    if (!width || !height)
        builderState.style().setAspectRatioType(AspectRatioType::AutoZero);
    else
        builderState.style().setAspectRatioType(AspectRatioType::Ratio);
    builderState.style().setAspectRatio(width, height);
}

inline void BuilderCustom::applyInitialContain(BuilderState& builderState)
{
    builderState.style().setContain(RenderStyle::initialContainment());
}

inline void BuilderCustom::applyInheritContain(BuilderState& builderState)
{
    builderState.style().setContain(forwardInheritedValue(builderState.parentStyle().contain()));
}

inline void BuilderCustom::applyValueContain(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value)) {
        if (downcast<CSSPrimitiveValue>(value).valueID() == CSSValueNone)
            return builderState.style().setContain(RenderStyle::initialContainment());
        if (downcast<CSSPrimitiveValue>(value).valueID() == CSSValueStrict)
            return builderState.style().setContain(RenderStyle::strictContainment());
        return builderState.style().setContain(RenderStyle::contentContainment());
    }

    if (!is<CSSValueList>(value))
        return;

    OptionSet<Containment> containment;
    auto& list = downcast<CSSValueList>(value);
    for (auto& item : list) {
        auto& value = downcast<CSSPrimitiveValue>(item.get());
        switch (value.valueID()) {
        case CSSValueSize:
            containment.add(Containment::Size);
            break;
        case CSSValueInlineSize:
            containment.add(Containment::InlineSize);
            break;
        case CSSValueLayout:
            containment.add(Containment::Layout);
            break;
        case CSSValuePaint:
            containment.add(Containment::Paint);
            break;
        case CSSValueStyle:
            containment.add(Containment::Style);
            break;
        default:
            break;
        };
    }
    return builderState.style().setContain(containment);
}

inline void BuilderCustom::applyValueTextEmphasisStyle(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSValueList>(value)) {
        auto& list = downcast<CSSValueList>(value);
        ASSERT(list.length() == 2);

        for (auto& item : list) {
            auto valueID = downcast<CSSPrimitiveValue>(item.get()).valueID();
            if (valueID == CSSValueFilled || valueID == CSSValueOpen)
                builderState.style().setTextEmphasisFill(fromCSSValueID<TextEmphasisFill>(valueID));
            else
                builderState.style().setTextEmphasisMark(fromCSSValueID<TextEmphasisMark>(valueID));
        }
        builderState.style().setTextEmphasisCustomMark(nullAtom());
        return;
    }

    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (primitiveValue.isString()) {
        builderState.style().setTextEmphasisFill(TextEmphasisFill::Filled);
        builderState.style().setTextEmphasisMark(TextEmphasisMark::Custom);
        builderState.style().setTextEmphasisCustomMark(AtomString { primitiveValue.stringValue() });
        return;
    }

    builderState.style().setTextEmphasisCustomMark(nullAtom());

    if (primitiveValue.valueID() == CSSValueFilled || primitiveValue.valueID() == CSSValueOpen) {
        builderState.style().setTextEmphasisFill(fromCSSValue<TextEmphasisFill>(value));
        builderState.style().setTextEmphasisMark(TextEmphasisMark::Auto);
    } else {
        builderState.style().setTextEmphasisFill(TextEmphasisFill::Filled);
        builderState.style().setTextEmphasisMark(fromCSSValue<TextEmphasisMark>(value));
    }
}

template <BuilderCustom::CounterBehavior counterBehavior>
inline void BuilderCustom::applyInheritCounter(BuilderState& builderState)
{
    auto& map = builderState.style().accessCounterDirectives();
    for (auto& keyValue : const_cast<RenderStyle&>(builderState.parentStyle()).accessCounterDirectives()) {
        auto& directives = map.add(keyValue.key, CounterDirectives { }).iterator->value;
        if (counterBehavior == Reset)
            directives.resetValue = keyValue.value.resetValue;
        else
            directives.incrementValue = keyValue.value.incrementValue;
    }
}

template <BuilderCustom::CounterBehavior counterBehavior>
inline void BuilderCustom::applyValueCounter(BuilderState& builderState, CSSValue& value)
{
    bool setCounterIncrementToNone = counterBehavior == Increment && is<CSSPrimitiveValue>(value) && downcast<CSSPrimitiveValue>(value).valueID() == CSSValueNone;

    if (!is<CSSValueList>(value) && !setCounterIncrementToNone)
        return;

    CounterDirectiveMap& map = builderState.style().accessCounterDirectives();
    for (auto& keyValue : map) {
        if (counterBehavior == Reset)
            keyValue.value.resetValue = std::nullopt;
        else
            keyValue.value.incrementValue = std::nullopt;
    }

    if (setCounterIncrementToNone)
        return;

    for (auto& item : downcast<CSSValueList>(value)) {
        AtomString identifier { downcast<CSSPrimitiveValue>(item->first()).stringValue() };
        int value = downcast<CSSPrimitiveValue>(item->second()).intValue();
        auto& directives = map.add(identifier, CounterDirectives { }).iterator->value;
        if (counterBehavior == Reset)
            directives.resetValue = value;
        else
            directives.incrementValue = saturatedSum(directives.incrementValue.value_or(0), value);
    }
}

inline void BuilderCustom::applyInitialCounterIncrement(BuilderState&)
{
}

inline void BuilderCustom::applyInheritCounterIncrement(BuilderState& builderState)
{
    applyInheritCounter<Increment>(builderState);
}

inline void BuilderCustom::applyValueCounterIncrement(BuilderState& builderState, CSSValue& value)
{
    applyValueCounter<Increment>(builderState, value);
}

inline void BuilderCustom::applyInitialCounterReset(BuilderState&)
{
}

inline void BuilderCustom::applyInheritCounterReset(BuilderState& builderState)
{
    applyInheritCounter<Reset>(builderState);
}

inline void BuilderCustom::applyValueCounterReset(BuilderState& builderState, CSSValue& value)
{
    applyValueCounter<Reset>(builderState, value);
}

inline void BuilderCustom::applyInitialCursor(BuilderState& builderState)
{
    builderState.style().clearCursorList();
    builderState.style().setCursor(RenderStyle::initialCursor());
}

inline void BuilderCustom::applyInheritCursor(BuilderState& builderState)
{
    builderState.style().setCursor(builderState.parentStyle().cursor());
    builderState.style().setCursorList(builderState.parentStyle().cursors());
}

inline void BuilderCustom::applyValueCursor(BuilderState& builderState, CSSValue& value)
{
    builderState.style().clearCursorList();
    if (is<CSSPrimitiveValue>(value)) {
        auto cursor = fromCSSValue<CursorType>(value);
        if (builderState.style().cursor() != cursor)
            builderState.style().setCursor(cursor);
        return;
    }

    builderState.style().setCursor(CursorType::Auto);
    auto& list = downcast<CSSValueList>(value);
    for (auto& item : list) {
        if (is<CSSCursorImageValue>(item)) {
            auto& image = downcast<CSSCursorImageValue>(item.get());
            builderState.style().addCursor(builderState.createStyleImage(image), image.hotSpot());
            continue;
        }

        builderState.style().setCursor(fromCSSValue<CursorType>(item.get()));
        ASSERT_WITH_MESSAGE(item.ptr() == list.item(list.length() - 1), "Cursor ID fallback should always be last in the list");
        return;
    }
}

inline std::pair<StyleColor, SVGPaintType> colorAndSVGPaintType(BuilderState& builderState, const CSSPrimitiveValue& localValue, String& url)
{
    StyleColor color;
    auto paintType = SVGPaintType::RGBColor;
    if (localValue.isURI()) {
        paintType = SVGPaintType::URI;
        url = localValue.stringValue();
    } else if (localValue.isValueID() && localValue.valueID() == CSSValueNone)
        paintType = url.isEmpty() ? SVGPaintType::None : SVGPaintType::URINone;
    else if (StyleColor::isCurrentColor(localValue)) {
        color = StyleColor::currentColor();
        paintType = url.isEmpty() ? SVGPaintType::CurrentColor : SVGPaintType::URICurrentColor;
        builderState.style().setDisallowsFastPathInheritance();
    } else {
        color = builderState.colorFromPrimitiveValue(localValue);
        paintType = url.isEmpty() ? SVGPaintType::RGBColor : SVGPaintType::URIRGBColor;
    }
    return { color, paintType };
}

inline void BuilderCustom::applyInitialFill(BuilderState& builderState)
{
    auto& svgStyle = builderState.style().accessSVGStyle();
    svgStyle.setFillPaint(SVGRenderStyle::initialFillPaintType(), SVGRenderStyle::initialFillPaintColor(), SVGRenderStyle::initialFillPaintUri(), builderState.applyPropertyToRegularStyle(), builderState.applyPropertyToVisitedLinkStyle());
}

inline void BuilderCustom::applyInheritFill(BuilderState& builderState)
{
    auto& svgStyle = builderState.style().accessSVGStyle();
    auto& svgParentStyle = builderState.parentStyle().svgStyle();
    svgStyle.setFillPaint(svgParentStyle.fillPaintType(), svgParentStyle.fillPaintColor(), svgParentStyle.fillPaintUri(), builderState.applyPropertyToRegularStyle(), builderState.applyPropertyToVisitedLinkStyle());
}

inline void BuilderCustom::applyValueFill(BuilderState& builderState, CSSValue& value)
{
    auto& svgStyle = builderState.style().accessSVGStyle();
    const auto* localValue = value.isPrimitiveValue() ? &downcast<CSSPrimitiveValue>(value) : nullptr;
    String url;
    if (value.isValueList()) {
        const CSSValueList& list = downcast<CSSValueList>(value);
        url = downcast<CSSPrimitiveValue>(list.item(0))->stringValue();
        localValue = downcast<CSSPrimitiveValue>(list.item(1));
    }

    if (!localValue)
        return;

    auto [color, paintType] = colorAndSVGPaintType(builderState, *localValue, url);
    svgStyle.setFillPaint(paintType, color, url, builderState.applyPropertyToRegularStyle(), builderState.applyPropertyToVisitedLinkStyle());
}

inline void BuilderCustom::applyInitialStroke(BuilderState& builderState)
{
    SVGRenderStyle& svgStyle = builderState.style().accessSVGStyle();
    svgStyle.setStrokePaint(SVGRenderStyle::initialStrokePaintType(), SVGRenderStyle::initialStrokePaintColor(), SVGRenderStyle::initialStrokePaintUri(), builderState.applyPropertyToRegularStyle(), builderState.applyPropertyToVisitedLinkStyle());
}

inline void BuilderCustom::applyInheritStroke(BuilderState& builderState)
{
    auto& svgStyle = builderState.style().accessSVGStyle();
    auto& svgParentStyle = builderState.parentStyle().svgStyle();
    svgStyle.setStrokePaint(svgParentStyle.strokePaintType(), svgParentStyle.strokePaintColor(), svgParentStyle.strokePaintUri(), builderState.applyPropertyToRegularStyle(), builderState.applyPropertyToVisitedLinkStyle());
}

inline void BuilderCustom::applyValueStroke(BuilderState& builderState, CSSValue& value)
{
    auto& svgStyle = builderState.style().accessSVGStyle();
    const auto* localValue = value.isPrimitiveValue() ? &downcast<CSSPrimitiveValue>(value) : nullptr;
    String url;
    if (value.isValueList()) {
        const CSSValueList& list = downcast<CSSValueList>(value);
        url = downcast<CSSPrimitiveValue>(list.item(0))->stringValue();
        localValue = downcast<CSSPrimitiveValue>(list.item(1));
    }

    if (!localValue)
        return;

    auto [color, paintType] = colorAndSVGPaintType(builderState, *localValue, url);
    svgStyle.setStrokePaint(paintType, color, url, builderState.applyPropertyToRegularStyle(), builderState.applyPropertyToVisitedLinkStyle());
}

inline void BuilderCustom::applyInitialContent(BuilderState& builderState)
{
    builderState.style().clearContent();
    builderState.style().setHasContentNone(false);
}

inline void BuilderCustom::applyInheritContent(BuilderState&)
{
}

inline void BuilderCustom::applyValueContent(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value)) {
        const auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
        ASSERT_UNUSED(primitiveValue, primitiveValue.valueID() == CSSValueNormal || primitiveValue.valueID() == CSSValueNone);
        builderState.style().clearContent();
        builderState.style().setHasContentNone(primitiveValue.valueID() == CSSValueNone);
        return;
    }

    bool didSet = false;
    auto processSingleValue = [&] (const CSSValue& item) {
        if (item.isImage()) {
            builderState.style().setContent(builderState.createStyleImage(item), didSet);
            didSet = true;
            return;
        }

        auto* primitive = dynamicDowncast<CSSPrimitiveValue>(item);
        if (primitive && primitive->isString()) {
            builderState.style().setContent(primitive->stringValue().impl(), didSet);
            didSet = true;
        } else if (primitive && primitive->isAttr()) {
            // FIXME: Can a namespace be specified for an attr(foo)?
            if (builderState.style().styleType() == PseudoId::None)
                builderState.style().setHasAttrContent();
            else
                const_cast<RenderStyle&>(builderState.parentStyle()).setHasAttrContent();
            QualifiedName attr(nullAtom(), primitive->stringValue().impl(), nullAtom());
            const AtomString& value = builderState.element() ? builderState.element()->getAttribute(attr) : nullAtom();
            builderState.style().setContent(value.isNull() ? emptyAtom() : value.impl(), didSet);
            didSet = true;
            // Register the fact that the attribute value affects the style.
            builderState.registerContentAttribute(attr.localName());
        } else if (item.isCounter()) {
            // FIXME: counter-style: we probably want to review this for custom counter-style.
            auto& counter = downcast<CSSCounterValue>(item);
            auto listStyle = fromCSSValueID<ListStyleType>(counter.listStyle());
            builderState.style().setContent(makeUnique<CounterContent>(counter.identifier(), listStyle, counter.separator()), didSet);
            didSet = true;
        } else {
            switch (item.valueID()) {
            case CSSValueOpenQuote:
                builderState.style().setContent(QuoteType::OpenQuote, didSet);
                didSet = true;
                break;
            case CSSValueCloseQuote:
                builderState.style().setContent(QuoteType::CloseQuote, didSet);
                didSet = true;
                break;
            case CSSValueNoOpenQuote:
                builderState.style().setContent(QuoteType::NoOpenQuote, didSet);
                didSet = true;
                break;
            case CSSValueNoCloseQuote:
                builderState.style().setContent(QuoteType::NoCloseQuote, didSet);
                didSet = true;
                break;
            default:
                // normal and none do not have any effect.
                break;
            }
        }
    };
    if (is<CSSValueList>(value)) {
        for (auto& item : downcast<CSSValueList>(value))
            processSingleValue(item);
    } else {
        processSingleValue(value);
    }
    if (!didSet)
        builderState.style().clearContent();
}

inline void BuilderCustom::applyInheritFontVariantLigatures(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setVariantCommonLigatures(builderState.parentFontDescription().variantCommonLigatures());
    fontDescription.setVariantDiscretionaryLigatures(builderState.parentFontDescription().variantDiscretionaryLigatures());
    fontDescription.setVariantHistoricalLigatures(builderState.parentFontDescription().variantHistoricalLigatures());
    fontDescription.setVariantContextualAlternates(builderState.parentFontDescription().variantContextualAlternates());
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInitialFontVariantLigatures(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setVariantCommonLigatures(FontVariantLigatures::Normal);
    fontDescription.setVariantDiscretionaryLigatures(FontVariantLigatures::Normal);
    fontDescription.setVariantHistoricalLigatures(FontVariantLigatures::Normal);
    fontDescription.setVariantContextualAlternates(FontVariantLigatures::Normal);
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyValueFontVariantLigatures(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value) && CSSPropertyParserHelpers::isSystemFontShorthand(downcast<CSSPrimitiveValue>(value).valueID())) {
        applyInitialFontVariantLigatures(builderState);
        return;
    }
    auto fontDescription = builderState.fontDescription();
    auto variantLigatures = extractFontVariantLigatures(value);
    fontDescription.setVariantCommonLigatures(variantLigatures.commonLigatures);
    fontDescription.setVariantDiscretionaryLigatures(variantLigatures.discretionaryLigatures);
    fontDescription.setVariantHistoricalLigatures(variantLigatures.historicalLigatures);
    fontDescription.setVariantContextualAlternates(variantLigatures.contextualAlternates);
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInheritFontVariantNumeric(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setVariantNumericFigure(builderState.parentFontDescription().variantNumericFigure());
    fontDescription.setVariantNumericSpacing(builderState.parentFontDescription().variantNumericSpacing());
    fontDescription.setVariantNumericFraction(builderState.parentFontDescription().variantNumericFraction());
    fontDescription.setVariantNumericOrdinal(builderState.parentFontDescription().variantNumericOrdinal());
    fontDescription.setVariantNumericSlashedZero(builderState.parentFontDescription().variantNumericSlashedZero());
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInitialFontVariantNumeric(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setVariantNumericFigure(FontVariantNumericFigure::Normal);
    fontDescription.setVariantNumericSpacing(FontVariantNumericSpacing::Normal);
    fontDescription.setVariantNumericFraction(FontVariantNumericFraction::Normal);
    fontDescription.setVariantNumericOrdinal(FontVariantNumericOrdinal::Normal);
    fontDescription.setVariantNumericSlashedZero(FontVariantNumericSlashedZero::Normal);
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyValueFontVariantNumeric(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value) && CSSPropertyParserHelpers::isSystemFontShorthand(downcast<CSSPrimitiveValue>(value).valueID())) {
        applyInitialFontVariantNumeric(builderState);
        return;
    }
    auto fontDescription = builderState.fontDescription();
    auto variantNumeric = extractFontVariantNumeric(value);
    fontDescription.setVariantNumericFigure(variantNumeric.figure);
    fontDescription.setVariantNumericSpacing(variantNumeric.spacing);
    fontDescription.setVariantNumericFraction(variantNumeric.fraction);
    fontDescription.setVariantNumericOrdinal(variantNumeric.ordinal);
    fontDescription.setVariantNumericSlashedZero(variantNumeric.slashedZero);
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInheritFontVariantEastAsian(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setVariantEastAsianVariant(builderState.parentFontDescription().variantEastAsianVariant());
    fontDescription.setVariantEastAsianWidth(builderState.parentFontDescription().variantEastAsianWidth());
    fontDescription.setVariantEastAsianRuby(builderState.parentFontDescription().variantEastAsianRuby());
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInitialFontVariantEastAsian(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setVariantEastAsianVariant(FontVariantEastAsianVariant::Normal);
    fontDescription.setVariantEastAsianWidth(FontVariantEastAsianWidth::Normal);
    fontDescription.setVariantEastAsianRuby(FontVariantEastAsianRuby::Normal);
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyValueFontVariantEastAsian(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value) && CSSPropertyParserHelpers::isSystemFontShorthand(downcast<CSSPrimitiveValue>(value).valueID())) {
        applyInitialFontVariantEastAsian(builderState);
        return;
    }
    auto fontDescription = builderState.fontDescription();
    auto variantEastAsian = extractFontVariantEastAsian(value);
    fontDescription.setVariantEastAsianVariant(variantEastAsian.variant);
    fontDescription.setVariantEastAsianWidth(variantEastAsian.width);
    fontDescription.setVariantEastAsianRuby(variantEastAsian.ruby);
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInheritFontVariantAlternates(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setVariantAlternates(builderState.parentFontDescription().variantAlternates());
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInitialFontVariantAlternates(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setVariantAlternates(FontVariantAlternates::Normal());
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyValueFontVariantAlternates(BuilderState& builderState, CSSValue& value)
{
    auto setAlternates = [&builderState](FontVariantAlternates alternates) {
        auto fontDescription = builderState.fontDescription();
        fontDescription.setVariantAlternates(WTFMove(alternates));
        builderState.setFontDescription(WTFMove(fontDescription));
    };

    if (auto* primitiveValue = dynamicDowncast<CSSPrimitiveValue>(value)) {
        if (primitiveValue->valueID() == CSSValueNormal || CSSPropertyParserHelpers::isSystemFontShorthand(primitiveValue->valueID())) {
            setAlternates(FontVariantAlternates::Normal());
            return;
        }
        if (primitiveValue->valueID() == CSSValueHistoricalForms) {
            auto alternates = FontVariantAlternates::Normal();
            alternates.valuesRef().historicalForms = true;
            setAlternates(WTFMove(alternates));
            return;
        }
        return;
    }

    if (auto* alternatesValues = dynamicDowncast<CSSFontVariantAlternatesValue>(value)) {
        setAlternates(alternatesValues->value());
        return;
    }

    ASSERT_NOT_REACHED();
}

inline void BuilderCustom::applyInitialFontSize(BuilderState& builderState)
{
    auto fontDescription = builderState.fontDescription();
    float size = Style::fontSizeForKeyword(CSSValueMedium, fontDescription.useFixedDefaultSize(), builderState.document());

    if (size < 0)
        return;

    fontDescription.setKeywordSizeFromIdentifier(CSSValueMedium);
    builderState.setFontSize(fontDescription, size);
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInheritFontSize(BuilderState& builderState)
{
    const auto& parentFontDescription = builderState.parentStyle().fontDescription();
    float size = parentFontDescription.specifiedSize();

    if (size < 0)
        return;

    auto fontDescription = builderState.fontDescription();
    fontDescription.setKeywordSize(parentFontDescription.keywordSize());
    builderState.setFontSize(fontDescription, size);
    builderState.setFontDescription(WTFMove(fontDescription));
}

// When the CSS keyword "larger" is used, this function will attempt to match within the keyword
// table, and failing that, will simply multiply by 1.2.
inline float BuilderCustom::largerFontSize(float size)
{
    // FIXME: Figure out where we fall in the size ranges (xx-small to xxx-large) and scale up to
    // the next size level.
    return size * 1.2f;
}

// Like the previous function, but for the keyword "smaller".
inline float BuilderCustom::smallerFontSize(float size)
{
    // FIXME: Figure out where we fall in the size ranges (xx-small to xxx-large) and scale down to
    // the next size level.
    return size / 1.2f;
}

inline float BuilderCustom::determineRubyTextSizeMultiplier(BuilderState& builderState)
{
    if (builderState.style().rubyPosition() != RubyPosition::InterCharacter)
        return 0.5f;

    // FIXME: This hack is to ensure tone marks are the same size as
    // the bopomofo. This code will go away if we make a special renderer
    // for the tone marks eventually.
    if (auto* element = builderState.element()) {
        for (auto& ancestor : ancestorsOfType<HTMLElement>(*element)) {
            if (ancestor.hasTagName(HTMLNames::rtTag))
                return 1.0f;
        }
    }
    return 0.25f;
}

static inline void applyFontStyle(BuilderState& state, std::optional<FontSelectionValue> slope, FontStyleAxis axis)
{
    auto& description = state.fontDescription();
    if (description.italic() == slope && description.fontStyleAxis() == axis)
        return;

    auto copy = description;
    copy.setItalic(slope);
    copy.setFontStyleAxis(axis);
    state.setFontDescription(WTFMove(copy));
}

inline void BuilderCustom::applyInitialFontStyle(BuilderState& state)
{
    applyFontStyle(state, FontCascadeDescription::initialItalic(), FontCascadeDescription::initialFontStyleAxis());
}

inline void BuilderCustom::applyInheritFontStyle(BuilderState& state)
{
    applyFontStyle(state, state.parentFontDescription().italic(), state.parentFontDescription().fontStyleAxis());
}

inline void BuilderCustom::applyValueFontStyle(BuilderState& state, CSSValue& value)
{
    auto* primitiveValue = dynamicDowncast<CSSPrimitiveValue>(value);
    auto keyword = primitiveValue ? primitiveValue->valueID() : CSSValueOblique;

    std::optional<FontSelectionValue> slope;
    if (!CSSPropertyParserHelpers::isSystemFontShorthand(keyword))
        slope = BuilderConverter::convertFontStyleFromValue(value);

    applyFontStyle(state, slope, keyword == CSSValueItalic ? FontStyleAxis::ital : FontStyleAxis::slnt);
}

inline void BuilderCustom::applyValueFontSize(BuilderState& builderState, CSSValue& value)
{
    auto fontDescription = builderState.fontDescription();
    fontDescription.setKeywordSizeFromIdentifier(CSSValueInvalid);

    float parentSize = builderState.parentStyle().fontDescription().specifiedSize();
    bool parentIsAbsoluteSize = builderState.parentStyle().fontDescription().isAbsoluteSize();

    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    float size = 0;
    if (CSSValueID ident = primitiveValue.valueID()) {
        fontDescription.setIsAbsoluteSize((parentIsAbsoluteSize && (ident == CSSValueLarger || ident == CSSValueSmaller || ident == CSSValueWebkitRubyText)) || CSSPropertyParserHelpers::isSystemFontShorthand(ident));

        if (CSSPropertyParserHelpers::isSystemFontShorthand(ident))
            size = SystemFontDatabase::singleton().systemFontShorthandSize(CSSPropertyParserHelpers::lowerFontShorthand(ident));

        switch (ident) {
        case CSSValueXxSmall:
        case CSSValueXSmall:
        case CSSValueSmall:
        case CSSValueMedium:
        case CSSValueLarge:
        case CSSValueXLarge:
        case CSSValueXxLarge:
        case CSSValueXxxLarge:
            size = Style::fontSizeForKeyword(ident, fontDescription.useFixedDefaultSize(), builderState.document());
            fontDescription.setKeywordSizeFromIdentifier(ident);
            break;
        case CSSValueLarger:
            size = largerFontSize(parentSize);
            break;
        case CSSValueSmaller:
            size = smallerFontSize(parentSize);
            break;
        case CSSValueWebkitRubyText:
            size = determineRubyTextSizeMultiplier(builderState) * parentSize;
            break;
        default:
            break;
        }
    } else {
        fontDescription.setIsAbsoluteSize(parentIsAbsoluteSize || !primitiveValue.isParentFontRelativeLength());
        if (primitiveValue.isLength()) {
            auto conversionData = builderState.cssToLengthConversionData().copyForFontSize();
            size = primitiveValue.computeLength<float>(conversionData);
        } else if (primitiveValue.isPercentage())
            size = (primitiveValue.floatValue() * parentSize) / 100.0f;
        else if (primitiveValue.isCalculatedPercentageWithLength()) {
            auto conversionData = builderState.cssToLengthConversionData().copyForFontSize();
            size = primitiveValue.cssCalcValue()->createCalculationValue(conversionData)->evaluate(parentSize);
        } else
            return;
    }

    if (size < 0)
        return;

    builderState.setFontSize(fontDescription, std::min(maximumAllowedFontSize, size));
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyValueFontSizeAdjust(BuilderState& builderState, CSSValue& value)
{
    auto fontDescription = builderState.fontDescription();
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (primitiveValue.isNumber())
        fontDescription.setFontSizeAdjust(primitiveValue.floatValue());
    else {
        ASSERT(primitiveValue.valueID() == CSSValueNone || CSSPropertyParserHelpers::isSystemFontShorthand(primitiveValue.valueID()));
        fontDescription.setFontSizeAdjust(std::nullopt);
    }
    builderState.setFontDescription(WTFMove(fontDescription));
}

inline void BuilderCustom::applyInitialGridTemplateAreas(BuilderState& builderState)
{
    builderState.style().setImplicitNamedGridColumnLines(RenderStyle::initialNamedGridColumnLines());
    builderState.style().setImplicitNamedGridRowLines(RenderStyle::initialNamedGridRowLines());

    builderState.style().setNamedGridArea(RenderStyle::initialNamedGridArea());
    builderState.style().setNamedGridAreaRowCount(RenderStyle::initialNamedGridAreaCount());
    builderState.style().setNamedGridAreaColumnCount(RenderStyle::initialNamedGridAreaCount());
}

inline void BuilderCustom::applyInheritGridTemplateAreas(BuilderState& builderState)
{
    builderState.style().setImplicitNamedGridColumnLines(builderState.parentStyle().implicitNamedGridColumnLines());
    builderState.style().setImplicitNamedGridRowLines(builderState.parentStyle().implicitNamedGridRowLines());

    builderState.style().setNamedGridArea(builderState.parentStyle().namedGridArea());
    builderState.style().setNamedGridAreaRowCount(builderState.parentStyle().namedGridAreaRowCount());
    builderState.style().setNamedGridAreaColumnCount(builderState.parentStyle().namedGridAreaColumnCount());
}

inline void BuilderCustom::applyValueGridTemplateAreas(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value)) {
        ASSERT(downcast<CSSPrimitiveValue>(value).valueID() == CSSValueNone);
        applyInitialGridTemplateAreas(builderState);
        return;
    }

    auto& gridTemplateAreasValue = downcast<CSSGridTemplateAreasValue>(value);
    const NamedGridAreaMap& newNamedGridAreas = gridTemplateAreasValue.gridAreaMap();

    NamedGridLinesMap implicitNamedGridColumnLines;
    NamedGridLinesMap implicitNamedGridRowLines;
    BuilderConverter::createImplicitNamedGridLinesFromGridArea(newNamedGridAreas, implicitNamedGridColumnLines, ForColumns);
    BuilderConverter::createImplicitNamedGridLinesFromGridArea(newNamedGridAreas, implicitNamedGridRowLines, ForRows);
    builderState.style().setImplicitNamedGridColumnLines(implicitNamedGridColumnLines);
    builderState.style().setImplicitNamedGridRowLines(implicitNamedGridRowLines);

    builderState.style().setNamedGridArea(gridTemplateAreasValue.gridAreaMap());
    builderState.style().setNamedGridAreaRowCount(gridTemplateAreasValue.rowCount());
    builderState.style().setNamedGridAreaColumnCount(gridTemplateAreasValue.columnCount());
}

#define SET_TRACKS_DATA_INTERNAL(trackList, style, parentStyle, TrackType) \
    ASSERT(trackList || parentStyle); \
    style.setGrid##TrackType##List(trackList ? *trackList : parentStyle->grid##TrackType##List()); \

#define SET_INHERIT_TRACKS_DATA(style, parentStyle, TrackType) \
    GridTrackList* trackList = nullptr; \
    const RenderStyle* parentStylePointer = &parentStyle; \
    SET_TRACKS_DATA_INTERNAL(trackList, style, parentStylePointer, TrackType)

#define SET_TRACKS_DATA(trackList, style, TrackType) \
    GridTrackList* trackListPointer = &trackList; \
    const RenderStyle* parentStyle = nullptr; \
    SET_TRACKS_DATA_INTERNAL(trackListPointer, style, parentStyle, TrackType)

inline void BuilderCustom::applyInitialGridTemplateColumns(BuilderState& builderState)
{
    GridTrackList initialTrackList;
    SET_TRACKS_DATA(initialTrackList, builderState.style(), Column);
}

inline void BuilderCustom::applyInheritGridTemplateColumns(BuilderState& builderState)
{
    SET_INHERIT_TRACKS_DATA(builderState.style(), builderState.parentStyle(), Column);
}

inline void BuilderCustom::applyValueGridTemplateColumns(BuilderState& builderState, CSSValue& value)
{
    GridTrackList trackList;
    if (!BuilderConverter::createGridTrackList(value, trackList, builderState))
        return;
    SET_TRACKS_DATA(trackList, builderState.style(), Column);
}

inline void BuilderCustom::applyInitialGridTemplateRows(BuilderState& builderState)
{
    GridTrackList initialTrackList;
    SET_TRACKS_DATA(initialTrackList, builderState.style(), Row);
}

inline void BuilderCustom::applyInheritGridTemplateRows(BuilderState& builderState)
{
    SET_INHERIT_TRACKS_DATA(builderState.style(), builderState.parentStyle(), Row);
}

inline void BuilderCustom::applyValueGridTemplateRows(BuilderState& builderState, CSSValue& value)
{
    GridTrackList trackList;
    if (!BuilderConverter::createGridTrackList(value, trackList, builderState))
        return;

    SET_TRACKS_DATA(trackList, builderState.style(), Row);
}

void BuilderCustom::applyValueAlt(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (primitiveValue.isString())
        builderState.style().setContentAltText(primitiveValue.stringValue());
    else if (primitiveValue.isAttr()) {
        // FIXME: Can a namespace be specified for an attr(foo)?
        if (builderState.style().styleType() == PseudoId::None)
            builderState.style().setUnique();
        else
            const_cast<RenderStyle&>(builderState.parentStyle()).setUnique();

        QualifiedName attr(nullAtom(), AtomString { primitiveValue.stringValue() }, nullAtom());
        const AtomString& value = builderState.element() ? builderState.element()->getAttribute(attr) : nullAtom();
        builderState.style().setContentAltText(value.isNull() ? emptyAtom() : value);

        // Register the fact that the attribute value affects the style.
        builderState.registerContentAttribute(attr.localName());
    } else
        builderState.style().setContentAltText(emptyAtom());
}

inline void BuilderCustom::applyValueWillChange(BuilderState& builderState, CSSValue& value)
{
    if (is<CSSPrimitiveValue>(value)) {
        ASSERT(downcast<CSSPrimitiveValue>(value).valueID() == CSSValueAuto);
        builderState.style().setWillChange(nullptr);
        return;
    }

    auto willChange = WillChangeData::create();
    for (auto& item : downcast<CSSValueList>(value)) {
        if (!is<CSSPrimitiveValue>(item))
            continue;
        auto& primitiveValue = downcast<CSSPrimitiveValue>(item.get());
        switch (primitiveValue.valueID()) {
        case CSSValueScrollPosition:
            willChange->addFeature(WillChangeData::Feature::ScrollPosition);
            break;
        case CSSValueContents:
            willChange->addFeature(WillChangeData::Feature::Contents);
            break;
        default:
            if (primitiveValue.isPropertyID()) {
                if (!isExposed(primitiveValue.propertyID(), &builderState.document().settings()))
                    break;
                willChange->addFeature(WillChangeData::Feature::Property, primitiveValue.propertyID());
            }
            break;
        }
    }
    builderState.style().setWillChange(WTFMove(willChange));
}

inline void BuilderCustom::applyValueStrokeWidth(BuilderState& builderState, CSSValue& value)
{
    builderState.style().setStrokeWidth(BuilderConverter::convertLengthAllowingNumber(builderState, value));
    builderState.style().setHasExplicitlySetStrokeWidth(true);
}

inline void BuilderCustom::applyValueStrokeColor(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
    if (builderState.applyPropertyToRegularStyle())
        builderState.style().setStrokeColor(builderState.colorFromPrimitiveValue(primitiveValue, ForVisitedLink::No));
    if (builderState.applyPropertyToVisitedLinkStyle())
        builderState.style().setVisitedLinkStrokeColor(builderState.colorFromPrimitiveValue(primitiveValue, ForVisitedLink::Yes));
    builderState.style().setHasExplicitlySetStrokeColor(true);
}

inline void BuilderCustom::applyValueColor(BuilderState& builderState, CSSValue& value)
{
    auto& primitiveValue = downcast<CSSPrimitiveValue>(value);

    // For the color property, current color is actually the inherited computed color.
    auto resolveColor = [&](const StyleColor& color) {
        return color.resolveColor(builderState.parentStyle().color());
    };

    if (builderState.applyPropertyToRegularStyle()) {
        auto color = builderState.colorFromPrimitiveValue(primitiveValue, ForVisitedLink::No);
        builderState.style().setColor(resolveColor(color));
    }
    if (builderState.applyPropertyToVisitedLinkStyle()) {
        auto color = builderState.colorFromPrimitiveValue(primitiveValue, ForVisitedLink::Yes);
        builderState.style().setVisitedLinkColor(resolveColor(color));
    }
    builderState.style().setDisallowsFastPathInheritance();
}

inline void BuilderCustom::applyInitialCustomProperty(BuilderState& builderState, const CSSRegisteredCustomProperty* registered, const AtomString& name)
{
    if (registered && registered->initialValue) {
        applyValueCustomProperty(builderState, registered, *registered->initialValue);
        return;
    }

    auto invalid = CSSCustomPropertyValue::createUnresolved(name, CSSValueInvalid);
    applyValueCustomProperty(builderState, registered, invalid.get());
}

inline void BuilderCustom::applyInheritCustomProperty(BuilderState& builderState, const CSSRegisteredCustomProperty* registered, const AtomString& name)
{
    auto* parentValue = builderState.parentStyle().inheritedCustomProperties().get(name);
    if (parentValue && !(registered && !registered->inherits))
        applyValueCustomProperty(builderState, registered, const_cast<CSSCustomPropertyValue&>(*parentValue));
    else if (auto* nonInheritedParentValue = builderState.parentStyle().nonInheritedCustomProperties().get(name))
        applyValueCustomProperty(builderState, registered, const_cast<CSSCustomPropertyValue&>(*nonInheritedParentValue));
    else
        applyInitialCustomProperty(builderState, registered, name);
}

inline void BuilderCustom::applyValueCustomProperty(BuilderState& builderState, const CSSRegisteredCustomProperty* registered, const CSSCustomPropertyValue& value)
{
    ASSERT(value.isResolved());

    bool isInherited = !registered || registered->inherits;
    builderState.style().setCustomPropertyValue(value, isInherited);
}

inline void BuilderCustom::applyInitialContainIntrinsicWidth(BuilderState& builderState)
{
    builderState.style().setContainIntrinsicWidthType(RenderStyle::initialContainIntrinsicWidthType());
    builderState.style().setContainIntrinsicWidth(RenderStyle::initialContainIntrinsicWidth());
}

inline void BuilderCustom::applyInheritContainIntrinsicWidth(BuilderState&)
{
}

inline void BuilderCustom::applyValueContainIntrinsicWidth(BuilderState& builderState, CSSValue& value)
{
    auto& style = builderState.style();
    if (is<CSSPrimitiveValue>(value)) {
        auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
        if (primitiveValue.valueID() == CSSValueNone) {
            style.setContainIntrinsicWidth(RenderStyle::initialContainIntrinsicWidth());
            return style.setContainIntrinsicWidthType(ContainIntrinsicSizeType::None);
        }

        if (primitiveValue.isLength()) {
            style.setContainIntrinsicWidthType(ContainIntrinsicSizeType::Length);
            auto width = primitiveValue.computeLength<Length>(builderState.cssToLengthConversionData().copyWithAdjustedZoom(1.0f));
            style.setContainIntrinsicWidth(width);
        }
        return;
    }

    if (!is<CSSValueList>(value))
        return;

    auto& list = downcast<CSSValueList>(value);
    ASSERT(list.length() == 2);
    ASSERT(downcast<CSSPrimitiveValue>(list.item(0))->valueID() == CSSValueAuto);
    ASSERT(downcast<CSSPrimitiveValue>(list.item(1))->isLength());
    style.setContainIntrinsicWidthType(ContainIntrinsicSizeType::AutoAndLength);
    auto lengthValue = downcast<CSSPrimitiveValue>(list.item(1))->computeLength<Length>(builderState.cssToLengthConversionData().copyWithAdjustedZoom(1.0f));
    style.setContainIntrinsicWidth(lengthValue);
}

inline void BuilderCustom::applyInitialContainIntrinsicHeight(BuilderState& builderState)
{
    builderState.style().setContainIntrinsicHeightType(RenderStyle::initialContainIntrinsicHeightType());
    builderState.style().setContainIntrinsicHeight(RenderStyle::initialContainIntrinsicHeight());
}

inline void BuilderCustom::applyInheritContainIntrinsicHeight(BuilderState&)
{
}

inline void BuilderCustom::applyValueContainIntrinsicHeight(BuilderState& builderState, CSSValue& value)
{
    auto& style = builderState.style();
    if (is<CSSPrimitiveValue>(value)) {
        auto& primitiveValue = downcast<CSSPrimitiveValue>(value);
        if (primitiveValue.valueID() == CSSValueNone) {
            style.setContainIntrinsicHeight(RenderStyle::initialContainIntrinsicHeight());
            return style.setContainIntrinsicHeightType(ContainIntrinsicSizeType::None);
        }

        if (primitiveValue.isLength()) {
            style.setContainIntrinsicHeightType(ContainIntrinsicSizeType::Length);
            auto height = primitiveValue.computeLength<Length>(builderState.cssToLengthConversionData().copyWithAdjustedZoom(1.0f));
            style.setContainIntrinsicHeight(height);
        }
        return;
    }

    if (!is<CSSValueList>(value))
        return;

    auto& list = downcast<CSSValueList>(value);
    ASSERT(list.length() == 2);
    ASSERT(downcast<CSSPrimitiveValue>(list.item(0))->valueID() == CSSValueAuto);
    ASSERT(downcast<CSSPrimitiveValue>(list.item(1))->isLength());
    style.setContainIntrinsicHeightType(ContainIntrinsicSizeType::AutoAndLength);
    auto lengthValue = downcast<CSSPrimitiveValue>(list.item(1))->computeLength<Length>(builderState.cssToLengthConversionData().copyWithAdjustedZoom(1.0f));
    style.setContainIntrinsicHeight(lengthValue);
}

}
}
