'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface NavItem {
  href: string;
  label: string;
  emoji: string;
  activeEmoji: string;
}

const navItems: NavItem[] = [
  { href: '/', label: 'Count', emoji: '👶', activeEmoji: '🥳' },
  { href: '/history', label: 'History', emoji: '📅', activeEmoji: '🗓️' },
  { href: '/settings', label: 'Settings', emoji: '⚙️', activeEmoji: '🔧' },
  { href: '/info', label: 'Help', emoji: '❓', activeEmoji: '💡' },
];

export function JoyfulBottomNav() {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (href === '/') {
      return pathname === '/';
    }
    return pathname.startsWith(href);
  };

  return (
    <nav
      className="
        fixed bottom-0 left-0 right-0
        bg-white/95 backdrop-blur-sm
        border-t-4 border-gradient
        safe-area-bottom
      "
      style={{
        borderImage: 'linear-gradient(90deg, #ff8c78, #ffc520, #2dd4bf, #ff8c78) 1',
      }}
      aria-label="Main navigation"
    >
      <div className="max-w-md mx-auto flex justify-around py-1">
        {navItems.map((item) => {
          const active = isActive(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`
                flex flex-col items-center py-2 px-4
                transition-all duration-300
                rounded-2xl my-1
                ${
                  active
                    ? 'bg-gradient-to-br from-[#fff5f3] to-[#ffe8e4] scale-105'
                    : 'hover:bg-[#f3f1ed] hover:scale-105'
                }
              `}
              aria-current={active ? 'page' : undefined}
            >
              <span className={`text-2xl transition-transform duration-300 ${active && 'animate-wiggle'}`}>
                {active ? item.activeEmoji : item.emoji}
              </span>
              <span
                className={`
                  text-xs mt-0.5 font-semibold
                  ${active ? 'text-[#f96d55]' : 'text-[#9a9184]'}
                `}
              >
                {item.label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
