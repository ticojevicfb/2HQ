# Architecture Overview

## 🏗 Architecture Pattern
**Clean Architecture with MVVM** - We implemented a layered architecture with clear separation of concerns:
- **Presentation Layer** (Views): SwiftUI views for UI rendering
- **Domain Layer** (ViewModels): Business logic and state management
- **Data Layer** (Services/Repositories): Data access and persistence

## 🛠 Technical Stack
- **SwiftUI** for declarative UI
- **SwiftData** for local persistence (bookmarks and caching)
- **Async/Await** for asynchronous operations
- **Modern Swift Concurrency** throughout the codebase

## 🔧 Key Architectural Decisions

### Dependency Injection
Implemented a custom `DependencyContainer` to manage service dependencies, making the code:
- ✅ **Highly testable** - Easy to mock dependencies
- ✅ **Flexible** - Simple to swap implementations
- ✅ **Maintainable** - Clear dependency graph

### Offline-First Strategy
True offline-first architecture with:
- SwiftData as primary data source
- Network as secondary data source
- Automatic cache updates when online
- Clear offline indication to users

### Localization System
Custom `LanguageManager` with:
- Dynamic language switching (EN/SR)
- Localizable.xcstrings for modern string management
- Instant language changes without app restart

### Accessibility Implementation
Comprehensive accessibility support including:
- Full VoiceOver compatibility
- Dynamic Type support
- Custom accessibility actions
- Screen reader announcements

## ⚡ Advanced Features Implemented

### 1. Debounced Search
- 300ms debounce to prevent excessive API calls
- Client-side filtering for immediate feedback
- Cancelable network requests during rapid typing

### 2. Cancelable Network Requests
- Proper task cancellation using Swift's native task management
- Prevention of outdated data display
- Memory leak avoidance

### 3. State Management
**Pragmatic Approach** - We used separate `@Published` properties for different aspects of state:
- `articles` array for data
- `isLoading` boolean for activity indication
- `errorMessage` for error handling
- Additional flags for offline status and filtering

**Why This Works for This Project**:
1. **Simplicity** - Easy to reason about each state aspect
2. **SwiftUI Integration** - Each property triggers UI updates independently
3. **Sufficient for Requirements** - Meets all functional needs

**Production Enhancement Needed**: For a larger app, we would implement a single `enum ViewState` to ensure atomic state transitions.

## 📱 Platform Considerations

### Minimum iOS Version
**iOS 17.0+** required due to:
- SwiftData (replacement for Core Data)
- Latest SwiftUI features
- Modern Swift Concurrency patterns

### Trade-off Analysis
- **✅ Pros**: Access to latest Apple technologies, better performance, cleaner APIs
- **❌ Cons**: Limits user base to newer devices, approximately 80% of iOS users

## 🎯 Conclusion

This architecture represents implementation that:
- Successfully meets all assignment requirements
- Uses modern iOS development practices
- Maintains clean separation of concerns
- Provides excellent user experience
- Is scalable for future enhancements
