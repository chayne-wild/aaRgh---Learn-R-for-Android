package com.example.ui

import android.content.res.Configuration
import android.view.ViewGroup
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTransformGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout. union
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import com.example.model.OperatorMode
import com.example.viewmodel.AarghViewModel
import com.example.webview.AarghWebViewHolder

/**
 * Main screen hosting the persistent offline webR + swirl WebView with full IME resize insets
 * and orientation-resilient state. Also provides modular Compose bars (`AarghTopActionBar`,
 * `AarghVariableChipsRow`, `AarghOperatorBar`, `AarghPinchZoomPlotDialog`) with single-row
 * `LazyRow` scrolling and Compose test tags.
 */
@Composable
fun AarghScreen(
    viewModel: AarghViewModel,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val insets = WindowInsets.safeDrawing.union(WindowInsets.ime)

    Surface(
        modifier = modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .windowInsetsPadding(insets),
        color = MaterialTheme.colorScheme.background
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .testTag("aargh_root_container")
        ) {
            AndroidView(
                modifier = Modifier
                    .fillMaxSize()
                    .testTag("webview_console"),
                factory = { ctx ->
                    AarghWebViewHolder.getOrCreateWebView(
                        context = ctx,
                        viewModel = viewModel
                    ).apply {
                        layoutParams = ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                        )
                    }
                },
                update = { webView ->
                    webView.keepScreenOn = true
                }
            )

            if (uiState.isPlotModalVisible) {
                AarghPinchZoomPlotDialog(
                    onDismiss = { viewModel.setPlotModalVisible(false) }
                )
            }
        }
    }
}

/**
 * Single-row horizontally scrollable Top App Bar (`LazyRow`) that never wraps or overlaps buttons.
 */
@Composable
fun AarghTopActionBar(
    isDarkMode: Boolean,
    isKeysExpanded: Boolean,
    isPlotReady: Boolean,
    onSendCommand: (String) -> Unit,
    onOpenPlot: () -> Unit,
    onToggleKeys: () -> Unit,
    onToggleTheme: () -> Unit,
    modifier: Modifier = Modifier
) {
    val configuration = LocalConfiguration.current
    val isLandscape = configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
    val barPaddingVertical = if (isLandscape) 4.dp else 8.dp
    val buttonHeight = if (isLandscape) 32.dp else 38.dp

    Row(
        modifier = modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
            .padding(horizontal = 10.dp, vertical = barPaddingVertical)
            .testTag("top_action_bar"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = "aaRgh",
            color = MaterialTheme.colorScheme.primary,
            fontFamily = FontFamily.Monospace,
            fontWeight = FontWeight.ExtraBold,
            fontSize = if (isLandscape) 15.sp else 17.sp,
            modifier = Modifier.testTag("brand_title")
        )

        LazyRow(
            modifier = Modifier
                .weight(1f)
                .testTag("top_actions_lazy_row"),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
            contentPadding = PaddingValues(horizontal = 2.dp)
        ) {
            val commands = listOf(
                "swirl()" to "swirl_button",
                "play()" to "play_button",
                "nxt()" to "nxt_button",
                "skip()" to "skip_button",
                "main()" to "main_button",
                "bye()" to "bye_button"
            )
            items(commands, key = { it.first }) { (cmd, tag) ->
                TopActionChip(
                    label = cmd,
                    testTag = tag,
                    height = buttonHeight,
                    onClick = { onSendCommand(cmd) }
                )
            }
            item(key = "plot") {
                TopActionChip(
                    label = "Plot",
                    testTag = "plot_button",
                    isHighlighted = isPlotReady,
                    height = buttonHeight,
                    onClick = onOpenPlot
                )
            }
            item(key = "keys") {
                TopActionChip(
                    label = "Keys",
                    testTag = "keys_toggle_button",
                    isHighlighted = isKeysExpanded,
                    height = buttonHeight,
                    onClick = onToggleKeys
                )
            }
            item(key = "theme") {
                TopActionChip(
                    label = if (isDarkMode) "Light" else "Dark",
                    testTag = "theme_toggle_button",
                    height = buttonHeight,
                    onClick = onToggleTheme
                )
            }
        }
    }
}

@Composable
private fun TopActionChip(
    label: String,
    testTag: String,
    height: androidx.compose.ui.unit.Dp,
    isHighlighted: Boolean = false,
    onClick: () -> Unit
) {
    val bgColor = if (isHighlighted) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.surfaceVariant
    }
    val textColor = if (isHighlighted) {
        MaterialTheme.colorScheme.onPrimary
    } else {
        MaterialTheme.colorScheme.onSurface
    }

    Box(
        modifier = Modifier
            .minimumInteractiveComponentSize()
            .height(height)
            .clip(RoundedCornerShape(6.dp))
            .background(bgColor)
            .border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(6.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 10.dp)
            .testTag(testTag),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            color = textColor,
            fontFamily = FontFamily.Monospace,
            fontWeight = FontWeight.SemiBold,
            fontSize = 12.sp,
            maxLines = 1
        )
    }
}

/**
 * Single-row horizontally scrollable Dynamic Variable Chips row (`LazyRow`).
 */
@Composable
fun AarghVariableChipsRow(
    variables: List<String>,
    onChipClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    if (variables.isEmpty()) return

    LazyRow(
        modifier = modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
            .padding(horizontal = 10.dp, vertical = 4.dp)
            .testTag("variable_chips_lazy_row"),
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        items(variables, key = { it }) { token ->
            Box(
                modifier = Modifier
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.surfaceVariant)
                    .border(1.dp, MaterialTheme.colorScheme.primary, CircleShape)
                    .clickable { onChipClick(token) }
                    .padding(horizontal = 10.dp, vertical = 4.dp)
                    .testTag("var_chip_$token"),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = token,
                    color = MaterialTheme.colorScheme.primary,
                    fontFamily = FontFamily.Monospace,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 12.sp,
                    maxLines = 1
                )
            }
        }
    }
}

/**
 * Single-row horizontally scrollable Primitive Operator Bar (`LazyRow`).
 */
@Composable
fun AarghOperatorBar(
    mode: OperatorMode,
    isExpanded: Boolean,
    onToggleMode: () -> Unit,
    onOperatorClick: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    if (!isExpanded) return

    LazyRow(
        modifier = modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(horizontal = 8.dp, vertical = 6.dp)
            .testTag("operator_bar_lazy_row"),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        item(key = "mode_toggle") {
            Box(
                modifier = Modifier
                    .height(34.dp)
                    .clip(RoundedCornerShape(5.dp))
                    .background(MaterialTheme.colorScheme.primary)
                    .clickable(onClick = onToggleMode)
                    .padding(horizontal = 8.dp)
                    .testTag("operator_mode_toggle"),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = mode.label,
                    color = MaterialTheme.colorScheme.onPrimary,
                    fontFamily = FontFamily.Monospace,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    maxLines = 1
                )
            }
        }

        items(mode.symbols, key = { it }) { symbol ->
            Box(
                modifier = Modifier
                    .height(34.dp)
                    .clip(RoundedCornerShape(5.dp))
                    .background(MaterialTheme.colorScheme.surface)
                    .border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(5.dp))
                    .clickable { onOperatorClick(symbol) }
                    .padding(horizontal = 10.dp)
                    .testTag("op_key_$symbol"),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = symbol,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontFamily = FontFamily.Monospace,
                    fontWeight = FontWeight.Bold,
                    fontSize = 14.sp,
                    maxLines = 1
                )
            }
        }
    }
}

@Composable
fun AarghPinchZoomPlotDialog(
    onDismiss: () -> Unit
) {
    var scale by remember { mutableFloatStateOf(1f) }
    var offsetX by remember { mutableFloatStateOf(0f) }
    var offsetY by remember { mutableFloatStateOf(0f) }

    Dialog(onDismissRequest = onDismiss) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(MaterialTheme.colorScheme.surface)
                .border(1.dp, MaterialTheme.colorScheme.outline, RoundedCornerShape(12.dp))
                .padding(12.dp)
                .testTag("plot_modal_dialog")
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "R Graphics Output",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                TopActionChip(
                    label = "Close",
                    testTag = "close_plot_modal_button",
                    height = 34.dp,
                    onClick = onDismiss
                )
            }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(320.dp)
                    .padding(top = 8.dp)
                    .background(MaterialTheme.colorScheme.background)
                    .pointerInput(Unit) {
                        detectTransformGestures { _, pan, zoom, _ ->
                            scale = (scale * zoom).coerceIn(1f, 5f)
                            if (scale > 1f) {
                                offsetX += pan.x
                                offsetY += pan.y
                            } else {
                                offsetX = 0f
                                offsetY = 0f
                            }
                        }
                    }
                    .graphicsLayer(
                        scaleX = scale,
                        scaleY = scale,
                        translationX = offsetX,
                        translationY = offsetY
                    ),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Pinch to zoom plot canvas",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}
