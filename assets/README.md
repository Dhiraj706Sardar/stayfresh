# StayFresh Assets Directory

This directory contains all the visual and audio assets for the StayFresh app. The assets are organized into logical folders for easy management and maintenance.

## 📁 Directory Structure

```
assets/
├── images/
│   ├── onboarding/          # Onboarding screen illustrations
│   ├── illustrations/       # App graphics and illustrations
│   ├── logos/              # App logos and branding
│   └── placeholders/       # Default/placeholder images
├── icons/
│   ├── categories/         # Grocery category icons
│   └── navigation/         # Navigation and UI icons
├── fonts/                  # Custom fonts (if any)
└── sounds/                 # Audio files and notifications
```

## 🎨 Design Guidelines

### Color Palette
- **Primary Green**: #4CAF50
- **Dark Green**: #2E7D32
- **Light Green**: #C8E6C9
- **Accent Green**: #66BB6A
- **White**: #FFFFFF
- **Off White**: #FAFAFA

### Style Guidelines
- **Design Style**: Clean, minimal, modern
- **Icon Style**: Material Design inspired with green accents
- **Illustration Style**: Simple, friendly, professional
- **Image Quality**: High resolution, optimized for mobile

## 📱 Asset Specifications

### Images
- **Onboarding**: 300x300px minimum, PNG with transparency
- **Illustrations**: 200x400px, PNG or SVG
- **Logos**: Various sizes (150x150px standard, 1024x1024px for app store)
- **Placeholders**: 100x200px, PNG with transparency

### Icons
- **Navigation Icons**: 24x24px or 32x32px
- **Category Icons**: 48x48px or 64x64px
- **Format**: PNG with transparency or SVG
- **Style**: Consistent with Material Design

### Fonts
- **Supported Formats**: .ttf, .otf
- **Usage**: Declare in pubspec.yaml under fonts section

### Sounds
- **Formats**: .mp3, .wav, .aac
- **Usage**: Notification sounds, UI feedback
- **Size**: Keep under 1MB for performance

## 🔧 Usage in Code

### Loading Images
```dart
// From assets
Image.asset('assets/images/logos/stayfresh_logo.png')

// With placeholder
Image.asset(
  'assets/images/placeholders/default_grocery_item.png',
  width: 100,
  height: 100,
)
```

### Loading Icons
```dart
// Category icons
Image.asset(
  'assets/icons/categories/icon_fruits.png',
  width: 48,
  height: 48,
)

// Navigation icons
Image.asset('assets/icons/navigation/nav_home_active.png')
```

### Loading Sounds
```dart
// Using flutter_local_notifications
const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  'channel_id',
  'channel_name',
  sound: RawResourceAndroidNotificationSound('notification'),
);
```

## 📋 Asset Checklist

### Required Assets for MVP
- [ ] App logo (stayfresh_logo.png)
- [ ] Splash screen logo (splash_logo.png)
- [ ] Onboarding illustrations (3 images)
- [ ] Empty state illustration
- [ ] Category icons (9 categories)
- [ ] Navigation icons (active/inactive states)
- [ ] Default grocery item placeholder
- [ ] User avatar placeholder

### Optional Assets for Enhanced UX
- [ ] Success/celebration illustrations
- [ ] Error state illustrations
- [ ] Loading animations (Lottie files)
- [ ] Custom notification sounds
- [ ] Category placeholder images
- [ ] Branded icons and graphics

## 🎯 Asset Optimization

### Performance Tips
1. **Compress Images**: Use tools like TinyPNG to reduce file sizes
2. **Use Appropriate Formats**: PNG for transparency, JPG for photos
3. **Multiple Resolutions**: Provide @2x and @3x versions for different screen densities
4. **SVG for Icons**: Use SVG for scalable icons when possible
5. **Lazy Loading**: Load images only when needed

### File Naming Convention
- Use lowercase with underscores: `grocery_item_placeholder.png`
- Include size in filename if multiple sizes: `logo_150x150.png`
- Use descriptive names: `onboarding_track_groceries.png`
- Include state for interactive elements: `nav_home_active.png`

## 🚀 Adding New Assets

1. **Place files** in appropriate directory
2. **Update pubspec.yaml** if adding new directories
3. **Follow naming conventions**
4. **Optimize file sizes**
5. **Test on different screen sizes**
6. **Update this documentation**

## 📝 Notes

- All assets should maintain the app's clean, minimal aesthetic
- Use consistent color palette throughout
- Ensure accessibility with sufficient contrast
- Test assets on both light and dark themes
- Keep file sizes optimized for mobile performance

---

*Last updated: $(date)*
*StayFresh App - Premium Grocery Tracker*