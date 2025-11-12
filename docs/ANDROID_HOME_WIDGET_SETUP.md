# Android Home Screen Widget Setup Guide

## Overview

This guide will help you set up a fully functional Android home screen widget for your Money Control app that displays your balance and provides quick access to send/receive money.

## What You'll Get

✅ **Real-time Balance Display** on your home screen

✅ **Quick Action Buttons** for Send and Receive

✅ **Auto-refresh** capability

✅ **Professional gradient design**

✅ **Works even when app is closed**

---

## 📚 Prerequisites

Before starting, ensure you have:
- Android Studio installed
- Your Money Control Flutter project set up
- Basic knowledge of Android development
- Access to the project's Android folder

---

## 🚀 Step-by-Step Setup

### Step 1: Install Dependencies

The `home_widget` package has already been added to your `pubspec.yaml`. Run:

```bash
flutter pub get
```

### Step 2: Create Required Android Resource Files

You need to manually create several XML files in your Android project:

#### 2.1 Create Widget Layout

Create file: `android/app/src/main/res/layout/money_control_widget.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@drawable/widget_background"
    android:orientation="vertical"
    android:padding="16dp">

    <!-- Header -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center_vertical"
        android:paddingBottom="8dp">

        <TextView
            android:layout_width="0dp"
            android:layout_height="wrap_content"
            android:layout_weight="1"
            android:text="Money Control"
            android:textColor="#FFFFFF"
            android:textSize="16sp"
            android:textStyle="bold" />

        <ImageButton
            android:id="@+id/refresh_button"
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:background="?attr/selectableItemBackgroundBorderless"
            android:contentDescription="Refresh"
            android:src="@android:drawable/ic_popup_sync"
            android:tint="#FFFFFF" />
    </LinearLayout>

    <View
        android:layout_width="match_parent"
        android:layout_height="1dp"
        android:background="#40FFFFFF"
        android:layout_marginBottom="12dp" />

    <!-- Balance Section -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:paddingVertical="8dp">

        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Available Balance"
            android:textColor="#B3FFFFFF"
            android:textSize="12sp" />

        <TextView
            android:id="@+id/balance_text"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="₹ 0.00"
            android:textColor="#FFFFFF"
            android:textSize="28sp"
            android:textStyle="bold"
            android:layout_marginTop="4dp" />

        <TextView
            android:id="@+id/last_updated_text"
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Tap to update"
            android:textColor="#80FFFFFF"
            android:textSize="10sp"
            android:layout_marginTop="4dp" />
    </LinearLayout>

    <View
        android:layout_width="match_parent"
        android:layout_height="0dp"
        android:layout_weight="1" />

    <!-- Action Buttons -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:orientation="horizontal"
        android:gravity="center"
        android:paddingTop="8dp">

        <Button
            android:id="@+id/send_button"
            android:layout_width="0dp"
            android:layout_height="48dp"
            android:layout_weight="1"
            android:layout_marginEnd="4dp"
            android:text="Send"
            android:textColor="#FFFFFF"
            android:background="@drawable/button_send_background" />

        <Button
            android:id="@+id/receive_button"
            android:layout_width="0dp"
            android:layout_height="48dp"
            android:layout_weight="1"
            android:layout_marginStart="4dp"
            android:text="Receive"
            android:textColor="#FFFFFF"
            android:background="@drawable/button_receive_background" />
    </LinearLayout>
</LinearLayout>
```

#### 2.2 Create Widget Background

Create file: `android/app/src/main/res/drawable/widget_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:angle="135"
        android:startColor="#2F80ED"
        android:endColor="#8A3FFC"
        android:type="linear" />
    <corners android:radius="24dp" />
</shape>
```

#### 2.3 Create Send Button Background

Create file: `android/app/src/main/res/drawable/button_send_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#2F80ED" />
    <corners android:radius="12dp" />
</shape>
```

#### 2.4 Create Receive Button Background

Create file: `android/app/src/main/res/drawable/button_receive_background.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <solid android:color="#8A3FFC" />
    <corners android:radius="12dp" />
</shape>
```

#### 2.5 Add Widget Description String

Add to `android/app/src/main/res/values/strings.xml`:

```xml
<resources>
    <!-- Existing strings... -->
    <string name="widget_description">View your balance and quick access to transactions</string>
</resources>
```

If `strings.xml` doesn't exist, create it:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Money Control</string>
    <string name="widget_description">View your balance and quick access to transactions</string>
</resources>
```

### Step 3: Create Widget Provider Class

Create file: `android/app/src/main/kotlin/com/example/money_control/MoneyControlWidgetProvider.kt`

```kotlin
package com.example.money_control

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MoneyControlWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "REFRESH_WIDGET") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, MoneyControlWidgetProvider::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.money_control_widget)

            // Get data from SharedPreferences
            val balance = widgetData.getString("balance", "₹ 0.00")
            val lastUpdated = widgetData.getString("lastUpdated", "Tap to update")

            // Update widget views
            views.setTextViewText(R.id.balance_text, balance)
            views.setTextViewText(R.id.last_updated_text, lastUpdated)

            // Set click listeners
            val refreshIntent = Intent(context, MoneyControlWidgetProvider::class.java)
            refreshIntent.action = "REFRESH_WIDGET"
            val refreshPendingIntent = android.app.PendingIntent.getBroadcast(
                context, 0, refreshIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.refresh_button, refreshPendingIntent)

            // Send button - open app
            val sendIntent = HomeWidgetPlugin.getLaunchIntent(context,"send")
            views.setOnClickPendingIntent(R.id.send_button, sendIntent)

            // Receive button - open app
            val receiveIntent = HomeWidgetPlugin.getLaunchIntent(context,"receive")
            views.setOnClickPendingIntent(R.id.receive_button, receiveIntent)

            // Update widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```

### Step 4: Update AndroidManifest.xml

Add the widget receiver to your `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<receiver
    android:name=".MoneyControlWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        <action android:name="REFRESH_WIDGET" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/money_control_widget_info" />
</receiver>
```

### Step 5: Initialize Widget in Flutter

Update your `main.dart` to initialize the widget:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:money_control/services/home_widget_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Home Widget
  await HomeWidgetService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Control',
      home: HomePage(),
    );
  }
}
```

### Step 6: Update Widget After Transactions

In your transaction completion code, add:

```dart
import 'package:money_control/services/home_widget_service.dart';

// After successfully adding a transaction
await HomeWidgetService.updateAfterTransaction();
```

### Step 7: Handle Widget Clicks

In your home screen, check if the app was launched from widget:

```dart
import 'package:money_control/services/home_widget_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    checkWidgetLaunch();
  }

  Future<void> checkWidgetLaunch() async {
    final uri = await HomeWidgetService.getWidgetLaunchAction();
    if (uri != null) {
      switch (uri.host) {
        case 'send':
          // Navigate to send money screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                initialType: 'send',
              ),
            ),
          );
          break;
        case 'receive':
          // Navigate to receive money screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionScreen(
                initialType: 'receive',
              ),
            ),
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Your home page UI
    );
  }
}
```

---

## 📱 Testing the Widget

### Build and Install

1. Build your Flutter app:
   ```bash
   flutter build apk --release
   ```

2. Install on your device:
   ```bash
   flutter install
   ```

### Add Widget to Home Screen

1. **Long press** on your Android home screen
2. Tap **"Widgets"**
3. Find **"Money Control"** widget
4. **Drag and drop** it to your home screen
5. The widget will appear with your balance!

---

## 🎨 Customization

### Change Colors

Edit the gradient in `widget_background.xml`:

```xml
<gradient
    android:angle="135"
    android:startColor="#YOUR_START_COLOR"
    android:endColor="#YOUR_END_COLOR"
    android:type="linear" />
```

### Change Widget Size

Edit `money_control_widget_info.xml`:

```xml
android:minWidth="250dp"    <!-- Minimum width -->
android:minHeight="180dp"   <!-- Minimum height -->
```

### Change Update Frequency

Edit `money_control_widget_info.xml`:

```xml
android:updatePeriodMillis="1800000"  <!-- 30 minutes in milliseconds -->
```

---

## ⚡ Troubleshooting

### Widget Not Showing in Widget Library

**Solution:**
1. Rebuild the app completely:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```
2. Uninstall and reinstall the app
3. Restart your device

### Widget Showing "₹ 0.00"

**Solution:**
1. Open the app and log in
2. Add a transaction
3. The widget will update automatically
4. Or tap the refresh button on the widget

### Widget Not Updating

**Solution:**
1. Check if user is logged in
2. Verify Firebase connection
3. Manually call update:
   ```dart
   await HomeWidgetService.updateWidget();
   ```

### Widget Buttons Not Working

**Solution:**
1. Verify PendingIntent flags in Kotlin code
2. Check AndroidManifest.xml receiver configuration
3. Ensure app has proper permissions

---

## 📚 Additional Resources

- [home_widget Package Documentation](https://pub.dev/packages/home_widget)
- [Android Widget Guide](https://developer.android.com/develop/ui/views/appwidgets)
- [Flutter Platform Integration](https://docs.flutter.dev/platform-integration)

---

## ✅ Checklist

Before testing, ensure you've completed:

- [ ] Added `home_widget` package to pubspec.yaml
- [ ] Created `money_control_widget.xml` layout
- [ ] Created widget background drawable
- [ ] Created button background drawables
- [ ] Created `money_control_widget_info.xml`
- [ ] Created `MoneyControlWidgetProvider.kt`
- [ ] Updated `AndroidManifest.xml`
- [ ] Initialized widget in `main.dart`
- [ ] Added widget update calls after transactions
- [ ] Added widget click handling
- [ ] Built and installed the app

---

## 👍 Next Steps

Once your widget is working:

1. **Test all scenarios**: Login, logout, transactions
2. **Customize design**: Match your app's branding
3. **Add more features**: Recent transactions, charts, etc.
4. **Optimize performance**: Cache balance, reduce updates
5. **Add analytics**: Track widget usage

---

**Created:** November 12, 2025

**Version:** 1.0.0

**Maintainer:** Money Control Development Team
