package com.retinaguard.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.retinaguard.ui.theme.VodafoneRed

/**
 * Full-width brand red strip used as a chapter break.
 * 40dp on mobile per spec.
 */
@Composable
fun RedBand(modifier: Modifier = Modifier, height: Dp = 40.dp) {
    Box(
        modifier
            .fillMaxWidth()
            .height(height)
            .background(VodafoneRed)
    )
}
