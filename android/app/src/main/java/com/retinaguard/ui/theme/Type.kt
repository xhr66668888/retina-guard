package com.retinaguard.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp

// Mobile typography. Inter is the open substitute for Vodafone face.
// We keep the system default sans-serif so the build works without bundling Inter;
// if the user later drops Inter into res/font, swap fontFamily here.
private val displayTracking = (-0.02).em

val AppTypography = Typography(
    // Brand display moments — onboarding hero, brand mark
    displayLarge = TextStyle(
        fontWeight = FontWeight.W800,
        fontSize = 56.sp,
        lineHeight = 56.sp,
        letterSpacing = displayTracking,
    ),
    displayMedium = TextStyle(
        fontWeight = FontWeight.W800,
        fontSize = 40.sp,
        lineHeight = 40.sp,
        letterSpacing = displayTracking,
    ),
    // Timer hero
    displaySmall = TextStyle(
        fontWeight = FontWeight.W800,
        fontSize = 80.sp,
        lineHeight = 80.sp,
        letterSpacing = (-0.01).em,
    ),
    headlineLarge = TextStyle(
        fontWeight = FontWeight.W700,
        fontSize = 32.sp,
        lineHeight = 36.sp,
    ),
    headlineMedium = TextStyle(
        fontWeight = FontWeight.W700,
        fontSize = 24.sp,
        lineHeight = 28.sp,
    ),
    headlineSmall = TextStyle(
        fontWeight = FontWeight.W700,
        fontSize = 20.sp,
        lineHeight = 26.sp,
    ),
    titleLarge = TextStyle(
        fontWeight = FontWeight.W700,
        fontSize = 18.sp,
        lineHeight = 24.sp,
    ),
    titleMedium = TextStyle(
        fontWeight = FontWeight.W600,
        fontSize = 16.sp,
        lineHeight = 22.sp,
    ),
    bodyLarge = TextStyle(
        fontWeight = FontWeight.W400,
        fontSize = 16.sp,
        lineHeight = 22.sp,
    ),
    bodyMedium = TextStyle(
        fontWeight = FontWeight.W400,
        fontSize = 14.sp,
        lineHeight = 20.sp,
    ),
    bodySmall = TextStyle(
        fontWeight = FontWeight.W400,
        fontSize = 12.sp,
        lineHeight = 16.sp,
    ),
    labelLarge = TextStyle(
        fontWeight = FontWeight.W700,
        fontSize = 14.sp,
        lineHeight = 14.sp,
        letterSpacing = 0.01.em,
    ),
    labelMedium = TextStyle(
        fontWeight = FontWeight.W600,
        fontSize = 12.sp,
        lineHeight = 14.sp,
        letterSpacing = 0.04.em,
    ),
    labelSmall = TextStyle(
        fontWeight = FontWeight.W600,
        fontSize = 11.sp,
        lineHeight = 14.sp,
        letterSpacing = 0.06.em,
    ),
)

val LinkTextStyle = TextStyle(
    fontWeight = FontWeight.W400,
    fontSize = 14.sp,
    color = SignalBlue,
    textDecoration = TextDecoration.Underline,
)
