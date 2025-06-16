# React Shadcn/UI Template

A React TypeScript + Tailwind template powered by [shadcn/ui](https://ui.shadcn.com/).

## 🎉 Features

- **React** - A JavaScript library for building user interfaces.
- **TypeScript** - A typed superset of JavaScript that compiles to plain JavaScript.
- **Tailwind CSS** - A utility-first CSS framework.
- **shadcn/ui** - Beautifully designed components you can copy and paste into your apps.
- **React Router** - Declarative routing for React.

## 🚀 Getting Started
Follow these steps to get started:

1. Install the dependencies:

    ```bash
    npm install
    ```

2. Start the development server:

    ```bash
    npm run start
    ```

## 📜 Available Scripts
### Compiles and hot-reloads for development
Runs the app in the development mode at [http://localhost:3000](http://localhost:3000).\
The page will reload if you make edits. You will also see any lint errors in the console.
```
npm run start
```

### Compiles and minifies for production
Builds the app for production to the `build` folder. It correctly bundles React in production mode and optimizes the build for the best performance.
```
npm run build
```

### Remove the project single-build dependency
This command will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you’re on your own.

**Note: This is a one-way operation. Once you `eject`, you can’t go back!**
```
npm run eject
```

## 📂 Project Structure

The project structure follows a standard React application layout:

```python
React-Shadcn-UI-Template/
  ├── node_modules/              # Project dependencies
  ├── public/                    # Public assets (e.g., index.html, favicon)
  ├── src/                       # Application source code
  │   ├── components/            # Shared React components
  │   │   └── ui/                # Prebuilt UI components from Shadcn UI library
  │   │       ├── accordion.tsx         # Accordion component
  │   │       ├── alert-dialog.tsx      # Alert dialog (modal) component
  │   │       ├── alert.tsx             # Alert notification component
  │   │       ├── aspect-ratio.tsx      # Aspect ratio wrapper
  │   │       ├── avatar.tsx            # User avatar component
  │   │       ├── badge.tsx             # Small status badge
  │   │       ├── breadcrumb.tsx        # Breadcrumb navigation
  │   │       ├── button.tsx            # Styled button component
  │   │       ├── calendar.tsx          # Calendar/date picker
  │   │       ├── card.tsx              # Card container component
  │   │       ├── carousel.tsx          # Carousel/slider for media
  │   │       ├── chart.tsx             # Chart/graph integration
  │   │       ├── checkbox.tsx          # Checkbox input
  │   │       ├── collapsible.tsx       # Expand/collapse container
  │   │       ├── command.tsx           # Command palette interface
  │   │       ├── context-menu.tsx      # Right-click context menu
  │   │       ├── dialog.tsx            # Dialog/modal component
  │   │       ├── drawer.tsx            # Slide-in drawer component
  │   │       ├── dropdown-menu.tsx     # Dropdown menu
  │   │       ├── form.tsx              # Form builder and utilities
  │   │       ├── hover-card.tsx        # Tooltip-style hover card
  │   │       ├── input-otp.tsx         # OTP (one-time-password) input
  │   │       ├── input.tsx             # Text input field
  │   │       ├── label.tsx             # Label for form fields
  │   │       ├── menubar.tsx           # Horizontal menu bar
  │   │       ├── navigation-menu.tsx   # Responsive nav menu
  │   │       ├── pagination.tsx        # Pagination controls
  │   │       ├── popover.tsx           # Floating popover UI
  │   │       ├── progress.tsx          # Progress bar
  │   │       ├── radio-group.tsx       # Grouped radio buttons
  │   │       ├── resizable.tsx         # Resizable container
  │   │       ├── scroll-area.tsx       # Custom scroll container
  │   │       ├── select.tsx            # Dropdown select input
  │   │       ├── separator.tsx         # Horizontal/vertical separator
  │   │       ├── sheet.tsx             # Bottom sheet UI
  │   │       ├── sidebar.tsx           # Sidebar navigation layout
  │   │       ├── skeleton.tsx          # Skeleton loading placeholders
  │   │       ├── slider.tsx            # Slider input (range)
  │   │       ├── sonner.tsx            # Toast notification system
  │   │       ├── switch.tsx            # Toggle switch input
  │   │       ├── table.tsx             # Data table component
  │   │       ├── tabs.tsx              # Tabbed navigation
  │   │       ├── textarea.tsx          # Multiline input
  │   │       ├── toggle-group.tsx      # Toggle group (exclusive or multiple)
  │   │       ├── toggle.tsx            # Single toggle button
  │   │       └── tooltip.tsx           # Tooltip component
  │   ├── pages/                 # Top-level route components
  │   │   └── HomePage.tsx       # Main landing page component
  │   ├── styles/                # Global and component-level styles
  │   │   └── App.css            # App-wide CSS (includes Tailwind + Shadcn config)
  │   ├── App.tsx                # Main application component
  │   ├── index.css              # Global CSS entry point
  │   └── index.tsx              # ReactDOM render and root setup
  ├── craco.config.js            # CRACO customization for build tools
  ├── tailwind.config.js         # Tailwind CSS configuration file
  └── tsconfig.json              # TypeScript compiler options

```

