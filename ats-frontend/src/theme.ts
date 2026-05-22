import type { GlobalThemeOverrides } from 'naive-ui'

/**
 * Naive UI 主题覆盖
 * 与 src/styles/tokens.css 保持一致：颜色、圆角、字号、过渡
 */
export const themeOverrides: GlobalThemeOverrides = {
  common: {
    primaryColor: '#10b981',
    primaryColorHover: '#34d399',
    primaryColorPressed: '#059669',
    primaryColorSuppl: '#10b981',

    infoColor: '#3b82f6',
    successColor: '#10b981',
    warningColor: '#f59e0b',
    errorColor: '#ef4444',

    bodyColor: '#fafafa',
    cardColor: '#ffffff',
    modalColor: '#ffffff',
    popoverColor: '#ffffff',

    textColorBase: '#18181b',
    textColor1: '#18181b',
    textColor2: '#27272a',
    textColor3: '#52525b',
    textColorDisabled: '#a1a1aa',

    borderColor: '#e4e4e7',
    dividerColor: '#ececef',

    fontFamily:
      'Inter, -apple-system, BlinkMacSystemFont, \'PingFang SC\', \'Microsoft YaHei\', \'Noto Sans SC\', sans-serif',
    fontFamilyMono:
      '\'JetBrains Mono\', \'SF Mono\', Consolas, \'Liberation Mono\', monospace',

    fontSize: '14px',
    fontSizeMedium: '14px',
    fontSizeLarge: '16px',
    fontSizeSmall: '13px',

    borderRadius: '8px',
    borderRadiusSmall: '6px',

    cubicBezierEaseInOut: 'cubic-bezier(0.4, 0, 0.2, 1)',
    cubicBezierEaseOut: 'cubic-bezier(0.16, 1, 0.3, 1)',
  },
  Button: {
    fontWeight: '500',
    textColorPrimary: '#ffffff',
    heightMedium: '36px',
  },
  Card: {
    borderRadius: '12px',
    paddingMedium: '20px',
  },
  Input: {
    heightMedium: '36px',
    borderRadius: '8px',
  },
  DataTable: {
    thColor: '#fafafa',
    thTextColor: '#71717a',
    thFontWeight: '600',
    tdColorHover: '#fafafa',
  },
  Tag: {
    borderRadius: '6px',
  },
}
