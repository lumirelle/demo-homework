import {
  defineConfig,
  presetAttributify,
  presetIcons,
  presetUno,
  transformerDirectives,
  transformerVariantGroup,
} from 'unocss'

/**
 * UnoCSS · ATS Frontend
 *
 * 设计原则（沉淀进 SKILL.md 2.6）：
 *  1. CSS custom properties（tokens.css）是 **单一真值来源**；
 *     UnoCSS theme 通过 var(--xxx) 引用 token，绝不重复维护色值。
 *  2. 现有手写 utility（text-gradient / aurora-layer / fade-* 等）
 *     全部以同名 shortcut 提供，组件零修改即可迁移。
 *  3. 微交互（hover）与 页面转场（route）严格区分两套 ease/duration token，
 *     在 theme.transitionTimingFunction / animation 里都有体现。
 *  4. 复杂 keyframes（aurora-drift / pulse / cursor-glow）仍写在
 *     global.css 里，shortcuts 只负责"组合"它们。
 */
export default defineConfig({
  presets: [
    presetUno(),
    presetAttributify({ prefix: 'u-', prefixedOnly: false }),
    presetIcons({
      scale: 1.1,
      extraProperties: {
        'display': 'inline-block',
        'vertical-align': 'middle',
      },
    }),
  ],
  transformers: [
    transformerDirectives(), // @apply / @screen / theme()
    transformerVariantGroup(), // hover:(bg-x text-y) → 拆开
  ],

  /** Token 桥接：theme 里的色板/间距/字号/曲线全部引用 CSS custom properties */
  theme: {
    colors: {
      brand: {
        50: 'var(--brand-50)',
        100: 'var(--brand-100)',
        200: 'var(--brand-200)',
        300: 'var(--brand-300)',
        400: 'var(--brand-400)',
        500: 'var(--brand-500)',
        600: 'var(--brand-600)',
        700: 'var(--brand-700)',
        800: 'var(--brand-800)',
        900: 'var(--brand-900)',
        DEFAULT: 'var(--brand-500)',
      },
      gray: {
        0: 'var(--gray-0)',
        50: 'var(--gray-50)',
        100: 'var(--gray-100)',
        150: 'var(--gray-150)',
        200: 'var(--gray-200)',
        300: 'var(--gray-300)',
        400: 'var(--gray-400)',
        500: 'var(--gray-500)',
        600: 'var(--gray-600)',
        700: 'var(--gray-700)',
        800: 'var(--gray-800)',
        900: 'var(--gray-900)',
        950: 'var(--gray-950)',
      },
      success: {
        50: 'var(--success-50)',
        500: 'var(--success-500)',
        700: 'var(--success-700)',
        DEFAULT: 'var(--success-500)',
      },
      warning: {
        50: 'var(--warning-50)',
        500: 'var(--warning-500)',
        700: 'var(--warning-700)',
        DEFAULT: 'var(--warning-500)',
      },
      danger: {
        50: 'var(--danger-50)',
        500: 'var(--danger-500)',
        700: 'var(--danger-700)',
        DEFAULT: 'var(--danger-500)',
      },
      info: {
        50: 'var(--info-50)',
        500: 'var(--info-500)',
        700: 'var(--info-700)',
        DEFAULT: 'var(--info-500)',
      },
      // 张扬武器库 accent 七色（成长系）
      accent: {
        mint: 'var(--accent-mint)',
        emerald: 'var(--accent-emerald)',
        teal: 'var(--accent-teal)',
        cyan: 'var(--accent-cyan)',
        lime: 'var(--accent-lime)',
        amber: 'var(--accent-amber)',
        forest: 'var(--accent-forest)',
      },
    },
    backgroundColor: {
      app: 'var(--bg-app)',
      elevated: 'var(--bg-elevated)',
      muted: 'var(--bg-muted)',
      hover: 'var(--bg-hover)',
      active: 'var(--bg-active)',
    },
    textColor: {
      primary: 'var(--text-primary)',
      secondary: 'var(--text-secondary)',
      tertiary: 'var(--text-tertiary)',
      disabled: 'var(--text-disabled)',
      inverse: 'var(--text-inverse)',
    },
    borderColor: {
      subtle: 'var(--border-subtle)',
      default: 'var(--border-default)',
    },
    fontFamily: {
      sans: 'var(--font-sans)',
      mono: 'var(--font-mono)',
    },
    fontSize: {
      'xs': 'var(--fs-xs)',
      'sm': 'var(--fs-sm)',
      'md': 'var(--fs-md)',
      'lg': 'var(--fs-lg)',
      'xl': 'var(--fs-xl)',
      '2xl': 'var(--fs-2xl)',
      '3xl': 'var(--fs-3xl)',
      'display-sm': 'var(--fs-display-sm)',
      'display-md': 'var(--fs-display-md)',
      'display-lg': 'var(--fs-display-lg)',
    },
    borderRadius: {
      sm: 'var(--radius-sm)',
      md: 'var(--radius-md)',
      lg: 'var(--radius-lg)',
      full: 'var(--radius-full)',
    },
    boxShadow: {
      'sm': 'var(--shadow-sm)',
      'md': 'var(--shadow-md)',
      'lg': 'var(--shadow-lg)',
      'glow-brand': 'var(--glow-brand)',
      'glow-mint': 'var(--glow-mint)',
      'glow-teal': 'var(--glow-teal)',
      'glow-amber': 'var(--glow-amber)',
    },
    /** ⚠️ 曲线分两轨：page-* 给路由/模态，默认给 hover/focus */
    transitionTimingFunction: {
      'out': 'var(--ease-out)',
      'in-out': 'var(--ease-in-out)',
      'bounce': 'var(--ease-bounce)',
      'page-in': 'var(--ease-page-in)',
      'page-out': 'var(--ease-page-out)',
    },
    transitionDuration: {
      'fast': 'var(--dur-fast)',
      'base': 'var(--dur-base)',
      'slow': 'var(--dur-slow)',
      'page-in': 'var(--dur-page-in)',
      'page-out': 'var(--dur-page-out)',
      'fade': 'var(--dur-fade)',
    },
  },

  /**
   * Rules：自定义产出真实 CSS 的 utility（高于 shortcut，可控性更强）
   *
   * ⚠️ 渐变相关 utility 必须用 rule 而不是 shortcut——
   * UnoCSS 的 `bg-[var(--xxx)]` 默认推断为 background-color，linear-gradient 会失效；
   * 这里显式输出 background-image 才能让 background-clip:text 配套渲染。
   */
  rules: [
    // text-gradient · text-gradient-spring|bloom|forest|brand|aurora（渐变文字）
    [
      /^text-gradient(?:-(spring|bloom|forest|brand|aurora))?$/,
      ([, name]) => ({
        'background-image': `var(--grad-${name || 'spring'})`,
        '-webkit-background-clip': 'text',
        'background-clip': 'text',
        'color': 'transparent',
        '-webkit-text-fill-color': 'transparent',
      }),
    ],
    // bg-grad-spring|bloom|forest|brand|aurora（渐变背景，显式 background-image）
    [
      /^bg-grad-(spring|bloom|forest|brand|aurora)$/,
      ([, name]) => ({
        'background-image': `var(--grad-${name})`,
      }),
    ],
    // bg-hero · bg-app-* 等复合 background 简写（含底色 fallback，必须 background: shorthand）
    ['bg-hero', { background: 'var(--bg-hero)' }],

    /**
     * 自定义 animation utility——keyframes 仍写在 global.css，这里只产出 utility。
     * 走 rule 而非 theme.animation 是为了：
     *   1) theme.animation 在不提供 keyframes 字段时 UnoCSS 不生成 utility（实测）
     *   2) rule 更直观，所见即所得
     */
    ['animate-pulse-ring', { animation: 'pulse-ring 2s ease-in-out infinite' }],
  ],

  /**
   * Shortcuts：纯 atomic 组合（不涉及自定义 CSS 属性）
   */
  shortcuts: {
    // 卡片基线（B 端常用）
    'card-base': 'bg-elevated border border-subtle rounded-lg shadow-sm',
    'card-hover': 'transition-[transform,box-shadow,border-color] duration-base ease-out hover:(-translate-y-1 shadow-lg)',

    // 居中工具
    'center-grid': 'grid place-content-center',
    'center-flex': 'flex items-center justify-center',
    'between-flex': 'flex items-center justify-between',

    // 字号 + 字重 一气呵成
    'heading-1': 'text-3xl font-bold tracking-tight',
    'heading-2': 'text-2xl font-bold tracking-tight',
    'kicker': 'font-mono text-xs font-semibold uppercase tracking-[1.5px] text-accent-emerald',

    // 张扬 hero 系列（保留 with-noise / aurora-layer / cursor-glow 给原生 class，
    // 因为它们依赖 ::after 伪元素 + JS 注入 --mx/--my，用纯 atomic 不优雅）
  },

  /** 安全名单：动态拼接的 class 必须放进来，否则会被 purge */
  safelist: [
    // 里程碑卡 accent
    ...['mint', 'emerald', 'teal', 'cyan', 'amber', 'lime', 'forest'].map(c => `accent-${c}`),
    // 状态
    'status-done',
    'status-doing',
    'status-todo',
    // 健康探针状态
    'data-state-up',
    'data-state-down',
    'data-state-pending',
  ],
})
