package com.example

import com.example.model.AarghUiState
import com.example.model.OperatorMode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AarghUnitTest {

    @Test
    fun defaultUiStateUsesLightModeAndExpandedKeys() {
        val state = AarghUiState()
        assertFalse("Default theme must be Light Mode", state.isDarkMode)
        assertTrue("Operator keys bar must default to expanded", state.isKeysExpanded)
        assertEquals(OperatorMode.R, state.operatorMode)
        assertEquals(">", state.promptLabel)
    }

    @Test
    fun operatorModesContainRequiredSymbols() {
        assertTrue(OperatorMode.R.symbols.containsAll(listOf("<", "-", "|", ">", "$", "(", ")", "[", "]")))
        assertTrue(OperatorMode.MATH.symbols.containsAll(listOf("<", ">", "=", "!", "&", "|", "%", "*")))
    }
}
