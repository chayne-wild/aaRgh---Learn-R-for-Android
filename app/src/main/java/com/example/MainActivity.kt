package com.example

import android.content.res.Configuration
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import com.example.ui.AarghScreen
import com.example.ui.theme.AaRghTheme
import com.example.viewmodel.AarghViewModel

class MainActivity : ComponentActivity() {

    private val viewModel: AarghViewModel by viewModels {
        AarghViewModel.provideFactory(applicationContext)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Ensure WindowInsetsCompat.Type.ime() is dispatched smoothly to the root view & WebView
        ViewCompat.setOnApplyWindowInsetsListener(window.decorView) { view, windowInsets ->
            ViewCompat.onApplyWindowInsets(view, windowInsets)
        }

        setContent {
            val uiState by viewModel.uiState.collectAsState()
            AaRghTheme(darkTheme = uiState.isDarkMode) {
                AarghScreen(
                    viewModel = viewModel,
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        // Handled seamlessly without recreating Activity or reloading the WebView / webR session
    }
}
