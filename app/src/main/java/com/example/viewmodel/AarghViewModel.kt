package com.example.viewmodel

import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.example.model.AarghUiState
import com.example.model.OperatorMode
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

class AarghViewModel(
    private val prefs: SharedPreferences
) : ViewModel() {

    companion object {
        const val PREFS_NAME = "aargh_preferences"
        const val KEY_THEME_MODE = "aargh_theme"
        const val KEY_KEYS_EXPANDED = "aargh_keys_visible"

        fun provideFactory(context: Context): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    val sharedPrefs = context.applicationContext.getSharedPreferences(
                        PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    return AarghViewModel(sharedPrefs) as T
                }
            }
    }

    private val _uiState = MutableStateFlow(
        AarghUiState(
            isDarkMode = prefs.getString(KEY_THEME_MODE, "light") == "dark",
            isKeysExpanded = prefs.getBoolean(KEY_KEYS_EXPANDED, true)
        )
    )
    val uiState: StateFlow<AarghUiState> = _uiState.asStateFlow()

    fun getThemeModeString(): String = if (_uiState.value.isDarkMode) "dark" else "light"

    fun setThemeModeFromString(mode: String) {
        val isDark = mode.equals("dark", ignoreCase = true)
        prefs.edit().putString(KEY_THEME_MODE, if (isDark) "dark" else "light").apply()
        _uiState.update { it.copy(isDarkMode = isDark) }
    }

    fun toggleThemeMode(): Boolean {
        val nextDark = !_uiState.value.isDarkMode
        prefs.edit().putString(KEY_THEME_MODE, if (nextDark) "dark" else "light").apply()
        _uiState.update { it.copy(isDarkMode = nextDark) }
        return nextDark
    }

    fun toggleKeysExpanded(): Boolean {
        val nextExpanded = !_uiState.value.isKeysExpanded
        prefs.edit().putBoolean(KEY_KEYS_EXPANDED, nextExpanded).apply()
        _uiState.update { it.copy(isKeysExpanded = nextExpanded) }
        return nextExpanded
    }

    fun toggleOperatorMode() {
        _uiState.update { state ->
            val nextMode = if (state.operatorMode == OperatorMode.R) {
                OperatorMode.MATH
            } else {
                OperatorMode.R
            }
            state.copy(operatorMode = nextMode)
        }
    }

    fun setPlotModalVisible(visible: Boolean) {
        _uiState.update { it.copy(isPlotModalVisible = visible) }
    }
}
