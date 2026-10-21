package com.example.model

enum class OperatorMode(val label: String, val symbols: List<String>) {
    R(
        label = "[R]",
        symbols = listOf("<", "-", "|", ">", "$", "(", ")", "[", "]", "\"", "'", ",", ":", "?", "_")
    ),
    MATH(
        label = "[Math]",
        symbols = listOf("<", ">", "=", "!", "&", "|", "%", "*", "+", "-", "/", "^", "~")
    )
}

enum class TranscriptLineType {
    STDOUT,
    STDERR,
    CMD
}

data class TranscriptLine(
    val id: Long,
    val text: String,
    val type: TranscriptLineType
)

data class AarghUiState(
    val isDarkMode: Boolean = false, // Light Mode Default
    val isKeysExpanded: Boolean = true,
    val operatorMode: OperatorMode = OperatorMode.R,
    val promptLabel: String = ">",
    val isPausedAtContinue: Boolean = false,
    val isPlotReady: Boolean = false,
    val isPlotModalVisible: Boolean = false,
    val isCrossOriginIsolated: Boolean = true,
    val variableChips: List<String> = emptyList(),
    val transcriptLines: List<TranscriptLine> = emptyList()
)
