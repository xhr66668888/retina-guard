package com.retinaguard.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.retinaguard.ui.theme.CanvasWhite
import com.retinaguard.ui.theme.Charcoal
import com.retinaguard.ui.theme.LightNeutral
import com.retinaguard.ui.theme.SecondaryGrey
import com.retinaguard.ui.theme.VodafoneRed

@Composable
fun ChecklistRow(
    title: String,
    description: String,
    granted: Boolean,
    actionLabel: String,
    onAction: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier
            .fillMaxWidth()
            .clickable(onClick = onAction)
            .padding(horizontal = 16.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Box(
            modifier = Modifier
                .size(24.dp)
                .background(if (granted) VodafoneRed else LightNeutral, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            if (granted) {
                Icon(
                    Icons.Filled.Check,
                    contentDescription = null,
                    tint = CanvasWhite,
                    modifier = Modifier.size(14.dp),
                )
            } else {
                Text("·", color = Charcoal, style = MaterialTheme.typography.bodySmall)
            }
        }
        Column(Modifier.weight(1f)) {
            Text(
                title,
                style = MaterialTheme.typography.titleMedium,
                color = Charcoal,
            )
            Text(
                description,
                style = MaterialTheme.typography.bodySmall,
                color = SecondaryGrey,
            )
        }
        Text(
            text = if (granted) "Granted" else actionLabel,
            style = MaterialTheme.typography.labelLarge,
            color = if (granted) SecondaryGrey else VodafoneRed,
        )
        Icon(
            Icons.Filled.ChevronRight,
            contentDescription = null,
            tint = SecondaryGrey,
        )
    }
    HorizontalDivider(color = LightNeutral)
}
