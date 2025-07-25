/*
 * Copyright (C) 2019 Apple Inc. All rights reserved.
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

#include "config.h"
#include "PropertyCascade.h"

#include "CSSCustomPropertyValue.h"
#include "CSSPaintImageValue.h"
#include "CSSPrimitiveValueMappings.h"
#include "CSSValuePool.h"
#include "PaintWorkletGlobalScope.h"
#include "PropertyAllowlist.h"
#include "StyleBuilderGenerated.h"
#include "StylePropertyShorthand.h"

namespace WebCore {
namespace Style {

PropertyCascade::PropertyCascade(const MatchResult& matchResult, CascadeLevel maximumCascadeLevel, IncludedProperties includedProperties, const HashSet<AnimatableProperty>* animatedProperties)
    : m_matchResult(matchResult)
    , m_includedProperties(includedProperties)
    , m_maximumCascadeLevel(maximumCascadeLevel)
    , m_animationLayer(animatedProperties ? std::optional { AnimationLayer { *animatedProperties } } : std::nullopt)
{
    buildCascade();
}

PropertyCascade::PropertyCascade(const PropertyCascade& parent, CascadeLevel maximumCascadeLevel, std::optional<ScopeOrdinal> rollbackScope, std::optional<CascadeLayerPriority> maximumCascadeLayerPriorityForRollback)
    : m_matchResult(parent.m_matchResult)
    , m_includedProperties(parent.m_includedProperties)
    , m_maximumCascadeLevel(maximumCascadeLevel)
    , m_rollbackScope(rollbackScope)
    , m_maximumCascadeLayerPriorityForRollback(maximumCascadeLayerPriorityForRollback)
    , m_animationLayer(parent.m_animationLayer)
{
    buildCascade();
}

PropertyCascade::~PropertyCascade() = default;

PropertyCascade::AnimationLayer::AnimationLayer(const HashSet<AnimatableProperty>& properties)
    : properties(properties)
{
    hasCustomProperties = std::find_if(properties.begin(), properties.end(), [](auto& property) {
        return std::holds_alternative<AtomString>(property);
    }) != properties.end();

    hasFontSize = properties.contains(CSSPropertyFontSize);
    hasLineHeight = properties.contains(CSSPropertyLineHeight);
}

void PropertyCascade::buildCascade()
{
    OptionSet<CascadeLevel> cascadeLevelsWithImportant;

    for (auto cascadeLevel : { CascadeLevel::UserAgent, CascadeLevel::User, CascadeLevel::Author }) {
        if (cascadeLevel > m_maximumCascadeLevel)
            break;
        bool hasImportant = addNormalMatches(cascadeLevel);
        if (hasImportant)
            cascadeLevelsWithImportant.add(cascadeLevel);
    }

    for (auto cascadeLevel : { CascadeLevel::Author, CascadeLevel::User, CascadeLevel::UserAgent }) {
        if (!cascadeLevelsWithImportant.contains(cascadeLevel))
            continue;
        addImportantMatches(cascadeLevel);
    }

    sortDeferredPropertyIDs();
}

void PropertyCascade::setPropertyInternal(Property& property, CSSPropertyID id, CSSValue& cssValue, const MatchedProperties& matchedProperties, CascadeLevel cascadeLevel)
{
    ASSERT(matchedProperties.linkMatchType <= SelectorChecker::MatchAll);
    property.id = id;
    property.cascadeLevel = cascadeLevel;
    property.styleScopeOrdinal = matchedProperties.styleScopeOrdinal;
    property.cascadeLayerPriority = matchedProperties.cascadeLayerPriority;
    property.fromStyleAttribute = matchedProperties.fromStyleAttribute;

    if (matchedProperties.linkMatchType == SelectorChecker::MatchAll) {
        property.cssValue[0] = &cssValue;
        property.cssValue[SelectorChecker::MatchLink] = &cssValue;
        property.cssValue[SelectorChecker::MatchVisited] = &cssValue;
    } else
        property.cssValue[matchedProperties.linkMatchType] = &cssValue;
}

void PropertyCascade::set(CSSPropertyID id, CSSValue& cssValue, const MatchedProperties& matchedProperties, CascadeLevel cascadeLevel)
{
    ASSERT(!CSSProperty::isInLogicalPropertyGroup(id));
    ASSERT(id < firstDeferredProperty);

    auto& property = m_properties[id];
    ASSERT(id < m_propertyIsPresent.size());
    if (id == CSSPropertyCustom) {
        m_propertyIsPresent.set(id);
        const auto& customValue = downcast<CSSCustomPropertyValue>(cssValue);
        bool hasValue = m_customProperties.contains(customValue.name());
        if (!hasValue) {
            Property property;
            property.id = id;
            property.cssValue = { };
            setPropertyInternal(property, id, cssValue, matchedProperties, cascadeLevel);
            m_customProperties.set(customValue.name(), property);
        } else {
            Property property = customProperty(customValue.name());
            setPropertyInternal(property, id, cssValue, matchedProperties, cascadeLevel);
            m_customProperties.set(customValue.name(), property);
        }
        return;
    }

    if (!m_propertyIsPresent[id])
        property.cssValue = { };
    m_propertyIsPresent.set(id);
    setPropertyInternal(property, id, cssValue, matchedProperties, cascadeLevel);
}

void PropertyCascade::setDeferred(CSSPropertyID id, CSSValue& cssValue, const MatchedProperties& matchedProperties, CascadeLevel cascadeLevel)
{
    ASSERT(id >= firstDeferredProperty);
    ASSERT(id <= lastDeferredProperty);

    auto& property = m_properties[id];
    if (!hasDeferredProperty(id)) {
        property.cssValue = { };
        m_lowestSeenDeferredProperty = std::min(m_lowestSeenDeferredProperty, id);
        m_highestSeenDeferredProperty = std::max(m_highestSeenDeferredProperty, id);
    }
    setDeferredPropertyIndex(id, ++m_lastIndexForDeferred);
    setPropertyInternal(property, id, cssValue, matchedProperties, cascadeLevel);
}

const PropertyCascade::Property* PropertyCascade::lastDeferredPropertyResolvingRelated(CSSPropertyID propertyID, TextDirection direction, WritingMode writingMode) const
{
    auto relatedID = [&] {
        if (!CSSProperty::isInLogicalPropertyGroup(propertyID))
            return relatedProperty(propertyID);
        if (CSSProperty::isDirectionAwareProperty(propertyID))
            return CSSProperty::resolveDirectionAwareProperty(propertyID, direction, writingMode);
        return CSSProperty::unresolvePhysicalProperty(propertyID, direction, writingMode);
    }();
    if (relatedID == CSSPropertyInvalid) {
        ASSERT_NOT_REACHED();
        return hasDeferredProperty(propertyID) ? &deferredProperty(propertyID) : nullptr;
    }
    auto indexForPropertyID = deferredPropertyIndex(propertyID);
    auto indexForRelatedID = deferredPropertyIndex(relatedID);
    if (indexForPropertyID > indexForRelatedID)
        return &deferredProperty(propertyID);
    if (indexForPropertyID < indexForRelatedID)
        return &deferredProperty(relatedID);
    ASSERT(!hasDeferredProperty(propertyID));
    ASSERT(!hasDeferredProperty(relatedID));
    return nullptr;
}

bool PropertyCascade::addMatch(const MatchedProperties& matchedProperties, CascadeLevel cascadeLevel, bool important)
{
    auto includePropertiesForRollback = [&] {
        if (m_rollbackScope && matchedProperties.styleScopeOrdinal > *m_rollbackScope)
            return true;
        if (cascadeLevel < m_maximumCascadeLevel)
            return true;
        if (matchedProperties.fromStyleAttribute == FromStyleAttribute::Yes)
            return false;
        return matchedProperties.cascadeLayerPriority <= *m_maximumCascadeLayerPriorityForRollback;
    };
    if (m_maximumCascadeLayerPriorityForRollback && !includePropertiesForRollback())
        return false;

    auto propertyAllowlist = matchedProperties.allowlistType;
    bool hasImportantProperties = false;

    for (auto current : *matchedProperties.properties) {
        if (current.isImportant())
            hasImportantProperties = true;
        if (important != current.isImportant())
            continue;

        if (m_includedProperties == IncludedProperties::InheritedOnly) {
            if (!current.isInherited()) {
                // Inherited only mode is used after matched properties cache hit.
                // A match with a value that is explicitly inherited should never have been cached.
                ASSERT(!isValueID(current.value(), CSSValueInherit));
                continue;
            }
        } else if (m_includedProperties == IncludedProperties::AfterAnimation || m_includedProperties == IncludedProperties::AfterTransition) {
            // We only want to re-apply properties that may depend on animated values, or are overriden by !import.
            if (!shouldApplyAfterAnimation(current))
                continue;
        }

        auto propertyID = current.id();

#if ENABLE(VIDEO)
        if (propertyAllowlist == PropertyAllowlist::Cue && !isValidCueStyleProperty(propertyID))
            continue;
#endif
        if (propertyAllowlist == PropertyAllowlist::Marker && !isValidMarkerStyleProperty(propertyID))
            continue;

        if (propertyID < firstDeferredProperty)
            set(propertyID, *current.value(), matchedProperties, cascadeLevel);
        else
            setDeferred(propertyID, *current.value(), matchedProperties, cascadeLevel);
    }

    return hasImportantProperties;
}

bool PropertyCascade::shouldApplyAfterAnimation(const StyleProperties::PropertyReference& property)
{
    ASSERT(m_animationLayer);

    auto id = property.id();
    auto* customProperty = dynamicDowncast<CSSCustomPropertyValue>(*property.value());

    auto hasPropertyAlready = [&] {
        if (customProperty)
            return hasCustomProperty(customProperty->name());
        return id < firstDeferredProperty ? hasNormalProperty(id) : hasDeferredProperty(id);
    }();

    if (hasPropertyAlready)
        return true;

    auto isAnimatedProperty = [&] {
        if (customProperty)
            return m_animationLayer->properties.contains(customProperty->name());
        return m_animationLayer->properties.contains(id);
    }();

    if (isAnimatedProperty) {
        // "Important declarations from all origins take precedence over animations."
        // https://drafts.csswg.org/css-cascade-5/#importance
        return m_includedProperties == IncludedProperties::AfterAnimation && property.isImportant();
    }

    // If we are animating custom properties they may affect other properties so we need to re-resolve them.
    if (m_animationLayer->hasCustomProperties) {
        // We could check if the we are actually animating the referenced variable. Indirect cases would need to be taken into account.
        if (customProperty && !customProperty->isResolved())
            return true;
        if (property.value()->isVariableReferenceValue())
            return true;
    }

    // Check for 'em' units and similar property dependencies.
    if (m_animationLayer->hasFontSize || m_animationLayer->hasLineHeight) {
        auto dependencies = property.value()->computedStyleDependencies();
        if (m_animationLayer->hasFontSize && dependencies.properties.contains(CSSPropertyFontSize))
            return true;
        if (m_animationLayer->hasLineHeight && dependencies.properties.contains(CSSPropertyLineHeight))
            return true;
    }

    return false;
}

static auto& declarationsForCascadeLevel(const MatchResult& matchResult, CascadeLevel cascadeLevel)
{
    switch (cascadeLevel) {
    case CascadeLevel::UserAgent: return matchResult.userAgentDeclarations;
    case CascadeLevel::User: return matchResult.userDeclarations;
    case CascadeLevel::Author: return matchResult.authorDeclarations;
    }
    ASSERT_NOT_REACHED();
    return matchResult.authorDeclarations;
}

bool PropertyCascade::addNormalMatches(CascadeLevel cascadeLevel)
{
    bool hasImportant = false;
    for (auto& matchedDeclarations : declarationsForCascadeLevel(m_matchResult, cascadeLevel))
        hasImportant |= addMatch(matchedDeclarations, cascadeLevel, false);

    return hasImportant;
}

static bool hasImportantProperties(const StyleProperties& properties)
{
    for (auto property : properties) {
        if (property.isImportant())
            return true;
    }
    return false;
}

void PropertyCascade::addImportantMatches(CascadeLevel cascadeLevel)
{
    struct ImportantMatch {
        unsigned index;
        ScopeOrdinal ordinal;
        CascadeLayerPriority layerPriority;
        FromStyleAttribute fromStyleAttribute;
    };
    Vector<ImportantMatch> importantMatches;
    bool hasMatchesFromOtherScopesOrLayers = false;

    auto& matchedDeclarations = declarationsForCascadeLevel(m_matchResult, cascadeLevel);

    for (unsigned i = 0; i < matchedDeclarations.size(); ++i) {
        const MatchedProperties& matchedProperties = matchedDeclarations[i];

        if (!hasImportantProperties(*matchedProperties.properties))
            continue;

        importantMatches.append({ i, matchedProperties.styleScopeOrdinal, matchedProperties.cascadeLayerPriority, matchedProperties.fromStyleAttribute });

        if (matchedProperties.styleScopeOrdinal != ScopeOrdinal::Element || matchedProperties.cascadeLayerPriority != RuleSet::cascadeLayerPriorityForUnlayered)
            hasMatchesFromOtherScopesOrLayers = true;
    }

    if (importantMatches.isEmpty())
        return;

    if (hasMatchesFromOtherScopesOrLayers) {
        // Match results are sorted in reverse tree context order so this is not needed for normal properties.
        std::stable_sort(importantMatches.begin(), importantMatches.end(), [] (auto& a, auto& b) {
            // For !important properties a later shadow tree wins.
            if (a.ordinal != b.ordinal)
                return a.ordinal < b.ordinal;
            // Lower priority layer wins, except if style attribute is involved.
            if (a.fromStyleAttribute != b.fromStyleAttribute)
                return a.fromStyleAttribute == FromStyleAttribute::No;
            return a.layerPriority > b.layerPriority;
        });
    }

    for (auto& match : importantMatches)
        addMatch(matchedDeclarations[match.index], cascadeLevel, true);
}

void PropertyCascade::sortDeferredPropertyIDs()
{
    auto begin = m_deferredPropertyIDs.begin();
    auto end = begin;
    for (uint16_t id = m_lowestSeenDeferredProperty; id <= m_highestSeenDeferredProperty; ++id) {
        auto propertyID = static_cast<CSSPropertyID>(id);
        if (hasDeferredProperty(propertyID))
            *end++ = propertyID;
    }
    m_seenDeferredPropertyCount = end - begin;
    std::sort(begin, end, [&](auto id1, auto id2) {
        return deferredPropertyIndex(id1) < deferredPropertyIndex(id2);
    });
}

}
}
