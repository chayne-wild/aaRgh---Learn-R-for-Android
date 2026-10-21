package com.example.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColorScheme = lightColorScheme(
    primary = LightAccent,
    onPrimary = LightAccentFg,
    secondary = LightCmd,
    onSecondary = LightPanel,
    tertiary = LightVarChipText,
    background = LightBackground,
    onBackground = LightText,
    surface = LightPanel,
    onSurface = LightText,
    surfaceVariant = LightChipBg,
    onSurfaceVariant = LightMuted,
    outline = LightBorder,
    error = LightError
)

private val DarkColorScheme = darkColorScheme(
    primary = DarkAccent,
    onPrimary = DarkAccentFg,
    secondary = DarkCmd,
    onSecondary = DarkBackground,
    tertiary = DarkVarChipText,
    background = DarkBackground,
    onBackground = DarkText,
    surface = DarkPanel,
    onSurface = DarkText,
    surfaceVariant = DarkChipBg,
    onSurfaceVariant = DarkMuted,
    outline = DarkBorder,
    error = DarkError
)

@Composable
fun AaRghTheme(
    darkTheme: Boolean = false, // Light Mode default per specification
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AarghTypography,
        content = content
    )
}
